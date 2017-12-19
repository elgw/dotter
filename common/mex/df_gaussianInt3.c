#include "mex.h"
#include "string.h"
#include "math.h"
#include "gaussianInt2.c"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray
    *prhs[])
{

  if(!(nrhs == 3))
    mexErrMsgTxt("There should be three inputs");

  if( ! mxIsDouble(prhs[0]))
  { mexErrMsgTxt("Check the data type of the input arguments."); }

  if( ! mxIsDouble(prhs[1]))
  { mexErrMsgTxt("Check the data type of the input arguments."); }

  if( ! mxIsDouble(prhs[1]))
  { mexErrMsgTxt("Check the data type of the input arguments."); }

  const size_t mDim = mxGetNumberOfElements(prhs[0]);
  const size_t sDim = mxGetNumberOfElements(prhs[1]);
  const size_t wDim = mxGetNumberOfElements(prhs[2]);

  if( mDim != 3)
    mexErrMsgTxt("Mu has to have three elements");

  if(sDim !=3)
    mexErrMsgTxt("sigma has to have three elements");

  if(wDim !=1)
    mexErrMsgTxt("size length has to be a single element");

  double * mu = mxGetPr(prhs[0]);
  double * sigma = mxGetPr(prhs[1]);
  double * side = mxGetPr(prhs[2]);

  //printf("Input: mu: %.2f, %.2f, sigma: %.2f, side: %.0f \n", mu[0], mu[1], sigma[0], side[0]);

  int w = 2*side[0]+1;
  int ut_dim[]={ w, w, w};


  plhs[0] = mxCreateNumericArray(3, ut_dim, mxDOUBLE_CLASS, mxREAL);  
  double * GI = (double *) mxGetPr(plhs[0]); 

  gaussianInt3(GI, mu, sigma, w); 
}
