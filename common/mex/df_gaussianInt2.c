#include "mex.h"
#include "string.h"
#include "math.h"
#include "gaussianInt2.c"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray
    *prhs[])
{

  if(nrhs != 3)
    mexErrMsgTxt("You have to provide three inputs");

  if( ! mxIsDouble(prhs[0]))
  { mexErrMsgTxt("Check the data type of the input arguments."); }

  if(mxGetNumberOfElements(prhs[0]) != 2)
    mexErrMsgTxt("mu has to be two elements");

  if(mxGetNumberOfElements(prhs[1]) != 2)
    mexErrMsgTxt("sigma has to be two elements");
  
  if(mxGetNumberOfElements(prhs[2]) != 1)
    mexErrMsgTxt("Side length not specified");


  double * mu = mxGetPr(prhs[0]);
  double * sigma = mxGetPr(prhs[1]);
  double * side = mxGetPr(prhs[2]);


  int w = 2*side[0]+1;

  if(w<3)
    mexErrMsgTxt("side has to be at least 3");

  if(w>10000)
    mexErrMsgTxt("side > 10000");

  const mwSize ut_dim[]={(mwSize) w, (mwSize) w, (mwSize) 1};

  if(w>100)
    printf("Input: mu: %.2f, %.2f, sigma: %.2f, side: %.0f \n", mu[0], mu[1], sigma[0], side[0]);

  plhs[0] = mxCreateNumericArray(2, ut_dim, mxDOUBLE_CLASS, mxREAL);  
  double * GI = (double *) mxGetPr(plhs[0]); 

  gaussianInt2(GI, mu, sigma, w); 
}
