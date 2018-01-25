#include <string.h>
#include <stdio.h>
#include <math.h>
#include "mex.h"
#include "conv1.h"

#ifndef verbose
#define verbose 1
#endif

void mexFunction(int nlhs, mxArray *plhs[],int nrhs, const mxArray *prhs[]) 
{


  if (! (nrhs==4)) {
    mexErrMsgTxt("There should be four inputs");
  }

  double * V = (double *) mxGetPr(prhs[0]);
  mwSize VnDim = mxGetNumberOfDimensions(prhs[0]);
  const mwSize * Vdim = mxGetDimensions(prhs[0]);
  const mwSize Vnel = mxGetNumberOfElements(prhs[0]);
#if verbose
  printf("Vnel: %lu\n", Vnel);
#endif

  if(VnDim < 2)
    mexErrMsgTxt("Input volume should be at least 2D");


  double * Kx = NULL;
  double * Ky = NULL;
  double * Kz = NULL;
  size_t nKx = 0;
  size_t nKy = 0;
  size_t nKz = 0;

  if(mxGetNumberOfElements(prhs[1])>0){
    Kx = (double *) mxGetPr(prhs[1]);
    nKx = mxGetNumberOfElements(prhs[1]);
  }
  if(mxGetNumberOfElements(prhs[2])>0) {
    Ky = (double *) mxGetPr(prhs[2]);
    nKy = mxGetNumberOfElements(prhs[2]);
  }
  if(mxGetNumberOfElements(prhs[3])>0) {
    Kz = (double *) mxGetPr(prhs[3]);
    nKz = mxGetNumberOfElements(prhs[3]);
  }

  size_t M = Vdim[0];
  size_t N = Vdim[1];

  size_t P = 1;

  if(VnDim>2)
    P = Vdim[2];

  if(nKx >= Vdim[0])
    mexErrMsgTxt("x kernel should be larger than size(V,1)");
  if(nKy >= Vdim[1])
    mexErrMsgTxt("y kernel should be larger than size(V,2)");
  if(P>1)
    if(nKz >= Vdim[2])
      mexErrMsgTxt("z kernel should be larger than size(V,3)");

#if verbose
  printf("VnDim: %lu\n", VnDim);
  printf("Vdim: %lux%lux%lu\n", Vdim[0], Vdim[1], Vdim[2]);
#endif

#if verbose
  printf("V: %lux%lux%lu, K:%lu, %lu, %lu\n", M, N, P, nKx, nKy, nKz);
#endif

  plhs[0] = mxCreateNumericArray(VnDim, Vdim, mxDOUBLE_CLASS, mxREAL);
  double * W = (double *) mxGetPr(plhs[0]);
  memcpy(W, V, Vnel*sizeof(double));

  conv1_3(W, M, N, P, Kx, nKx, Ky, nKy, Kz, nKz);

}


