#include <string.h>
#include "mex.h"

#include "blit3.c"
#include "gaussianInt2.c"
#include "imshift.h"

// Provides a MATLAB interface from blit3.c

#ifndef verbose
#define verbose 1
#endif

void mexFunction(int nlhs, mxArray *plhs[],int nrhs, const mxArray *prhs[]) 
{

  int verbosive = 0;

  photonw pw = xyz_volume;

  if (nrhs<2 || nrhs>4) {
    mexErrMsgTxt("There should be two or three inputs.");
  }

  /* Check data types of the input arguments. */
  if (!(mxIsDouble(prhs[0]))) {
    mexErrMsgTxt("First argument must be of type double.");
  }

  if (!(mxIsDouble(prhs[1]))) {
    mexErrMsgTxt("Second argument must be of type double.");
  }

  if (!(mxIsDouble(prhs[2]))) {
    mexErrMsgTxt("Third argument must be of type double.");
  }

  if(nrhs>3)
  {
    double * t = mxGetPr(prhs[3]);
    switch((int) t[0]){
      case 0:
        pw = xyz_volume;
        break;
      case 1:
        pw = xy_plane;
        break;
      case 2:
        pw = mid_point;
        break;
    }
  }

  double * V = (double *) mxGetPr(prhs[0]);
  int VnDim = mxGetNumberOfDimensions(prhs[0]);
  const int * Vdim = mxGetDimensions(prhs[0]);
  const size_t Vnel = mxGetNumberOfElements(prhs[0]);

  if(! (VnDim == 3))
    mexErrMsgTxt("Volume has to be 3D");

  double * K = (double *) mxGetPr(prhs[1]);
  int KnDim = mxGetNumberOfDimensions(prhs[1]);
  const int * Kdim_temp = mxGetDimensions(prhs[1]);
  const size_t Knel = mxGetNumberOfElements(prhs[1]);

  int Kdim[] = {0,0,0};

  double * P = (double *) mxGetPr(prhs[2]);
  //  int PnDim = mxGetNumberOfDimensions(prhs[2]);
  const int * Pdim = mxGetDimensions(prhs[2]);
  //  const size_t Pnel = mxGetNumberOfElements(prhs[2]);

  // Also handle 1D and 2D kernels
  Kdim[0] = Kdim_temp[0];
  if(KnDim < 3){
    Kdim[2] = 1;
  } else {
    Kdim[2] = Kdim_temp[2];
  }
  if(KnDim<2) {
    Kdim[1] = 1;
  } else {
    Kdim[1] = Kdim_temp[1];
  }

  if((Pdim[0] < 3))
    mexErrMsgTxt("List of dots has to be of size [3xN] or [7xN]");

  int nF = Pdim[0];

  if(verbosive) { 
    printf("V: %dx%dx%d\n", Vdim[0], Vdim[1], Vdim[2]);
  }

  plhs[0] = mxCreateNumericArray(VnDim,  Vdim, mxDOUBLE_CLASS, mxREAL);
  double * W = (double *) mxGetPr(plhs[0]);
  memcpy(W, V, Vnel*sizeof(double));
  
  const int one_indexing = 1;
  if(Knel == 0)
  {
    // printf("No kernel supplied, using a Gaussian kernel\n");
    if(! (nF == 7))
      mexErrMsgTxt("Each dot has to have x, y, z, #phots, sx, sy, sz");
    blit3g(W, Vdim[0], Vdim[1], Vdim[2], 
           P, Pdim[1], pw, one_indexing);

  }
  else
  {

#if verbose > 0
    printf("Kdim: %d %d %d\n", Kdim[0], Kdim[1], Kdim[2]);
#endif

  double * KS = calloc(Kdim[0]*Kdim[1]*Kdim[2], sizeof(double));


    for(uint32_t pp = 0; pp<Pdim[1]; pp++)  {
      // KS = K;
      memcpy(KS, K, Kdim[0]*Kdim[1]*Kdim[2]*sizeof(double));
      
      double dx = -nearbyint(P[nF*pp+0]) + P[nF*pp+0];
      double dy = -nearbyint(P[nF*pp+1]) + P[nF*pp+1];
      double dz = -nearbyint(P[nF*pp+2]) + P[nF*pp+2];

 //     printf("delta: %f %f %f\n", dx, dy, dz);

      if( dx!=0 || dy!=0 || dz!=0)
        imshift3(KS, Kdim[0], Kdim[1], Kdim[2], dx, dy, dz, 3);

      blit3(W, Vdim[0], Vdim[1], Vdim[2], 
          KS, Kdim[0], Kdim[1], Kdim[2],
          (int64_t) (P[nF*pp+0]-1-dx - (Kdim[0]-1)/2), 
          (int64_t) (P[nF*pp+1]-1-dy - (Kdim[1]-1)/2), 
          (int64_t) (P[nF*pp+2]-1-dz - (Kdim[2]-1)/2), 
          0);
    }
    free(KS);
  }

}
