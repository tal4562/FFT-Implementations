#include <iostream>
#include <vector>
#include <complex>
#include <fstream>
#include <random>
#include <chrono>
#include <iomanip>

using namespace std;
using comp = complex<double>;

// normal
// g++ -O0 time_fft.cpp FFT_Stockham_v0.cpp -o time_fft.exe
// .\time_fft.exe

// to go agg
//g++ -O3 -march=native -ffast-math -funroll-loops -flto test_1_core.cpp FFT_Stockham_v2.cpp -o test_1_core.exe
//vector<comp> fft_Stockham_v0(const vector<comp> &x) ;
vector<complex<double>> fft_Stockham_v0(const vector<complex<double>>& x) ;

int main() {
    size_t N = 1<< 25;
    vector<comp> input_signal(N);

    mt19937 gen(42);
    uniform_real_distribution<double> dist(-1.0, 1.0);
    for (size_t i = 0; i < N; ++i) {
        input_signal[i] = comp(dist(gen), dist(gen));
    }

    // --- Start Timing ---
    int iterations = 10;
    cout << "Starting " << iterations << " iterations for timing..." << endl;

    auto start = chrono::high_resolution_clock::now();

    for (int i = 0; i < iterations; ++i) {
        // We use volatile-like trick or just ensure the result isn't optimized away
        //vector<comp> result = fft_Stockham_v0(input_signal);
        vector<complex<double>> result = fft_Stockham_v0(input_signal) ;
    }

    auto end = chrono::high_resolution_clock::now();
    // --- End Timing ---

    chrono::duration<double> diff = end - start;
    double avg_time = diff.count() / iterations;

    cout << "------------------------------------" << endl;
    cout << "Total time for " << iterations << " runs: " << diff.count() << " s" << endl;
    cout << "Average time per FFT: " << fixed << setprecision(4) << avg_time << " s" << endl;
    cout << "------------------------------------" << endl;

    // Run one final time to save for verification
    vector<comp> final_result = fft_Stockham_v0(input_signal);

    return 0;
}