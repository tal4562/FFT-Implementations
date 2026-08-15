import numpy as np

# Parameters
n = 20
seed = 42
input_filename = "complex_data.bin"
output_filename = "fft_output.bin"

# Set seed for reproducibility
np.random.seed(seed)

# Generate complex array
a = np.random.uniform(-1, 1, size=2**n) + 1j * np.random.uniform(-1, 1, size=2**n)

# Save input to binary file (interleaved real/imag)
data_to_save = np.empty(a.size * 2, dtype=np.float64)
data_to_save[0::2] = a.real
data_to_save[1::2] = a.imag
data_to_save.tofile(input_filename)
print(f"Saved {a.size} complex numbers to {input_filename}")

# Compute FFT
fft_a = np.fft.fft(a)

# Save FFT output to binary file (interleaved real/imag)
fft_data_to_save = np.empty(fft_a.size * 2, dtype=np.float64)
fft_data_to_save[0::2] = fft_a.real
fft_data_to_save[1::2] = fft_a.imag
fft_data_to_save.tofile(output_filename)
print(f"Saved FFT of {fft_a.size} complex numbers to {output_filename}")
