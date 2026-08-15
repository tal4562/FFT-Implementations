#include <iostream>
#include <fstream>
#include <vector>
#include <complex>
#include <cmath>
using comp = std::complex<double>;
using namespace std ;

vector<complex<double>> fft_Stockham_v0(const vector<complex<double>>& x) ;


// normal
// g++ -O0 verify_fft.cpp FFT_Stockham_v0.cpp -o verify_fft.exe

// to go agg
//  g++ -O3 -march=native -ffast-math -funroll-loops -flto verify_fft.cpp FFT_Stockham_v0.cpp -o verify_fft.exe
//.\verify_fft.exe

int main() {
    const size_t N = 1 << 20;

    // Read input file
    std::vector<std::complex<double> > data(N);
    std::ifstream fin_in("complex_data.bin", std::ios::binary);
    if (!fin_in) { std::cerr << "Cannot open input file\n"; return 1; }
    fin_in.read(reinterpret_cast<char*>(data.data()), N * sizeof(std::complex<double>));
    fin_in.close();

    // Read NumPy FFT output
    std::vector<std::complex<double>> fft_numpy(N);
    std::ifstream fin_out("fft_output.bin", std::ios::binary);
    if (!fin_out) { std::cerr << "Cannot open FFT file\n"; return 1; }
    fin_out.read(reinterpret_cast<char*>(fft_numpy.data()), N * sizeof(std::complex<double>));
    fin_out.close();

    // Compute FFT using cpp implementation
    vector<complex<double>> fft_local = fft_Stockham_v0(data) ;


    // Verify: compute max absolute error
    double max_error = 0.0;
    for (size_t i = 0; i < N; ++i) {
        double err = std::abs(fft_local[i] - fft_numpy[i]);
        if (err > max_error) max_error = err;
    }

    std::cout << "Maximum absolute error vs NumPy FFT: " << max_error << "\n";

    return 0;
}
