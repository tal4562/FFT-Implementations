import numpy as np
import math
from fractions import Fraction


def decimal_to_All(x: float, M: int, N: int, ang: bool = False):
    """
    M = integer bits INCLUDING sign
    N = fractional bits
    x = decimal value, if it is an angle can be in radians or degrees. always in the interval [-pi, pi)

    Convert a number in the range [-2^(M-1), 2^(M-1)-2^-N] to Q(M.N) format.
    Prints value, Q integer, binary, and hex.

    QM.N can represent signed numbers in the interval [-2 ^(M-1), 2 ^(M-1) - 2^(-N)]
    Resolution is 2^(-N)
    decimal = Q_num / (2^N)
    """
    if ang and abs(x) > np.pi + 0.01:  # x is in degrees, convert to radians than convert to Q
        # x [rad] = x [deg] * pi / 180
        # x [ normalized to -1,1] = x / pi
        # so its simply x / 180
        x /= 180
    if ang and abs(x) < np.pi:
        x /= np.pi
    # Check input range
    min_val = -2 ** (M - 1)
    max_val = 2 ** (M - 1) - 2 ** (-N)
    assert min_val <= x <= max_val, f"Input must be in [{min_val}, {max_val}]"

    W = M + N
    SCALE = 1 << N  # 2^N scaling for fractional bits

    # Convert to Q(M.N)
    q_val = int(round(x * SCALE))

    # Mask for W-bit two's complement
    masked = q_val & ((1 << W) - 1)

    # Binary & Hex
    bin_str = f"{masked:0{W}b}"
    hex_width = (W + 3) // 4
    hex_str = f"0x{masked:0{hex_width}X}"

    # Print nicely
    q_label = f"Q{M}.{N} dec"
    if ang:
        frac = Fraction(x).limit_denominator(16)
        print(
            f"Angle degrees: {180 * x}, Angle radians: {x * np.pi} = {frac.numerator}π/{frac.denominator}, Angle normalized: {x}")
    else:
        print(f"Value: {x}")
    print(f"{q_label}: {q_val}")
    print(f"Binary: {bin_str}")
    print(f"Hex: {hex_str}")


def qM_N_from_hw(q_val: int, M: int, N: int, ang: bool = False):
    """
    Convert a stored Q(M.N) integer to all representations.

    Parameters:
    - q_val : int
        Stored integer in hardware (W = M+N bits signed two's complement)
    - M : int
        Integer bits INCLUDING sign
    - N : int
        Fractional bits
    - ang : bool
        If True, treat the value as a normalized angle in [-pi, pi], scaled by pi

    Prints:
    - Decimal value (scaled by 2^N)
    - Angle in radians / degrees / fraction of π if ang=True
    - Binary string
    - Hex string
    """
    W = M + N
    # --- Convert from two's complement if negative ---
    if q_val & (1 << (W - 1)):
        q_val_signed = q_val - (1 << W)
    else:
        q_val_signed = q_val

    # --- Decimal value ---
    x_dec = q_val_signed / (1 << N)

    # --- Binary & Hex strings ---
    bin_str = f"{q_val & ((1 << W) - 1):0{W}b}"
    hex_width = (W + 3) // 4
    hex_str = f"0x{q_val & ((1 << W) - 1):0{hex_width}X}"

    # --- Print results ---
    print(f"Stored integer (Q{M}.{N}): {q_val_signed}")
    print(f"Binary: {bin_str}")
    print(f"Hex: {hex_str}")
    print(f"Decimal value: {x_dec:.6f}")

    if ang:
        angle_rad = x_dec * np.pi
        angle_deg = angle_rad * 180 / np.pi
        frac = Fraction(x_dec).limit_denominator(16)
        print(f"Angle radians: {angle_rad:.6f}")
        print(f"Angle degrees: {angle_deg:.6f}")
        print(f"Angle fraction of π: {frac.numerator}/{frac.denominator} π")


