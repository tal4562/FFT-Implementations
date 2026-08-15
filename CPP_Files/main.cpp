#include <iostream>
#include <vector>
#include <complex>
#include <fstream>
#include <random>
#include <chrono>
#include <iomanip>

using namespace std;
using comp = complex<double>;

// This allows to record the cpp fft input and output
vector<comp> fft_Stockham_v0(const vector<comp> &x) ;

// --- Binary Save Function ---
// Writes raw bytes directly from RAM to disk to preserve 1e-15 precision.
void save_binary(const string& filename, const vector<comp>& data) {
    ofstream outFile(filename, ios::binary);
    if (!outFile) {
        cerr << "Error opening file: " << filename << endl;
        return;
    }
    // std::complex<double> is guaranteed to be two doubles (16 bytes) side-by-side
    outFile.write(reinterpret_cast<const char*>(data.data()), data.size() * sizeof(comp));
    outFile.close();
}

int main() {
    const size_t N = 1 << 20; // 1,048,576 points
    vector<comp> input_signal(N);

    // 1. Generate Random Input (Fixed seed 42 for reproducibility)
    mt19937 gen(42);
    uniform_real_distribution<double> dist(-1.0, 1.0);

    for (size_t i = 0; i < N; ++i) {
        input_signal[i] = comp(dist(gen), dist(gen));
    }

    // 2. Save Input in Binary (No precision loss)
    save_binary("input_random.bin", input_signal);
    cout << "Input saved to input_random.bin (" << (N * sizeof(comp)) / 1024 / 1024 << " MB)" << endl;

    // 3. Run the FFT
    cout << "Calculating FFT..." << endl;
    vector<comp> result = fft_Stockham_v0(input_signal);

    // 4. Save Output in Binary
    save_binary("output_stockham.bin", result);
    cout << "Output saved to output_stockham.bin" << endl;

    cout << "\nSuccess! Binary files generated. Use np.fromfile(..., dtype=np.complex128) in Python." << endl;

    return 0;
}

