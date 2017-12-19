#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include "mex.h"

void mexFunction(int nlhs, mxArray *plhs[],int nrhs, const mxArray *prhs[]) 
{

/*
  prhs     An array of right-hand input arguments.
  plhs     An array of left-hand output arguments.
  nrhs     The number of right-hand arguments, or the size of the prhs array.
  nlhs     The number of left-hand arguments, or the size of the plhs array
*/ 

if (!(mxIsDouble(prhs[0]))) {
    mexErrMsgTxt("First argument must be of type DOUBLE.");
  }

double *Pin, *Pout;
Pin = (double *) mxGetPr(prhs[0]);
const int* dim_array;
dim_array=mxGetDimensions(prhs[0]);
int out_dim[2];
for(int kk=0; kk<2; kk++)
  out_dim[kk]=dim_array[kk];


// Only allocate for the remaining points.
plhs[0] = mxCreateNumericArray(2, out_dim, mxDOUBLE_CLASS, mxREAL);
Pout = (double*) mxGetPr(plhs[0]);

}

