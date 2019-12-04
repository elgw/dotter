#include "mex.h"
#include "mlfit1.c"

/* Provides a MATLAB interface to mlfit1 
 * which provides dot fitting
 */

void mexFunction(int nlhs, mxArray *plhs[],int nrhs, const mxArray *prhs[]) 
{

  int verbosive = 0;

  if (!(nrhs==2 || nrhs==3)) {
    mexErrMsgTxt("There should be two or three inputs: Volumetric image, List of dots, sigma");
  }

  /* Check data types of the input arguments. */
  if (!(mxIsDouble(prhs[0]))) {
    mexErrMsgTxt("First argument must be of type double.");
  }

  if (!(mxIsDouble(prhs[1]))) {
    mexErrMsgTxt("Second argument must be of type double.");
  }

  double sigmaxy = 1;
  double sigmaz = 1;

  if(nrhs==3)
  {
    double * s = mxGetPr(prhs[2]);
    sigmaxy = s[0];
    sigmaz = sigmaxy;
  }

  if(sigmaxy<0.5)
    mexErrMsgTxt("Sigma has to be > .5");
  if(sigmaxy>4)
    mexErrMsgTxt("Sigma has to be > 4");

  if(nrhs==4)
  {
    double * s = mxGetPr(prhs[3]);
    sigmaz = s[0];
  }

  if(sigmaz<0.5)
    mexErrMsgTxt("Sigma has to be > .5");
  if(sigmaz>4)
    mexErrMsgTxt("Sigma has to be > 4");

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

  for(size_t kk = 0; kk<Vdim[0]*Vdim[1]*Vdim[2]; kk++)
  {
    if(V[kk]<=0)
        mexErrMsgTxt("V has to be postive");
  }

  // Prepare the output matrix
  mwSize Cdim[] = {0,0};
  Cdim[0] = 3; Cdim[1] = Pnel/3;

  if(verbosive) { 
    printf("V: %dx%dx%d\n", Vdim[0], Vdim[1], Vdim[2]);
    printf("C: %dx%d\n", Cdim[0], Cdim[1]);
  }

  plhs[0] = mxCreateNumericArray(2,  Cdim, mxDOUBLE_CLASS, mxREAL);
  double * C = (double *) mxGetPr(plhs[0]);

  // Make a copy of the list of dots and convert the locations to
  // 0-based
  double * Q = malloc(Pdim[1]*Pdim[0]*sizeof(double));
  for(size_t kk = 0; kk<Pdim[0]*Pdim[1]; kk++)
  {
    Q[kk] = P[kk]-1;
  }

  if(1)
    localize(V, Vdim[0], Vdim[1], Vdim[2], 
        Q, Pdim[1], C, sigmaxy, sigmaz);

  // Fix offsets to MATLAB 1-indexing
  for(size_t kk =0; kk<Pnel; kk++)
    C[kk]++;

  free(Q);
}
