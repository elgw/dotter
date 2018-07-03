#include "mex.h"
#include "volume_spheres_sampling.c"

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


double radius = 0;
if(nrhs>0)
{
  double * r = (double *) mxGetPr(prhs[0]);
  radius = r[0];
}

const mwSize out_size [] = {1,1,1};
  plhs[0] = mxCreateNumericArray(3,  out_size, mxDOUBLE_CLASS, mxREAL);
  double * out = (double *) mxGetPr(plhs[0]);

  double * A = mxGetPr(prhs[1]);
  size_t nA = floor(mxGetNumberOfElements(prhs[1])/3.0);
size_t n_samples = 10e6;

out[0] = sphere3_sampling(n_samples, radius, A, nA);

}
