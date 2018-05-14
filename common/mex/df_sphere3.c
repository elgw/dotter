#include "mex.h"
#include "sphere3.c"

void mexFunction(int nlhs, mxArray *plhs[],int nrhs, const mxArray *prhs[]) 
{

if(nrhs <2 )
  mexErrMsgTxt("There should be at least two inputs");

  if (!(mxIsDouble(prhs[0]))) {
    mexErrMsgTxt("First argument must be of type double.");
  }

  if (!(mxIsDouble(prhs[1]))) {
    mexErrMsgTxt("Second argument must be of type double.");
  }

double * Bin = (double * ) mxGetPr(prhs[0]);
double * D = (double * ) mxGetPr(prhs[1]);

double radius = 0;
if(nrhs>2)
{
  double * r = (double *) mxGetPr(prhs[2]);
  radius = r[0];
}

  const mwSize * size_B = mxGetDimensions(prhs[0]);
  const mwSize N = mxGetNumberOfElements(prhs[1])/3;
  const mwSize numel_B = mxGetNumberOfElements(prhs[0]);

 
  plhs[0] = mxCreateNumericArray(3,  size_B, mxDOUBLE_CLASS, mxREAL);
  double * B = (double *) mxGetPr(plhs[0]);
 
  for(size_t kk = 0; kk<numel_B; kk++)
    B[kk] = Bin[kk];


sphere3(B, size_B[0], size_B[1], size_B[2], D, N, radius);

}
