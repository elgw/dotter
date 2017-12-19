#include "mex.h"
#include "fwhm1d.c"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray
    *prhs[])
{

  int minSize = 7;

  if(nrhs != 1)
    mexErrMsgTxt("You have to provide one");

  if( ! mxIsDouble(prhs[0]))
  { mexErrMsgTxt("Check the data type of the input arguments."); }

  int N =mxGetNumberOfElements(prhs[0]); 
  if (N%2 == 0)
    mexErrMsgTxt("signal has to have an odd number of elements");

  int N2 = (N-1)/2;

  if(N < minSize)
    mexErrMsgTxt("signal has to have at least 7 elements");

  double * y = mxGetPr(prhs[0]);

  const mwSize ut_dim[]={1,1, 1};

  plhs[0] = mxCreateNumericArray(2, ut_dim, mxDOUBLE_CLASS, mxREAL);  
  double * fwhmvalues = (double *) mxGetPr(plhs[0]); 
  double * x = malloc(N*sizeof(double));

  for(int kk = 0; kk<N; kk++)
    x[kk] = kk-N2;

  if(fwhm(x, y, N, fwhmvalues))
  {
    fwhmvalues[0] = -1;
  }
    

}
