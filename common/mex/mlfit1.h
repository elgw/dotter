#ifndef __mlfit1_h_
//' Localization of dots in the image V using Maximum Likelihood
int localize(double * V, // Volumetric, i.e., 3D image
    size_t Vm, size_t Vn, size_t Vp, // Size of V Columns, Row, Slices
    double * D, size_t Dm, // List of Dm/3 dots to fit
    double * F, // Fitted coordinates -- this is the output. Has to be pre-allocated
    double sigma_xy, // Sigma for the Gaussians in the lateral plane
    double sigma_z); // Sigma for the Gaussians in the axial plane
#else
#define __mlfit1_h_
#endif
