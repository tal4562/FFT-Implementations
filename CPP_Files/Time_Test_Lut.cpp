#include <iostream> // for cout
#include <iomanip> // for controlling percision
#include <complex> // for comp
#include <chrono> // for timing
#include <cstring> // for memcopy

#include "Taylor_LUT_Coefficients.h"
#include "Memory_utils.h"


// shortcuts
using namespace std;
using namespace chrono;
using comp = complex<double>;
using namespace Taylor ;


// compile normally
// g++ Time_Test_Lut.cpp -o Time_Test_Lut.exe

// comp agg
//  g++ -O3 -march=native -ffast-math -funroll-loops -flto Time_Test_lut.cpp -o Time_Test_lut.exe
//  .\Time_Test_lut.exe k

// one liner
// g++ -O3 -march=native -ffast-math -funroll-loops -flto Time_Test_Lut.cpp -o Time_Test_Lut.exe ; .\Time_Test_Lut.exe 25


/* ================================================
 * LUT Rotation Function With Pointer Walking      *
 * ================================================*/
void apply_full_rotation_comp_pw(comp* lut, int N) {
    const int quarter_N = N >> 2 ;
    const int eight_N   = N >> 3 ;

    // set anchors
    lut[0] = comp(1.0, 0.0) ;
    lut[eight_N]   = comp(root2_2, neg_root2_2) ;
    lut[quarter_N] = comp(0.0, -1.0) ;
    lut[eight_N + quarter_N]   = comp(neg_root2_2, neg_root2_2) ;


    // Mirror Octant 1 -> Octant 2 [-45 .. -90]
    const comp* __restrict lut_src_octant = &lut[eight_N - 1] ;
    comp* __restrict lut_dst_octant = &lut[eight_N + 1] ;
    size_t steps_o1 = eight_N - 1;
    #pragma omp simd
    for (size_t k = 0; k < steps_o1; ++k) {
        *lut_dst_octant = -comp(lut_src_octant->imag(), lut_src_octant->real());
        lut_dst_octant++ ;
        lut_src_octant-- ;
    }

    // Rotate Quadrant 1 -> Quadrant 2 [-90 .. -180]
    const comp* __restrict lut_src_quadrant = &lut[quarter_N - 1] ;
    comp* __restrict lut_dst_quadrant = &lut[quarter_N + 1] ;
    size_t steps_q1 = quarter_N - 1 ;

#pragma omp simd
    for (size_t k = 0; k < steps_q1; ++k) {
        *lut_dst_quadrant = comp(-lut_src_quadrant->real(), lut_src_quadrant->imag());
        lut_dst_quadrant++ ;
        lut_src_quadrant-- ;
    }
}

/* ================================================
 * LUT Rotation Function With index                *
 * ================================================*/
void apply_full_rotation_index_comp(comp* lut, int N) {
    const int quarter_N = N >> 2 ;
    const int eight_N   = N >> 3 ;

    // set anchors
    lut[0] = comp(1.0, 0.0) ;
    lut[eight_N]   = comp(root2_2, neg_root2_2) ;
    lut[quarter_N] = comp(0.0, -1.0) ;
    lut[eight_N + quarter_N]   = comp(neg_root2_2, neg_root2_2) ;

    // Mirror Octant 1 -> Octant 2 [-45 .. -90]
#pragma omp simd
    for (int i = 1; i < eight_N; ++i) {
        comp v = lut[eight_N - i];
        lut[eight_N + i] = comp(-v.imag(), -v.real());
    }


    // Rotate Quadrant 1 -> Quadrant 2 [-90 .. -180]
#pragma omp simd
    for (int i = 1; i < quarter_N; ++i) {
        comp v = lut[i];
        lut[quarter_N + i] = comp(v.imag(), -v.real());
    }
}


/* ================================================
 * Compare and Time LUTS comp                      *
 * ================================================*/
void test_print_result_comp(const string& label,
    time_point<high_resolution_clock> startTime, time_point<high_resolution_clock> endTime, const comp* a, const comp* b,size_t limit ) {

    double max_real = 0.0 ;
    double max_imag = 0.0 ;
    double max_abs  = 0.0 ;

    for (int i = 0; i <= limit ; ++i) {
        double dr = abs(a[i].real() - b[i].real()) ;
        double di = abs(a[i].imag() - b[i].imag()) ;
        double da = abs(a[i] - b[i]) ;

        if (dr > max_real) max_real = dr ;
        if (di > max_imag) max_imag = di ;
        if (da > max_abs)  max_abs  = da ;
    }

    double duration_sec = duration<double>(endTime - startTime).count() ;

    cout << left << setw(25) << label
         << "| " << fixed << setprecision(8) << setw(12) << duration_sec
         << "| " << setw(12) << scientific << setprecision(3) << max_real
         << "| " << setw(12) << scientific << setprecision(3) << max_imag
         << "| " << setw(12) << scientific << setprecision(3) << max_abs
         << endl ;
}