def bin_To_All(bin_str: str, M: int, N: int, ang: bool = False):
    """
    Convert a binary string representing a stored Q(M.N) number to all representations.

    Parameters:
    - bin_str : str
        Binary string of length W = M+N
    - M : int
        Integer bits INCLUDING sign
    - N : int
        Fractional bits
    - ang : bool
        If True, treat the value as a normalized angle in [-pi, pi], scaled by pi

    Prints:
    - Stored integer
    - Decimal value
    - Angle in radians / degrees / fraction of π if ang=True
    - Hex string
    """
    W = M + N
    assert len(bin_str) == W, f"Binary string length must be {W}"

    # Convert binary string to integer
    q_val = int(bin_str, 2)

    # --- Convert from two's complement if negative ---
    if q_val & (1 << (W - 1)):
        q_val_signed = q_val - (1 << W)
    else:
        q_val_signed = q_val

    # --- Decimal value ---
    x_dec = q_val_signed / (1 << N)

    # --- Hex representation ---
    hex_width = (W + 3) // 4
    hex_str = f"0x{q_val:0{hex_width}X}"

    # --- Print results ---
    print(f"Binary: {bin_str}")
    print(f"Stored integer (Q{M}.{N}): {q_val_signed}")
    print(f"Hex: {hex_str}")
    print(f"Decimal value: {x_dec:.6f}")

    if ang:
        angle_rad = x_dec * np.pi
        angle_deg = angle_rad * 180 / np.pi
        frac = Fraction(x_dec).limit_denominator(16)
        print(f"Angle radians: {angle_rad:.6f}")
        print(f"Angle degrees: {angle_deg:.6f}")
        print(f"Angle fraction of π: {frac.numerator}/{frac.denominator} π")


def hex_To_All(hex_str: str, M: int, N: int, ang: bool = False):
    """
    Convert a hex string representing a stored Q(M.N) number to all representations.

    Parameters:
    - hex_str : str
        Hex string of length corresponding to W = M+N bits
    - M : int
        Integer bits INCLUDING sign
    - N : int
        Fractional bits
    - ang : bool
        If True, treat the value as a normalized angle in [-pi, pi], scaled by pi

    Prints:
    - Stored integer
    - Decimal value
    - Angle in radians / degrees / fraction of π if ang=True
    - Binary string
    """
    W = M + N
    # Convert hex string to integer
    q_val = int(hex_str, 16)

    # Convert to binary string
    bin_str = f"{q_val:0{W}b}"

    # --- Convert from two's complement if negative ---
    if q_val & (1 << (W - 1)):
        q_val_signed = q_val - (1 << W)
    else:
        q_val_signed = q_val

    # --- Decimal value ---
    x_dec = q_val_signed / (1 << N)

    # --- Print results ---
    print(f"Hex: {hex_str}")
    print(f"Binary: {bin_str}")
    print(f"Stored integer (Q{M}.{N}): {q_val_signed}")
    print(f"Decimal value: {x_dec:.6f}")

    if ang:
        angle_rad = x_dec * np.pi
        angle_deg = angle_rad * 180 / np.pi
        frac = Fraction(x_dec).limit_denominator(16)
        print(f"Angle radians: {angle_rad:.6f}")
        print(f"Angle degrees: {angle_deg:.6f}")
        print(f"Angle fraction of π: {frac.numerator}/{frac.denominator} π")


