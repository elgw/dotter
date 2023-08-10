#include "mex.h"
#include "fwhm1d.c"
#include "matrix.h"

bool double_vector_isFinite(double * V, size_t N)
{
  for(size_t kk = 0; kk< N; kk++)
  {
    if(!mxIsFinite(V[kk]))
    {
      return false;
    }
  }
  return true;
}

void mexFunction(int nlhs, mxArray *plhs[],
                 int nrhs, const mxArray *prhs[])
{
  int minSize = 7; /* Minimal number of pixels */

  if(nrhs != 1)
  {
    mexErrMsgTxt("You have to provide one profile as input (double vector)");
  }

  if( ! mxIsDouble(prhs[0]))
  {
      mexErrMsgTxt("Error: The first argument  must be a 1D-array of type double");
  }

  int N = mxGetNumberOfElements(prhs[0]);
  if (N%2 == 0)
  {
      // TODO don't see why this is necessary
      mexErrMsgTxt("signal has to have an odd number of elements");
  }

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

  if( double_vector_isFinite(y, N) )
  {
    if(fwhm1d(x, y, N, fwhmvalues))
    {
      // if failed for some reason, return -1
      fwhmvalues[0] = -1;
    }
  } else { // if not finite signal, return -1
    fwhmvalues[0] = -1;
  }
  free(x);
  return;
}
