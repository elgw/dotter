#include "mex.h"
#include "mlfit1sn.c"

// Provides a MATLAB interface from mlfit1sn.c
// To fit sigma and number of photons for signals 
// at given locations.

void mexFunction(int nlhs, mxArray *plhs[],int nrhs, const mxArray *prhs[]) 
{

  int verbosive = 1;

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
  Cdim[0] = 5; Cdim[1] = Pnel/3;
 
 if(verbosive) { 
  printf("V: %zux%zux%zu\n", Vdim[0], Vdim[1], Vdim[2]);
  printf("C: %zux%zu\n", Cdim[0], Cdim[1]);
 }

  plhs[0] = mxCreateNumericArray(2,  Cdim, mxDOUBLE_CLASS, mxREAL);
  double * C = (double *) mxGetPr(plhs[0]);

  // Make a copy of the list of dots and convert the locations to
  // 0-based
  double * Q = malloc(Pdim[1]*Pdim[0]*sizeof(double));
  for(size_t kk = 0; kk<Pdim[0]*Pdim[1]; kk++)
    Q[kk] = P[kk]-1;

  if(1)
    mlfit1sn(V, Vdim[0], Vdim[1], Vdim[2], 
      Q, Pdim[1], C);


  free(Q);
}