def twiddle_LUT(N_FFT: int, M: int, N: int):
    """
    Generate twiddle factors in decimal, Q, hex and binary and prints to the screen
    M = integer bits INCLUDING sign bit
    N = fractional bits
    """

    W = M + N  # total bits
    scale = 1 << N  # scale = 2^N
    mask = (1 << W) - 1  # two's complement mask

    k = np.arange(N_FFT)

    # Integer Q(M.N) values in Q
    cos_vals = [int(round(np.cos(2 * np.pi * i / N_FFT) * scale)) for i in k]
    sin_vals = [int(round(-np.sin(2 * np.pi * i / N_FFT) * scale)) for i in k]

    # column widths
    dec_width = max(len(str(max(cos_vals + sin_vals, key=abs))), 6)
    hex_width = (W + 3) // 4  # number of hex digits
    bin_width = W  # full binary width
    print('Twiddles LUT for exp(-2πjk/N)' "\n")
    # Build headline label (e.g. "Q1.15 Dec")
    q_label = f"Q{M}.{N} Dec"

    # ----------- COSINE HEADER -----------
    header_cos = (
        f"{'k':>2}  "
        f"{'cos':>10}  "
        f"{q_label:>{dec_width + 2}}  "
        f"{'Hex':>{hex_width + 2}}  "
        f"{'Binary':>{bin_width}}"
    )
    print(header_cos)

    for i in range(N_FFT):
        val = cos_vals[i]
        masked = val & mask  # keeps exactly W bits
        print(
            f"{i:>2}  "
            f"{np.cos(2 * np.pi * i / N_FFT):10.6f}  "
            f"{val:>{dec_width}}  "
            f"0x{masked:0{hex_width}X}  "
            f"{masked:0{bin_width}b}"
        )

    print("\n")

    # ----------- -SIN HEADER -----------
    header_sin = (
        f"{'k':>2}  "
        f"{'-sin':>10}  "
        f"{q_label:>{dec_width + 2}}  "
        f"{'Hex':>{hex_width + 2}}  "
        f"{'Binary':>{bin_width}}"
    )
    print(header_sin)

    for i in range(N_FFT):
        val = sin_vals[i]
        masked = val & mask  # keeps exactly W bits
        print(
            f"{i:>2}  "
            f"{-np.sin(2 * np.pi * i / N_FFT):10.6f}  "
            f"{val:>{dec_width}}  "
            f"0x{masked:0{hex_width}X}  "
            f"{masked:0{bin_width}b}"
        )

    return cos_vals, sin_vals


def arctan_LUT_hw(N_iter: int, M: int, N: int):
    """
    Generate CORDIC arctangent LUT scaled for hardware in Q(M.N) format.

    - M = integer bits INCLUDING sign bit
    - N = fractional bits
    - LUT stores arctan(2^-i)/pi scaled to Q(M.N)
    """
    W = M + N
    SCALE = 1 << N  # 2^N scaling

    # Generate LUT in integer Q(M.N)
    LUT = [int(round(math.atan(2 ** -i) / math.pi * SCALE)) for i in range(N_iter)]

    # Formatting widths
    dec_width = max(len(str(max(LUT, key=abs))), 6)
    hex_width = (W + 3) // 4
    bin_width = W

    # Headline
    q_label = f"Q{M}.{N} Dec"
    header = (f"{'i':>2} | {'atan(2^-i) [rad]':>15} | {'atan [deg]':>10} | "
              f"{q_label:>{dec_width}} | {'Hex':>{hex_width}} | {'Bin':>{bin_width}}")
    print(header)
    print("-" * (len(header) + 2))
    K = 1  # cordic gain
    # Print LUT values
    for i, val in enumerate(LUT):
        K *= np.sqrt(1 + 2 ** (-2 * i))
        rad = math.atan(2 ** -i)
        deg = math.degrees(rad)
        masked = val & ((1 << W) - 1)  # mask for W-bit two's complement
        hex_str = f"0x{masked:0{hex_width}X}"
        bin_str = f"{masked:0{bin_width}b}"
        print(f"{i:2d} | {rad:15.6f} | {deg:10.4f} | {val:>{dec_width}d} | {hex_str} | {bin_str}")
    print("\n""Cordic gain: " + str(K) + '\nGain inverse')
    decimal_to_All(1 / K, M, N)
    return LUT


