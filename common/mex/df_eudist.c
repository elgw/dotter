#include "mex.h"
#include "eudist.c"

/*
 * Provides a MATLAB interface from eudist2.c for usage, 
 * see df_eudist_ut.m
 */

void mexFunction(int nlhs, mxArray *plhs[],int nrhs, const mxArray *prhs[]) 
{

  int nThreads = 4;

  if (nrhs<1 || nrhs>3) {
    mexErrMsgTxt("There should be 1 to three inputs.");
  }

  /* Check data types of the input arguments. */
  if (!(mxIsDouble(prhs[0]))) {
    mexErrMsgTxt("First argument must be of type double.");
  }

   double * V = (double *) mxGetPr(prhs[0]);
  mwSize VnDim = mxGetNumberOfDimensions(prhs[0]);
  const mwSize * Vdim = mxGetDimensions(prhs[0]);

  double dx = 1; double dy = 1; double dz = 1;
  if(nrhs>1)
  {
    double * D = (double *) mxGetPr(prhs[1]);
    dx = D[0];
    dy = D[1];
    dz = D[2];
  }

  if(VnDim < 2)
    mexErrMsgTxt("Image has to be at least 2D");
size_t d3 = 1;

  if(VnDim > 2)
    d3 = Vdim[2];

 const mwSize dim[] = {Vdim[0], Vdim[1], d3};
  plhs[0] = mxCreateNumericArray(3,  dim, mxDOUBLE_CLASS, mxREAL);

  double * D = (double *) mxGetPr(plhs[0]);

  edt(V, D, 
      (size_t) dim[0], (size_t) dim[1], (size_t) dim[2],
      dx, dy, dz, nThreads);
}


