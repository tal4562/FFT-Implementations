# FFT Implementation

## Overview

This project explores the implementation of the Fast Fourier Transform (FFT) across both software and digital hardware.

The project includes:

- **Logisim** - 16-point FFT digital circuit using Q1.15 fixed-point arithmetic.
- **Verilog** - clockless, combinational implementation of the FFT for $N = 16$ and arbitrary $N = 2^k$.
- **C++** - performance-oriented Stockham FFT implementation using a radix-2 algorithm.
- **Python** - reference implementation and verification.

The goal of the project is to implement the FFT at different levels, from a Python reference implementation and C++ software implementation to a digital circuit in Logisim and a Verilog implementation.

The different implementations can be compared against each other to verify the correctness of the FFT and its fixed-point arithmetic.


## FFT Background

The Fast Fourier Transform (FFT) is an efficient algorithm for computing the Discrete Fourier Transform (DFT).

The DFT converts a signal from the time domain into its frequency-domain representation. A direct DFT computation requires $O(N^2)$ operations, while the FFT reduces this to $O(N \log N)$ by exploiting the structure of the DFT.

This project uses **radix-2 FFT algorithms**, which recursively decompose an $N$-point transform into smaller transforms. The computation is built from **butterfly operations** and complex multiplication by **twiddle factors**.

For a radix-2 FFT, the input size is generally restricted to:

$N = 2^k$

where $k$ is the number of FFT stages.


## Fixed-Point Representation - Q1.15

The Logisim FFT uses **16-bit signed Q1.15 fixed-point arithmetic**.

Q1.15 uses:

- **16 bits total**
- **1 sign bit**
- **15 fractional bits**

The fixed-point representation uses a scale factor of `2^15`:

fixed_value = real_value × $2^{15}$.


## Logisim

The Logisim implementation contains both a **16-point FFT DIT** and a separate **CORDIC algorithm** implementation.

The FFT uses **16-bit signed Q1.15 fixed-point arithmetic**. Its twiddle factors are generated using **precomputed lookup tables (LUTs)** rather than the CORDIC implementation.

The CORDIC implementation is included as a separate exploration of hardware-friendly trigonometric computation.


## Verilog

The Verilog implementation is a clockless, combinational implementation of the FFT for $N = 16$ and arbitrary $N = 2^k$.

Simulation is performed using **Icarus Verilog (iverilog)**, with waveform inspection using **GTKWave**.
