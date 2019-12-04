#include "mex.h"
#include "com3.c"

// Provides a MATLAB interface from com3.c

void mexFunction(int nlhs, mxArray *plhs[],int nrhs, const mxArray *prhs[]) 
{

  int verbosive = 0;
  int weighted = 0;

  if (nrhs<2 || nrhs>3) {
    mexErrMsgTxt("There should be two or three inputs.");
  }

  /* Check data types of the input arguments. */
  if (!(mxIsDouble(prhs[0]))) {
    mexErrMsgTxt("First argument must be of type double.");
  }

  if (!(mxIsDouble(prhs[1]))) {
    mexErrMsgTxt("Second argument must be of type double.");
  }

  if(nrhs>2){
    if ((mxIsDouble(prhs[2]))) {
      double * t = (double *) mxGetPr(prhs[2]);
      weighted = t[0];
      assert(weighted == 0 || weighted == 1);
    }
  }

  double * V = (double *) mxGetPr(prhs[0]);
  mwSize VnDim = mxGetNumberOfDimensions(prhs[0]);
  const mwSize * Vdim = mxGetDimensions(prhs[0]);

  if(! (VnDim == 3))
    mexErrMsgTxt("Volume has to be 3D");

  double * P = (double *) mxGetPr(prhs[1]);
  mwSize PnDim = mxGetNumberOfDimensions(prhs[1]);
  const mwSize * Pdim = mxGetDimensions(prhs[1]);
  const mwSize Pnel = mxGetNumberOfElements(prhs[1]);

  if(!(PnDim == 2))
    mexErrMsgTxt("List of dots has to be 2D");

  if(!(Pdim[0] == 3))
    mexErrMsgTxt("List of dots has to be of size [3xN]");

  // Prepare the output matrix
  mwSize Cdim[] = {0,0};
  Cdim[0] = 3; Cdim[1] = Pnel/3;

  if(verbosive) { 
    printf("V: %dx%dx%d\n", Vdim[0], Vdim[1], Vdim[2]);
    printf("C: %dx%d\n", Cdim[0], Cdim[1]);
  }

  plhs[0] = mxCreateNumericArray(2,  Cdim, mxDOUBLE_CLASS, mxREAL);
  double * C = (double *) mxGetPr(plhs[0]);

  com3(V, Vdim[0], Vdim[1], Vdim[2], 
      P, C, Pdim[1], weighted);

  for(size_t kk =0; kk<Pnel; kk++)
    C[kk]++;

}