def cordic_table_xyz_QM_N(N_iter: int, M: int, N: int, theta: float, K: float = 0.607252935, show_hex: bool = False,
                          show_bin: bool = False):
    """
    Generate a CORDIC rotation mode trace for a given angle in general Q(M.N) format.

    Parameters:
        N_iter  : int    - number of CORDIC iterations
        M       : int    - integer bits including sign
        N       : int    - fractional bits
        theta   : float  - input angle in degrees
        K       : float  - cordic inverse gain
        show_hex: bool   - whether to print hex columns
        show_bin: bool   - whether to print binary columns

    Prints:
        - Iteration table with x, y, z in decimal, optional binary and hex
        - Final x, y, z values in decimal and float
        - Verification using math.cos/math.sin
    """
    W = M + N
    SCALE = 1 << N

    # --- Convert input angle to Q format (normalized [-pi,pi] -> [-1,1]) ---
    if abs(theta) > np.pi /2 + 0.001:
        if abs(theta) > 90:
            print('Cordic converges only for -90 < theta < 90 [degrees]')
        z_start = int(round(theta / 180 * SCALE))  # degrees -> Q format [-1,1]
    else:
        if abs(theta) > np.pi:
            print('Cordic converges only for -pi/2 < theta < pi/2 [radians]')
        z_start = int(round(theta / np.pi * SCALE))  # radians -> Q format [-1,1]

    # --- Pre-scaled CORDIC K factor in Q(M.N) ---
    x_start = int(round(K * SCALE))
    y_start = 0

    # --- Precompute arctangent LUT in Q(M.N) ---
    LUT = [int(round(math.atan(2 ** -i) / math.pi * SCALE)) for i in range(N_iter)]

    # --- Initialize registers ---
    x, y, z = x_start, y_start, z_start
    trace = []

    # --- CORDIC iterations ---
    for i in range(N_iter):
        trace.append({'i': i, 'x_i': x, 'y_i': y, 'z_i': z})
        sigma = 1 if z >= 0 else -1
        x_new = x - sigma * (y >> i)
        y_new = y + sigma * (x >> i)
        z_new = z - sigma * LUT[i]
        x, y, z = x_new, y_new, z_new

    trace.append({'i': N_iter, 'x_i': x, 'y_i': y, 'z_i': z})

    # --- Compute widths ---
    hex_width = (W + 3) // 4

    # --- Print Table Header ---
    header = f"{'i':>2} | {'x_i dec':>20} | {'y_i dec':>20} | {'z_i dec':>20}"
    if show_bin:
        header += f" | {'x_i bin':>{W}} | {'y_i bin':>{W}} | {'z_i bin':>{W}}"
    if show_hex:
        header += f" | {'x_i hex':>{hex_width + 2}} | {'y_i hex':>{hex_width + 2}} | {'z_i hex':>{hex_width + 2}}"

    print(f"## CORDIC Rotation Mode Trace (Q{M}.{N})")
    print(f"Initial Z_0 Angle: {theta:.6f}°")
    print("-" * len(header))
    print(header)
    print("-" * len(header))

    # --- Print iteration table ---
    for current in trace:
        line = f"{current['i']:2d} | {current['x_i']:20d} | {current['y_i']:20d} | {current['z_i']:20d}"
        if show_bin:
            line += f" | {current['x_i'] & ((1 << W) - 1):0{W}b} | {current['y_i'] & ((1 << W) - 1):0{W}b} | {current['z_i'] & ((1 << W) - 1):0{W}b}"
        if show_hex:
            line += f" | 0x{current['x_i'] & ((1 << W) - 1):0{hex_width}X} | 0x{current['y_i'] & ((1 << W) - 1):0{hex_width}X} | 0x{current['z_i'] & ((1 << W) - 1):0{hex_width}X}"
        print(line)

    # --- Final results ---
    final = trace[N_iter]
    print("\n" + "-" * len(header))
    print("## Final CORDIC Results")
    print(f"x (cos): Decimal={final['x_i']}, Float={final['x_i'] / SCALE:.6f}")
    print(f"y (sin): Decimal={final['y_i']}, Float={final['y_i'] / SCALE:.6f}")
    print(f"z (Error): Decimal={final['z_i']}, Float={final['z_i'] / SCALE:.6f}")

    # --- Verification ---
    angle_rad = math.radians(theta)
    print("\n## Verification (Target)")
    print(f"Target Cos({theta:.6f}°): {math.cos(angle_rad)}", ' Cos error = '+ str(np.abs(final['x_i'] / SCALE-math.cos(angle_rad))))
    print(f"Target Sin({theta:.6f}°): {math.sin(angle_rad)}", ' Sine error = '+ str(np.abs(final['y_i'] / SCALE-math.sin(angle_rad))))

print(hex_To_All('5a82',1,15))