int main(int argc, char* argv[]) {
    size_t powTwo = 25 ;
    if (argc > 1) {
        // Convert the text from the terminal into a number
        powTwo = std::stoul(argv[1]);
    }

    const int N = 1 << powTwo ;
    const int half_N = N / 2 ;
    const int quarter_N = N / 4;
    const int eight_N = N / 8 ;
    const double base_ang = Two_PI / N ;
    const size_t alloc_size_comp = half_N * sizeof(comp) ;
    const size_t alloc_size_double = half_N * sizeof(double) ;

    // 1. Standard Built-in
    comp* __restrict const lut_built_sin_cos = (comp*)malloc_64(alloc_size_comp) ;
    {
        auto start_built_in = high_resolution_clock::now();
        for (int i = 0; i < half_N; ++i) {
            double ang = i * base_ang;
            lut_built_sin_cos[i] = comp(cos(ang), -sin(ang));
        }
        auto end_built_in = high_resolution_clock::now();
        // Print Results
        cout <<"Timing for LUTs. input size of 2 ^"<< powTwo<<". LUT size is 2^"<< powTwo-1<< endl;
        cout << left << setw(25) << "Method"
             << "| " << setw(12) << "Time (s)"
             << "| " << setw(12) << "Max Real"
             << "| " << setw(12) << "Max Imag"
             << "| " << "Max Abs" << endl ;
        cout << string(80, '-') << endl ;

        cout << left << setw(25) << "1. Built-in cos sin"
             << "| " << fixed << setprecision(5) << setw(12)
             << duration<double>(end_built_in - start_built_in).count()
             << "| " << setw(12) << "-"
             << "| " << setw(12) << "-"
             << "| " << "-" << endl ;
    }

    // 2. Built-in rotated index
    {
        comp* __restrict const build_in_rotated_index = (comp*)malloc_64(alloc_size_comp) ;
        auto start_build_in_rot_ind = high_resolution_clock::now() ;
        for (int i = 1; i <= eight_N; ++i) {
            double ang = i * base_ang;
            double s, c;
            sincos(ang, &s, &c);
            build_in_rotated_index[i] = comp(c, -s);
        }
        apply_full_rotation_index_comp(build_in_rotated_index, N) ;
        auto end_build_in_rot_ind = high_resolution_clock::now() ;
        test_print_result_comp("2. Build in rot index", start_build_in_rot_ind, end_build_in_rot_ind, build_in_rotated_index , lut_built_sin_cos, half_N) ;
        free_64(build_in_rotated_index) ;
    }

    // 3. Built-in rotated pointer walking
    {
        comp* __restrict const build_in_rotated_pw = (comp*)malloc_64(alloc_size_comp) ;
        auto start_build_in_rot_ind = high_resolution_clock::now() ;
        for (int i = 1; i <= eight_N; ++i) {
            double ang = i * base_ang;
            double s, c;
            sincos(ang, &s, &c);
            build_in_rotated_pw[i] = comp(c, -s);
        }
        apply_full_rotation_index_comp(build_in_rotated_pw, N) ;
        auto end_build_in_rot_ind = high_resolution_clock::now() ;
        test_print_result_comp("3. Build in rot pw", start_build_in_rot_ind, end_build_in_rot_ind, build_in_rotated_pw , lut_built_sin_cos, half_N) ;
        free_64(build_in_rotated_pw) ;
    }

    // 4. Taylor 14 rotated index
    {
        comp* __restrict const taylor_rot_ind = (comp*)malloc_64(alloc_size_comp) ;
        auto start_taylor_rot_ind = high_resolution_clock::now() ;
        for (int i = 1; i < eight_N; ++i) {
            double ang = base_ang * i ;
            double x2 = ang * ang ;
            double c = 1.0 + x2*(C2 + x2*(C4 + x2*(C6 + x2*(C8 + x2*(C10 + x2*(C12 + x2*C14)))))) ;
            double s = ang * (1.0 + x2*(S3 + x2*(S5 + x2*(S7 + x2*(S9 + x2*(S11 + x2*(S13 + x2*S15))))))) ;
            taylor_rot_ind[i] = comp(c, -s) ;
        }
        apply_full_rotation_index_comp(taylor_rot_ind, N) ;
        auto end_taylor_rot_ind = high_resolution_clock::now() ;
        test_print_result_comp("4. Taylor rot ind", start_taylor_rot_ind, end_taylor_rot_ind, taylor_rot_ind , lut_built_sin_cos, half_N) ;
        free_64(taylor_rot_ind) ;
    }

    // 5. Taylor 14 rotated pointer walking
    {
        comp* __restrict const taylor_rot_pw = (comp*)malloc_64(alloc_size_comp) ;
        auto start_taylor_rot_ind = high_resolution_clock::now() ;
        for (int i = 1; i < eight_N; ++i) {
            double ang = base_ang * i ;
            double x2 = ang * ang ;
            double c = 1.0 + x2*(C2 + x2*(C4 + x2*(C6 + x2*(C8 + x2*(C10 + x2*(C12 + x2*C14)))))) ;
            double s = ang * (1.0 + x2*(S3 + x2*(S5 + x2*(S7 + x2*(S9 + x2*(S11 + x2*(S13 + x2*S15))))))) ;
            taylor_rot_pw[i] = comp(c, -s) ;
        }
        apply_full_rotation_index_comp(taylor_rot_pw, N) ;
        auto end_taylor_rot_ind = high_resolution_clock::now() ;
        test_print_result_comp("5. Taylor rot pw", start_taylor_rot_ind, end_taylor_rot_ind, taylor_rot_pw , lut_built_sin_cos, half_N) ;
        free_64(taylor_rot_pw) ;
    }

    //6. SOA all at once index
    {
        double* __restrict const SOA_A_ind_r = static_cast<double*>(malloc_64(alloc_size_double)) ;
        double* __restrict const SOA_A_ind_i = static_cast<double*>(malloc_64(alloc_size_double)) ;

        auto start_SOA_once_ind =  high_resolution_clock::now();
        SOA_A_ind_r[0] = 1 ;
        SOA_A_ind_i[0] = 0 ;

        SOA_A_ind_r[eight_N] = root2_2 ;
        SOA_A_ind_i[eight_N] = neg_root2_2 ;

        SOA_A_ind_r[quarter_N] = 0.0 ;
        SOA_A_ind_i[quarter_N] = -1.0 ;

        SOA_A_ind_r[quarter_N + eight_N] = neg_root2_2 ;
        SOA_A_ind_i[quarter_N + eight_N] = neg_root2_2 ;


        for (size_t p1 = 1, p2 = quarter_N - 1, p3 = quarter_N + 1, p4 = half_N - 1 ;
            p1 < eight_N ;
            ++p1, --p2, ++p3, --p4) {

            const double ang = base_ang * p1 ;
            const double x2  = ang * ang ;

            // 1. Calc 'c'
            const double c1 = 1.0 + x2*(C2 + x2*(C4 + x2*(C6 + x2*(C8 + x2*(C10 + x2*(C12 + x2*C14)))))) ;
            SOA_A_ind_r[p1] = c1 ;  // Assign immediately

            // 2. Flip to 'nc' and blast it
            const double nc = -c1 ;
            SOA_A_ind_r[p4] = nc ;
            SOA_A_ind_i[p2] = nc ;
            SOA_A_ind_i[p3] = nc ;


            // 3. Calc 's'
            const double sin1 = ang * (1.0 + x2*(S3 + x2*(S5 + x2*(S7 + x2*(S9 + x2*(S11 + x2*(S13 + x2*S15))))))) ;
            SOA_A_ind_r[p2] = sin1 ;

            // 4. Flip to 'ns' and blast it
            const double ns = -sin1 ;
            SOA_A_ind_i[p1] = ns ;
            SOA_A_ind_r[p3] = ns ;
            SOA_A_ind_i[p4] = ns ;

            }
        auto end_SOA_once_ind =  high_resolution_clock::now();
        comp* __restrict const SOA_once_ind  = (comp*)malloc_64(alloc_size_comp) ;
        for (size_t k = 0 ; k < half_N ; k++) {
            SOA_once_ind[k] = {SOA_A_ind_r[k], SOA_A_ind_i[k] } ;
        }
        free_64(SOA_A_ind_r) ;
        free_64(SOA_A_ind_i) ;
        test_print_result_comp("6. SOA Once ind", start_SOA_once_ind, end_SOA_once_ind, SOA_once_ind , lut_built_sin_cos, half_N) ;
        free_64(SOA_once_ind) ;
    }

    //7. SOA all at once pointer walking
    {
        double* __restrict const SOA_A_pw_r = static_cast<double*>(malloc_64(alloc_size_double)) ;
        double* __restrict const SOA_A_pw_i = static_cast<double*>(malloc_64(alloc_size_double)) ;

        auto start_SOA_once_pw =  high_resolution_clock::now();

        // 1. Anchor initialization (as you provided)
        SOA_A_pw_r[0] = 1.0;
        SOA_A_pw_i[0] = 0.0;

        SOA_A_pw_r[eight_N] = root2_2;
        SOA_A_pw_i[eight_N] = neg_root2_2;

        SOA_A_pw_r[quarter_N] = 0.0;
        SOA_A_pw_i[quarter_N] = -1.0;

        SOA_A_pw_r[quarter_N + eight_N] = neg_root2_2;
        SOA_A_pw_i[quarter_N + eight_N] = neg_root2_2;

        // 2. Pointer Setup (Offset by 1 to not overwrite anchors)
        double* __restrict pr1 = &SOA_A_pw_r[1];
        double* __restrict pi1 = &SOA_A_pw_i[1];

        double* __restrict pr2 = &SOA_A_pw_r[quarter_N - 1];
        double* __restrict pi2 = &SOA_A_pw_i[quarter_N - 1];

        double* __restrict pr3 = &SOA_A_pw_r[quarter_N + 1];
        double* __restrict pi3 = &SOA_A_pw_i[quarter_N + 1];

        double* __restrict pr4 = &SOA_A_pw_r[half_N - 1]; // Assuming half_N is the end of your range
        double* __restrict pi4 = &SOA_A_pw_i[half_N - 1];

        // 3. The Loop
        for (size_t k = 1; k < eight_N; ++k) {
            const double ang = base_ang * k;
            const double x2  = ang * ang;

            // Taylor series for cos/sin
            const double c1   = 1.0 + x2*(C2 + x2*(C4 + x2*(C6 + x2*(C8 + x2*(C10 + x2*(C12 + x2*C14))))));
            const double sin1 = ang * (1.0 + x2*(S3 + x2*(S5 + x2*(S7 + x2*(S9 + x2*(S11 + x2*(S13 + x2*S15)))))));

            const double nc = -c1;
            const double ns = -sin1;

            // --- Blast Assignments (Imaginary is always negative in this range) ---

            // Real parts: C, S, -S, -C
            *pr1 = c1;   // Oct 1: cos(a)
            *pr2 = sin1; // Oct 2: cos(90-a) = sin(a)
            *pr3 = ns;   // Oct 3: cos(90+a) = -sin(a)
            *pr4 = nc;   // Oct 4: cos(180-a) = -cos(a)

            // Imaginary parts: -S, -C, -C, -S
            *pi1 = ns;   // Oct 1: sin(a) -> -sin(a)
            *pi2 = nc;   // Oct 2: sin(90-a) = cos(a) -> -cos(a)
            *pi3 = nc;   // Oct 3: sin(90+a) = cos(a) -> -cos(a)
            *pi4 = ns;   // Oct 4: sin(180-a) = sin(a) -> -sin(a)

            pr1++; pi1++;
            pr2--; pi2--;
            pr3++; pi3++;
            pr4--; pi4--;
        }
        auto end_SOA_once_pw =  high_resolution_clock::now();
        comp* __restrict const SOA_once_pw  = (comp*)malloc_64(alloc_size_comp) ;
        for (size_t k = 0 ; k < half_N ; k++) {
            SOA_once_pw[k] = {SOA_A_pw_r[k], SOA_A_pw_i[k] } ;
        }
        free_64(SOA_A_pw_r) ;
        free_64(SOA_A_pw_i) ;
        test_print_result_comp("7. SOA Once pw", start_SOA_once_pw, end_SOA_once_pw, SOA_once_pw , lut_built_sin_cos, half_N) ;
        free_64(SOA_once_pw) ;
    }

    //8. SOA memcopy
    {
        double* __restrict const SOA_mc_r = static_cast<double*>(malloc_64(alloc_size_double)) ;
        double* __restrict const SOA_mc_i = static_cast<double*>(malloc_64(alloc_size_double)) ;

        auto start_SOA_mc =  high_resolution_clock::now() ;

        SOA_mc_r[0] = 1.0 ;
        SOA_mc_i[0] = 0.0 ;

        SOA_mc_r[eight_N] = root2_2 ;
        SOA_mc_i[eight_N] = neg_root2_2 ;

        SOA_mc_i[quarter_N] = -1.0 ;
        SOA_mc_i[quarter_N + eight_N] = neg_root2_2 ;

#pragma omp simd
        for (size_t k = 1; k < eight_N; ++k) {
            const double ang = base_ang * k ;
            const double x2  = ang * ang ;

            SOA_mc_r[k] = 1.0 + x2*(C2 + x2*(C4 + x2*(C6 + x2*(C8 + x2*(C10 + x2*(C12 + x2*C14))))));
            SOA_mc_i[k] = -(ang * (1.0 + x2*(S3 + x2*(S5 + x2*(S7 + x2*(S9 + x2*(S11 + x2*(S13 + x2*S15))))))));
        }



        double* r_src_base = &SOA_mc_r[eight_N - 1];
        double* i_src_base = &SOA_mc_i[eight_N - 1];
        double* r_dst_base = &SOA_mc_r[eight_N + 1];
        double* i_dst_base = &SOA_mc_i[eight_N + 1];

        size_t steps_o1 = eight_N - 1;

        for (size_t k = 0; k < steps_o1; ++k) {
            r_dst_base[k] = -i_src_base[-k]; // Write forward, Read backward
            i_dst_base[k] = -r_src_base[-k]; // Write forward, Read backward
        }
        memcpy(&SOA_mc_r[quarter_N],&SOA_mc_i[0],(quarter_N )*sizeof(double)) ;

        double* iq_src_base = &SOA_mc_i[quarter_N - 1];
        double* iq_dst_base = &SOA_mc_i[quarter_N + 1];

        size_t steps_q1 = quarter_N - 1;

        for (size_t k = 0; k < steps_q1; ++k) {
            // iq_dst moves forward (+k), iq_src moves backward (-k)
            iq_dst_base[k] = iq_src_base[-k];
        }

        auto end_SOA_mc =  high_resolution_clock::now();
        comp* __restrict const SOA_mc  = (comp*)malloc_64(alloc_size_comp) ;
        for (size_t k = 0 ; k < half_N ; k++) {
            SOA_mc[k] = {SOA_mc_r[k], SOA_mc_i[k] } ;
        }
        free_64(SOA_mc_r) ;
        free_64(SOA_mc_i) ;
        test_print_result_comp("8. SOA memcopy", start_SOA_mc, end_SOA_mc, SOA_mc , lut_built_sin_cos, half_N) ;
        free_64(SOA_mc) ;
    }

    //  Taylor 14 rotated index (Optimized with Estrin's Scheme)
    // 4. Taylor 14 rotated index (Fixed Estrin's Scheme)
    {
        #pragma vector nontemporal
        comp* __restrict const taylor_rot_ind_es = (comp*)malloc_64(alloc_size_comp);
        auto start_taylor_rot_ind_es = high_resolution_clock::now();

        for (int i = 1; i < eight_N; ++i) {
            double ang = base_ang * i;
            double x2 = ang * ang;
            double x4 = x2 * x2;
            double x8 = x4 * x4;

            // --- Cosine Core ---
            // Original inside bracket: C2 + C4*x2 + C6*x4 + C8*x6 + C10*x8 + C12*x10 + C14*x12
            double c_pair1 = C2  + x2 * C4;
            double c_pair2 = C6  + x2 * C8;
            double c_pair3 = C10 + x2 * C12;

            // Combine them using the correct power offsets
            double c_poly  = c_pair1 + x4 * c_pair2 + x8 * (c_pair3 + x4 * C14);
            double c       = 1.0 + x2 * c_poly;

            // --- Sine Core ---
            // Original inside bracket: S3 + S5*x2 + S7*x4 + S9*x6 + S11*x8 + S13*x10 + S15*x12
            double s_pair1 = S3  + x2 * S5;
            double s_pair2 = S7  + x2 * S9;
            double s_pair3 = S11 + x2 * S13;

            // Combine them using the correct power offsets
            double s_poly  = s_pair1 + x4 * s_pair2 + x8 * (s_pair3 + x4 * S15);
            double s       = ang * (1.0 + x2 * s_poly);

            // Store result
            taylor_rot_ind_es[i] = comp(c, -s);
        }

        apply_full_rotation_index_comp(taylor_rot_ind_es, N);
        auto end_taylor_rot_ind = high_resolution_clock::now();
        test_print_result_comp("9.(Estrin Fixed)", start_taylor_rot_ind_es, end_taylor_rot_ind, taylor_rot_ind_es, lut_built_sin_cos, half_N);
        free_64(taylor_rot_ind_es);
    }

    free_64(lut_built_sin_cos) ;

    return 0 ;

}
