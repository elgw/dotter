#include "mex.h"
#include "mlfitN.c"

// Provides a MATLAB interface mlfitN 

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

  if(! (VnDim == 3))
    mexErrMsgTxt("Volume has to be 3D");

  double * P = (double *) mxGetPr(prhs[1]);
  int PnDim = mxGetNumberOfDimensions(prhs[1]);
  const int * Pdim = mxGetDimensions(prhs[1]);
  const size_t Pnel = mxGetNumberOfElements(prhs[1]);

  if(!(PnDim == 2))
    mexErrMsgTxt("List of dots has to be 2D");

  if(!(Pdim[0] == 7))
    mexErrMsgTxt("List of dots has to be of size [7xN]");

  // Prepare the output matrix
  const int nfeat = 5;
  int Cdim[] = {0,0};
  Cdim[0] = nfeat; Cdim[1] = Pdim[1];
 
 if(verbosive) { 
  printf("V: %dx%dx%d\n", Vdim[0], Vdim[1], Vdim[2]);
  printf("C: %dx%d\n", Cdim[0], Cdim[1]);
 }

  plhs[0] = mxCreateNumericArray(2,  Cdim, mxDOUBLE_CLASS, mxREAL);
  double * C = (double *) mxGetPr(plhs[0]);

  // Make a copy of the list of dots and convert the locations to
  // 0-based
  double * Q = malloc(7*Pdim[1]*sizeof(double));
  for(size_t kk = 0; kk<Pdim[1]; kk++)
  {
    Q[7*kk+0] = P[7*kk+0]-1; // x
    Q[7*kk+1] = P[7*kk+1]-1; // y
    Q[7*kk+2] = P[7*kk+2]-1; // z
    Q[7*kk+3] = P[7*kk+3]; // nphot
    Q[7*kk+4] = P[7*kk+4]; // sigmax
    Q[7*kk+5] = P[7*kk+5]; // sigmay
    Q[7*kk+6] = P[7*kk+6]; // sigmaz
  }

  if(1)
    localize(V, Vdim[0], Vdim[1], Vdim[2], 
      Q, Pdim[0], Pdim[1], C);

  // Add 1 to x, y, z to correspond to matlab's indexing
 
  for(size_t kk =0; kk<Cdim[1]; kk++)
  {
    C[kk*Cdim[0]+0]++;
    C[kk*Cdim[0]+1]++;
    C[kk*Cdim[0]+2]++;
  }

  free(Q);
}
