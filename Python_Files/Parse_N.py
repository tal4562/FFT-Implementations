import matplotlib.pyplot as plt
import numpy as np
import os

# --- Configuration (FIXED FOR N=16 COSINE) ---
# IMPORTANT: Update this path to match the file name and path from the N=16 TB
FILE_PATH = r"C:\verilog\N_FFT\fft_N_output.txt"  # <-- Changed file name
Q_FORMAT = 15  # Fixed-point format Q1.15 (15 fractional bits)
N_FFT = 1024  # <-- Changed FFT size to 16


# PULSE_START/PULSE_END are not needed for this cosine test
# ----------------------------------------------

# --- Parsing Function (Unchanged, already correct for decimal input) ---
def parse_fft_tb_output_fixed(tb_output_content, q_format=15):
    """
    Parse a Verilog TB FFT output of the format 'RRRR IIII'
    (Real Decimal Int, Imaginary Decimal Int) into floating-point arrays.
    """
    X_real_int = []
    X_imag_int = []
    scale_factor = 1 << q_format

    lines = tb_output_content.strip().splitlines()

    for i, line in enumerate(lines):
        line = line.strip()
        parts = line.split()

        if len(parts) != 2:
            if line and not line.startswith('C:'):
                print(f"Warning: Skipping line {i + 1} due to unexpected format: '{line}'.")
            continue

        try:
            # 1. Convert string (decimal) to integer
            real_val = int(parts[0])
            imag_val = int(parts[1])

            # 2. Convert to floating point (Q-format scaling)
            X_real_int.append(real_val / scale_factor)
            X_imag_int.append(imag_val / scale_factor)

        except ValueError as e:
            print(f"Error on line {i + 1}: Could not convert decimal '{line}' - {e}")
            continue

    return X_real_int, X_imag_int


# Plotting Function
def plot_fft(X_real, X_imag, input_arr=None, q_format=15):
    """Plot FFT amplitude and phase."""
    X = np.array(X_real) + 1j * np.array(X_imag)
    N = len(X)

    if N == 0:
        print("Error: No valid FFT data was parsed to plot.")
        return

    # Verilog FFT Processing and Normalization
    max_abs_X = np.max(np.abs(X))
    X_normalized = X / max_abs_X if max_abs_X != 0 else X
    amp = np.abs(X_normalized)
    phase = np.angle(X_normalized)

    # NumPy Reference Calculation and Normalization
    if input_arr is not None:
        numpy_fft = np.fft.fft(input_arr)
        max_amplitude = np.max(np.abs(numpy_fft))
        numpy_fft_normalized = numpy_fft / max_amplitude if max_amplitude != 0 else numpy_fft

    # Plotting Setup
    fig, axes = plt.subplots(1, 2, figsize=(14, 5))
    k_indices = np.arange(N)

    # Amplitude
    ax1 = axes[0]
    ax1.stem(k_indices, np.fft.fftshift(amp), linefmt='C0-', markerfmt='C0.', basefmt=" ", label='Verilog TB Output')
    ax1.set_title("FFT Amplitude (Normalized, Shifted)")
    ax1.set_xlabel("Frequency Bin (k)")
    ax1.set_ylabel("|X[k]|")
    ax1.grid(axis='y', linestyle='--', alpha=0.7)

    if input_arr is not None:
        ax1.plot(k_indices, np.fft.fftshift(np.abs(numpy_fft_normalized)),
                 'r--', alpha=0.6, label='NumPy FFT (Ref.)')
    ax1.legend()

    # Phase
    ax2 = axes[1]
    ax2.stem(k_indices, np.fft.fftshift(phase) % (2 * np.pi), linefmt='C0-', markerfmt='C0.', basefmt=" ",
             label='Verilog TB Output')
    ax2.set_title("FFT Phase (radians, Shifted)")
    ax2.set_xlabel("Frequency Bin (k)")
    ax2.set_ylabel("∠X[k]")
    ax2.grid(axis='y', linestyle='--', alpha=0.7)

    if input_arr is not None:
        ax2.plot(k_indices, np.fft.fftshift(np.angle(numpy_fft_normalized)) % (2 * np.pi),
                 'r--', alpha=0.6, label='NumPy FFT (Ref.)')
    ax2.legend()

    fig.suptitle(f"FFT Analysis (N={N}) - Fixed-Point Q1.{q_format}", fontsize=14)
    plt.tight_layout(rect=[0, 0.03, 1, 0.95])
    plt.show()


# --- Main Execution Block ---

# 1. Read the file contents
try:
    with open(FILE_PATH, 'r') as f:
        file_content = f.read()
    print(f"Successfully read file: {FILE_PATH}")

except FileNotFoundError:
    print(f"FATAL ERROR: The file was not found at the specified path: {FILE_PATH}")
    file_content = ""
except Exception as e:
    print(f"An error occurred while reading the file: {e}")
    file_content = ""

# 2. Parse the output content
X_real, X_imag = parse_fft_tb_output_fixed(file_content, q_format=Q_FORMAT)

print(f"Successfully parsed {len(X_real)} complex samples for an N={len(X_real)} FFT.")

# 3. Generate the NumPy Reference Input (0.5 * cos(2*pi*n/16))
# This matches the Verilog TB: Amplitude 0.5, k=1, N=16
# l = np.cos(2 * np.pi * np.arange(N_FFT) / N_FFT) * 0.5
'''
l = np.zeros(N_FFT)
for i in range(N_FFT):
    if 20 < i and i < 128 - 20 + 1:
        l[i] = 0.5
'''
center = N_FFT / 2.0
x = (np.arange(N_FFT) - center) * 0.5
l = np.sinc(x) * 0.5

# 4. Plot the results
if len(X_real) == N_FFT:
    plot_fft(
        X_real=X_real,
        X_imag=X_imag,
        input_arr=l,
        q_format=Q_FORMAT
    )
else:
    print(
        f"Warning: Parsed FFT length ({len(X_real)}) does not match expected length N={N_FFT}. Plotting without NumPy reference.")
    plot_fft(X_real, X_imag, q_format=Q_FORMAT)