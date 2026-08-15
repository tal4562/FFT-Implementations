cmake_minimum_required(VERSION 3.31)
project(FFT_proj LANGUAGES CXX)

# Set C++ standard
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

# Optimization flags for GCC/MinGW (SIMD-friendly)
if (NOT MSVC)
    add_compile_options(-O3 -march=native -ffast-math -funroll-loops)
endif()

# This tells the compiler to look inside the "include" and "LUT" folders

# Add executable and link all source files
add_executable(FFT_proj
        main.cpp
        test_lut.cpp
        verify_fft.cpp
        time_fft.cpp
        FFT_V6.cpp

)
