#include <vector>
#include <complex>
#include <algorithm>

#include "Memory_utils.h"
#include "Taylor_LUT_Coefficients.h"

#include <immintrin.h>


using namespace std ;
using comp = complex<double>;
using namespace Taylor;



vector<comp> fft_Stockham_v0(const vector<comp> &x) {
    /* =====================================
    Step 1: Array Sizes and Initialization
     ===================================== */
    const size_t N = x.size();
    const size_t half_N = N >> 1;
    const size_t quarter_N = N >> 2;
    const size_t eight_N = N >> 3;
    const size_t PAD = 1024 / sizeof(comp);
    const size_t section = (N + PAD + 3) & ~3; // Align to 64 bytes

    comp *const __restrict buffer = static_cast<comp *>(malloc_64(2.5 * section * sizeof(comp)));
    comp *const __restrict src_base = buffer;
    comp *const __restrict dst_base = buffer + section;
    comp *const __restrict lut_base = buffer + 2 * section;


    /* =====================================
       Step 2: Linear LUT Initialization (Taylor)
       ===================================== */
    {
        comp *const __restrict lin_lut = dst_base;
        const double base_ang = Two_PI / static_cast<double>(N);
        lin_lut[0] = comp(1.0, 0.0);
        for (size_t i = 1; i < eight_N; ++i) {
            const double ang = base_ang * i;
            const double x2 = ang * ang;

            const double c = 1.0 + x2 * (C2 + x2 * (C4 + x2 * (C6 + x2 * (C8 + x2 * (C10 + x2 * (C12 + x2 * C14))))));
            const double s = ang * (1.0 + x2 * (
                                        S3 + x2 * (S5 + x2 * (S7 + x2 * (S9 + x2 * (S11 + x2 * (S13 + x2 * S15)))))));

            lin_lut[i] = comp(c, -s);
        }

        lin_lut[eight_N] = comp(root2_2, neg_root2_2);
        lin_lut[quarter_N] = comp(0.0, -1.0);

        for (size_t i = 1; i < eight_N; ++i) {
            const comp v = lin_lut[eight_N - i];
            lin_lut[eight_N + i] = comp(-v.imag(), -v.real());
        }

        for (size_t i = 1; i < quarter_N; ++i) {
            const comp v = lin_lut[i];
            lin_lut[quarter_N + i] = comp(v.imag(), -v.real());
        }

        lin_lut[quarter_N + eight_N] = comp(neg_root2_2, neg_root2_2);
    }


    /* =====================================
   Step 3: Direct read for the input
   ===================================== */
    {
        const comp *const __restrict p_in1 = x.data();
        const comp *const __restrict p_in2 = p_in1 + half_N;

        comp *const __restrict p_out1 = src_base;
        comp *const __restrict p_out2 = src_base + half_N;

        const comp *const __restrict lin_lut = dst_base;

#pragma omp simd aligned(p_out1, p_out2, lin_lut : 64)
        for (size_t k = 0; k < half_N; ++k) {
            const comp a = p_in1[k];
            const comp b = p_in2[k];
            const comp w = lin_lut[k];

            const comp s = a + b;
            const comp d = (a - b) * w;

            p_out1[k] = s;
            p_out2[k] = d;
        }
    }

    /* =====================================
    Step 4: Building Stockham LUT
    ===================================== */
    {
        size_t log2N = 0;
        for (size_t t = N; t > 1; t >>= 1) ++log2N;
        // 1. Point to the base, but allow the pointer to be reassigned later
        comp *__restrict current_dst = lut_base;

        // 2. Point to source data, and promise NOT to change that data
        const comp *__restrict current_src = dst_base;

        size_t src_count = half_N;
        for (size_t s = 1; s < log2N; ++s) {
            size_t dst_count = src_count >> 1;

            // LOCAL ALIASES: These are locked for this specific 's' iteration
            // We add 'const' to the pointer itself here for maximum optimization
            const comp *const __restrict s_ptr = current_src;
            comp *const __restrict d_ptr = current_dst;

#pragma omp simd aligned(s_ptr, d_ptr : 64)
            for (size_t k = 0; k < dst_count; ++k) {
                d_ptr[k] = s_ptr[k << 1];
            }



            // Update the base pointers for the next stage of 's'
            current_src = current_dst;
            current_dst += dst_count;
            src_count = dst_count;
        }
    }


    /* =====================================
    Step 5: Main DIF stages
    ===================================== */
  {
    double* __restrict src_raw = reinterpret_cast<double*>(src_base);
    double* __restrict dst_raw = reinterpret_cast<double*>(dst_base);
    const double* __restrict w_raw = reinterpret_cast<const double*>(lut_base);

    size_t L = half_N;
    size_t num_groups = 2;
    size_t w_offset = 0;
    const size_t L2_TILE_D = 65536 ;

    while (L > 4) {
        const size_t half_L = L >> 1;
        const size_t L_d = L * 2;
        const size_t half_L_d = half_L * 2;
        const size_t half_N_d = half_N * 2;

        for (size_t k_outer = 0; k_outer < half_L_d; k_outer += L2_TILE_D) {
            size_t k_end = std::min(k_outer + L2_TILE_D, half_L_d);

            for (size_t j = 0; j < num_groups; ++j) {


                const double* __restrict p1_in = src_raw + (j * L_d) + k_outer;
                const double* __restrict p2_in = p1_in + half_L_d;
                const double* __restrict tw    = w_raw + w_offset + k_outer;

                double* __restrict p1_out = dst_raw + (j * half_L_d) + k_outer;
                double* __restrict p2_out = p1_out + half_N_d;

                // We process 4 doubles (2 complex) at a time to match AVX registers
                for (size_t k = 0; k < (k_end - k_outer); k += 4) {
                    // 1. Vector Loads
                    __m256d a = _mm256_loadu_pd(&p1_in[k]);
                    __m256d b = _mm256_loadu_pd(&p2_in[k]);
                    __m256d w = _mm256_loadu_pd(&tw[k]);

                    // 2. Butterfly Addition -> Stream out (Non-Temporal)
                    __m256d s = _mm256_add_pd(a, b);
                    _mm256_stream_pd(&p1_out[k], s);

                    // 3. Butterfly Subtraction
                    __m256d diff = _mm256_sub_pd(a, b);

                    // 4. FMA3 Vectorized Complex Multiply
                    __m256d w_real       = _mm256_movedup_pd(w);
                    __m256d w_imag       = _mm256_unpackhi_pd(w, w);
                    __m256d diff_swapped = _mm256_permute_pd(diff, 0x5);

                    __m256d diff_mult    = _mm256_fmaddsub_pd(diff, w_real, _mm256_mul_pd(diff_swapped, w_imag));

                    // 5. Stream out Second Butterfly Half
                    _mm256_stream_pd(&p2_out[k], diff_mult);
                }
            }
        }
        w_offset += half_L_d;
        std::swap(src_raw, dst_raw);
        L = half_L;
        num_groups <<= 1;
    }
}







    {
        // --- Anchor the Base Pointers ---
        // We use 'const' on the right of the asterisk to tell the compiler
        // these base addresses are "frozen" for the duration of the loop.
     const comp* __restrict p_in = dst_base;
        comp* __restrict os_l = src_base;
        comp* __restrict os_h = src_base + half_N;
        comp* __restrict od_l = src_base + quarter_N;
        comp* __restrict od_h = src_base + quarter_N + half_N;

        for (size_t j = 0; j < quarter_N; ++j) {
            // 1. Calculate the block offset once per loop.
            // The compiler will likely implement this using a bit-shift (j << 2).
            const comp *const __restrict block = p_in + (j << 2);

            // 2. Load the 4-point sub-sequence.
            // These translate to simple 'Base + Offset' loads in assembly.
            const comp a = block[0];
            const comp b = block[1];
            const comp c = block[2];
            const comp d = block[3];

            // 3. Perform Butterfly Math.
            const comp s0 = a + c;
            const comp d0 = a - c;
            const comp s1 = b + d;
            const comp d1 = b - d;

            // 4. Imaginary Rotation (d1 * -i)
            const comp d1_rot = {d1.imag(), -d1.real()};

            // 5. Indexed Stores.
            os_l[j] = s0 + s1;
            os_h[j] = s0 - s1;
            od_l[j] = d0 + d1_rot;
            od_h[j] = d0 - d1_rot;
        }
    }


    vector result(src_base, src_base + N);
    free_64(buffer);
    return result;
}
