// this files holds the taylor and lut constants
#ifndef TAYLOR_LUT_COEFFICIENTS_H
#define TAYLOR_LUT_COEFFICIENTS_H

namespace Taylor {

    // for base angle
    inline constexpr double Two_PI = 2 * 3.14159265358979323846 ;
    // lut anchors
    inline constexpr double root2_2 = 0.70710678118654752440 ;
    inline constexpr double neg_root2_2 = -0.70710678118654752440 ;

    // Cosine coefficients
    inline constexpr double C2  = -0.5;
    inline constexpr double C4  =  4.16666666666666666667e-2 ;
    inline constexpr double C6  = -1.38888888888888888889e-3 ;
    inline constexpr double C8  =  2.48015873015873015873e-5 ;
    inline constexpr double C10 = -2.75573192239858906526e-7 ;
    inline constexpr double C12 =  2.08767569878680989792e-9 ;
    inline constexpr double C14 = -1.14707455977297247331e-11 ;

    // Sine coefficients
    inline constexpr double S3  = -1.66666666666666666667e-1 ;
    inline constexpr double S5  =  8.33333333333333333333e-3 ;
    inline constexpr double S7  = -1.98412698412698412698e-4 ;
    inline constexpr double S9  =  2.75573192239858906526e-6 ;
    inline constexpr double S11 = -2.50521083854417187751e-8 ;
    inline constexpr double S13 =  1.60590438368216145994e-10 ;
    inline constexpr double S15 = -7.64716373181981647590e-13 ;
}

#endif //TAYLOR_LUT_COEFFICIENTS_H