import matplotlib.pyplot as plt
import numpy as np

# --- Configuration ---
FILE_PATH = r"C:\verilog\16_FFT\fft_16_output.txt"  # Ensure this path is correct
Q_FORMAT = 15  # Assuming Q1.15 format


# --- Parsing Function ---
def parse_fft_tb_output_fixed(tb_output_content, q_format=15):
    """
    Parse a Verilog TB FFT output of the format 'RRRR IIII'
    (Real 16-bit hex, Imaginary 16-bit hex) into floating-point arrays.
    """
    X_real = []
    X_imag = []
    scale_factor = 1 << q_format

    # If tb_output_content is a file path, we handle the error, but the input
    # should be the file content string.
    lines = tb_output_content.strip().splitlines()
    parsed_count = 0

    for i, line in enumerate(lines):
        line = line.strip()
        parts = line.split()

        # Check for expected format (two hex words)
        if len(parts) != 2:
            if line:
                # Print a warning only for lines that contain data but are misformatted
                if len(line) > 1 and not line.startswith('C:'):
                    print(f"Warning: Skipping line {i + 1} due to unexpected format: '{line}'.")
            continue

        try:
            real_hex, imag_hex = parts[0], parts[1]

            # 1. Convert hex to integer
            real_val = int(real_hex, 16)
            imag_val = int(imag_hex, 16)

            # 2. Convert 16-bit signed (Two's Complement)
            if real_val & 0x8000:
                real_val -= 0x10000
            if imag_val & 0x8000:
                imag_val -= 0x10000

            # 3. Convert to floating point (Q-format scaling)
            X_real.append(real_val / scale_factor)
            X_imag.append(imag_val / scale_factor)
            parsed_count += 1

        except ValueError as e:
            print(f"Error on line {i + 1}: Could not convert hex '{line}' - {e}")
            continue

    return X_real, X_imag


# --- Plotting Function ---
def plot_fft(X_real, X_imag, input_arr=None, q_format=15):
    """Plot FFT amplitude and phase."""
    X = np.array(X_real) + 1j * np.array(X_imag)
    N = len(X)

    if N == 0:
        print("Error: No valid FFT data was parsed to plot.")
        return

    # Apply normalization factor to Verilog data (based on Verilog's max value)
    # This step is critical for proper scaling if you are comparing two plots
    if np.max(np.abs(X)) != 0:
        X_normalized = X / np.max(np.abs(X))
    else:
        X_normalized = X  # Avoid division by zero

    amp = np.abs(X_normalized)
    phase = np.angle(X_normalized)

    # --- NumPy Reference Calculation and Normalization ---
    if input_arr is not None:
        numpy_fft = np.fft.fft(input_arr)

        # 1. Calculate the normalization factor from the NumPy result
        max_amplitude = np.max(np.abs(numpy_fft))

        # 2. Apply normalization to the NumPy result (if max_amplitude is not zero)
        if max_amplitude != 0:
            numpy_fft_normalized = numpy_fft / max_amplitude
        else:
            numpy_fft_normalized = numpy_fft

    # --- Plotting Setup ---
    fig, axes = plt.subplots(1, 2, figsize=(14, 5))
    k_indices = np.arange(N)

    # --- Amplitude ---
    ax1 = axes[0]
    # Use the normalized amplitude for the Verilog plot
    ax1.stem(k_indices, np.fft.fftshift(amp), label='Verilog TB Output', basefmt=" ")
    ax1.set_title("FFT Amplitude (Normalized)")
    ax1.set_xlabel("Frequency Bin (k)")
    ax1.set_ylabel("|X[k]|")
    ax1.grid(axis='y', linestyle='--', alpha=0.7)

    if input_arr is not None:
        # Use the normalized NumPy amplitude for the reference plot
        ax1.plot(k_indices, np.fft.fftshift(np.abs(numpy_fft_normalized)),
                 'r--', alpha=0.6, label='NumPy FFT (Ref.)')

    ax1.legend()

    # --- Phase ---
    ax2 = axes[1]
    # Use the normalized phase for the Verilog plot
    ax2.stem(k_indices, np.fft.fftshift(phase), label='Verilog TB Output', basefmt=" ")
    ax2.set_title("FFT Phase (radians)")
    ax2.set_xlabel("Frequency Bin (k)")
    ax2.set_ylabel("∠X[k]")
    ax2.grid(axis='y', linestyle='--', alpha=0.7)

    if input_arr is not None:
        # Use the normalized NumPy phase for the reference plot
        ax2.plot(k_indices, np.fft.fftshift(np.angle(numpy_fft_normalized)),
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

# 3. Plot the results
plot_fft(X_real, X_imag, np.cos(2 * np.pi * np.arange(16) / 16), q_format=Q_FORMAT)