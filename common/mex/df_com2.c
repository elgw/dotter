#include "mex.h"
#include "com2.c"

// Provides a MATLAB interface from com2.c

void mexFunction(int nlhs, mxArray *plhs[],int nrhs, const mxArray *prhs[]) 
{

  int verbosive = 0;

  if (!(nrhs==2)) {
     mexErrMsgTxt("There should be two inputs.");
  }

  /* Check data types of the input arguments. */
  if (!(mxIsDouble(prhs[0]))) {
    mexErrMsgTxt("First argument must be of type double.");
  }

  if (!(mxIsDouble(prhs[1]))) {
    mexErrMsgTxt("Second argument must be of type double.");
  }

  double * V = (double *) mxGetPr(prhs[0]);
  int VnDim = mxGetNumberOfDimensions(prhs[0]);
  const int * Vdim = mxGetDimensions(prhs[0]);

  if(! (VnDim == 2))
    mexErrMsgTxt("Volume has to be 2D");

  double * P = (double *) mxGetPr(prhs[1]);
  int PnDim = mxGetNumberOfDimensions(prhs[1]);
  const int * Pdim = mxGetDimensions(prhs[1]);
  const size_t Pnel = mxGetNumberOfElements(prhs[1]);

  if(!(PnDim == 2))
    mexErrMsgTxt("List of dots has to be 2D");

  if(!(Pdim[0] == 2))
    mexErrMsgTxt("List of dots has to be of size [2xN]");

  // Prepare the output matrix
  int Cdim[] = {0,0};
  Cdim[0] = 2; Cdim[1] = Pnel/2;
 
 if(verbosive) { 
  printf("V: %dx%d\n", Vdim[0], Vdim[1]);
  printf("C: %dx%d\n", Cdim[0], Cdim[1]);
 }

  plhs[0] = mxCreateNumericArray(2,  Cdim, mxDOUBLE_CLASS, mxREAL);
  double * C = (double *) mxGetPr(plhs[0]);

  if(1)
    com2(V, Vdim[0], Vdim[1], 
      P, C, Pdim[1]);

  for(size_t kk =0; kk<Pnel; kk++)
    C[kk]++;

}
