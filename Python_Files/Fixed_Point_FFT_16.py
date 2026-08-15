import numpy as np
import matplotlib.pyplot as plt

# ---------------------------
# Parameters
# ---------------------------
N = 16 # FFT size (power of 2)
Q_BITS = 15  # The number of fractional bits (for Q1.15)
Q_SCALE = 1 << Q_BITS
print(Q_SCALE)
# ---------------------------
# Input signal (assumed to be already in Q1.15 format)
# ---------------------------
# The problem asks to assume x_in = arrange(1, N) in Q1.15 format.
# Assuming x_in = [0, 1, 2, ..., N-1] for simplicity and starting index 0
# Since the problem statement already assumes x is in Q1.15, we use the raw integers.
x_in_real =  [0.5 * np.cos(2 * np.pi * i / 16) for i in range(16)]#[i  for i in range(N)]
for i in range(16):
    if abs(x_in_real[i]) < (10 ** -16):
        x_in_real[i] = 0
x_in_imag = [0] * N
# 2. Define the Scaling Factor (2^15)
Q_BITS = 15
SCALE_FACTOR = 2 ** Q_BITS  # 32768

# 3. Perform the conversion
x_in_q1_15 = []
for x in x_in_real:
    # A. Scale the value
    scaled_value = x * SCALE_FACTOR

    # B. Round to the nearest integer
    # Using np.round is recommended for consistency
    rounded_value = np.round(scaled_value)

    # C. Cast to a standard integer (e.g., 16-bit signed integer for final use)
    # The intermediate result is typically a standard Python integer or np.int64
    q1_15_int = int(rounded_value)

    x_in_q1_15.append(q1_15_int)

x_in_real = x_in_q1_15

print("Input Real (Q1.15):", x_in_real)
print("Input Imag (Q1.15):", x_in_imag)

# Initialize Real and Imaginary arrays for the FFT process
x_real = list(x_in_real)
x_imag = list(x_in_imag)

# ---------------------------
# Precompute twiddle factors (Q1.15)
# ---------------------------
twiddle_real = {}
twiddle_imag = {}
size = 2
while size <= N:
    half = size // 2
    wr_list = []
    wi_list = []
    for k in range(half):
        angle = -2 * np.pi * k / size
        # Scale twiddle factors by Q_SCALE (2^15)
        wr_list.append(int(round(np.cos(angle) * Q_SCALE)))
        wi_list.append(int(round(np.sin(angle) * Q_SCALE)))
    twiddle_real[size] = wr_list
    twiddle_imag[size] = wi_list
    size *= 2
print(twiddle_real)
print(twiddle_imag)
# ---------------------------
# Bit-reversal permutation
# ---------------------------
levels = int(np.log2(N))
rev = [0] * N
for i in range(N):
    r = 0
    for j in range(levels):
        r = (r << 1) | ((i >> j) & 1)
    rev[i] = r

# Apply bit-reversal to both real and imaginary parts
x_real = [x_real[rev[i]] for i in range(N)]
x_imag = [x_imag[rev[i]] for i in range(N)]

print("\n--- After Bit-Reversal ---")
print("Real:", x_real)
print("Imag:", x_imag)

# ---------------------------
# Iterative FFT with scaling
# ---------------------------
stage = 1
size = 2
while size <= N:
    half = size // 2
    wr = twiddle_real[size]
    wi = twiddle_imag[size]

    for start in range(0, N, size):
        for k in range(half):
            # Complex Butterfly Operation (u + t * W)

            # u = x[start + k]
            u_r = x_real[start + k]
            u_i = x_imag[start + k]

            # t = x[start + k + half]
            t_r = x_real[start + k + half]
            t_i = x_imag[start + k + half]

            # W = twiddle[k]
            w_r = wr[k]
            w_i = wi[k]

            # 1. Complex Multiplication: t_new = t * W
            # (t_r + j*t_i) * (w_r + j*w_i) = (t_r*w_r - t_i*w_i) + j*(t_r*w_i + t_i*w_r)

            # Result of fixed-point multiplication requires scaling by Q_SCALE (right shift by Q_BITS)
            t_new_r = ((t_r * w_r - t_i * w_i)) >> (Q_BITS )
            t_new_i = ((t_r * w_i + t_i * w_r)) >> (Q_BITS )
            SCALE_FACTOR = 32768  # Q1.15 scaling

            # Assuming w_r and w_i are signed integers from Q1.15
            w_real = w_r / SCALE_FACTOR
            w_imag = w_i / SCALE_FACTOR

            print(f"{k} : twiddle = {w_real} + j{w_imag}")

            # 2. Butterfly Computation with Scale-by-1/2 (>>1)
            # X[k] = (u + t_new) / 2
            x_real[start + k] = (u_r + t_new_r) >> 1
            x_imag[start + k] = (u_i + t_new_i) >> 1

            # X[k+half] = (u - t_new) / 2
            x_real[start + k + half] = (u_r - t_new_r) >> 1
            x_imag[start + k + half] = (u_i - t_new_i) >> 1

    print(f"\n--- After Stage {stage} (Size {size}) ---")
    print("indx:", [i for i in range(N)])
    print("Real:", x_real)
    print("Imag:", x_imag )

    stage += 1
    size *= 2

print("\n==================================")
print("Final Output (Q1.15):")
print("Real:", x_real)
print("Imag:", x_imag)
print("==================================")
num_stages = int(np.log2(N))
scale = 1 << num_stages   # 2^stages
x_real = [v  for v in x_real]
x_imag = [v  for v in x_imag]
# your magnitude
mag = np.sqrt(np.array(x_real)**2 + np.array(x_imag)**2)
mag_norm = mag / np.max(mag)                # normalize so max = 1
mag_norm_shifted = np.fft.fftshift(mag_norm)
plt.stem(np.arange(N) - N/2, mag_norm_shifted)

X = np.fft.fft(np.cos(np.arange(16) * 2 * np.pi / 16))                # FFT
X_mag = np.abs(X)                           # magnitude
X_mag_norm = X_mag / np.max(X_mag)          # normalize so max = 1
X_mag_norm_shifted = np.fft.fftshift(X_mag_norm)

plt.plot(np.arange(N) - N/2, X_mag_norm_shifted)
plt.show()
# ---------------------------
# Convert Q1.15 → float for verification
# ---------------------------
x_real_float_out = [val / Q_SCALE for val in x_real]
x_imag_float_out = [val / Q_SCALE for val in x_imag]

print("\nVerification (Float):")
print("Real:", [f"{v:.4f}" for v in x_real_float_out])
print("Imag:", [f"{v:.4f}" for v in x_imag_float_out])


