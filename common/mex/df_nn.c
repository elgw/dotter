#include "mex.h"

#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include "nn.c"

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray
*prhs[])
{

  if (nrhs != 2) {
    mexErrMsgTxt("There should be two inputs.");
  }

  /* Check data types of the input arguments. */
  if (!(mxIsDouble(prhs[0]))) {
    mexErrMsgTxt("First argument must be of type double.");
  }
  
  if (!(mxIsDouble(prhs[1]))) {
    mexErrMsgTxt("First argument must be of type double.");
  }

  if(! mxGetNumberOfDimensions(prhs[0]) == 2) {
    mexErrMsgTxt("D has to be 2-dimensional");
  }

  const mwSize * Ddim = mxGetDimensions(prhs[0]);
  //printf("Dimensions: %zu %zu\n", Ddim[0], Ddim[1]);

  double * D = mxGetPr(prhs[0]);
  double * d = mxGetPr(prhs[1]);
  plhs[0] = mxCreateNumericArray(1, Ddim+1, mxUINT8_CLASS, mxREAL);
  uint8_t * X = (uint8_t *) mxGetPr(plhs[0]);

  nn(D, X, Ddim[1], Ddim[0], d[0]);
  
  return;
}

