#include "mex.h"
#include "volume_spheres_sampling.c"

void mexFunction(int nlhs, mxArray *plhs[],int nrhs, const mxArray *prhs[]) 
{

  if(nrhs <2 )
    mexErrMsgTxt("There should be at least three inputs");

  if (!(mxIsDouble(prhs[0]))) {
    mexErrMsgTxt("First argument, radius, must be of type double.");
  }

  if (!(mxIsDouble(prhs[1]))) {
    mexErrMsgTxt("Second argument, point set 1, must be of type double.");
  }

  if (!(mxIsDouble(prhs[2]))) {
    mexErrMsgTxt("Third argument, point set 2, must be of type double.");
  }

  size_t n_samples = 10e5;
  if(nrhs>3)
  {
    if (!(mxIsDouble(prhs[3]))) {
      mexErrMsgTxt("Fourth argument, number of samples, must be of type double.");
    }
    double * ns = (double *) mxGetPr(prhs[3]);
    double ns1 = abs(round(ns[0]));
    if(ns1<1000)
      mexErrMsgTxt("At least 1000 sample points has to be used.");

    n_samples = (size_t) ns1;
  }

  double * r = (double *) mxGetPr(prhs[0]);
  double radius = r[0];

  const mwSize out_size [] = {1,1,1};
  plhs[0] = mxCreateNumericArray(3,  out_size, mxDOUBLE_CLASS, mxREAL);
  double * out = (double *) mxGetPr(plhs[0]);

  double * A = mxGetPr(prhs[1]);
  size_t nA = floor(mxGetNumberOfElements(prhs[1])/3.0);
  double * B = mxGetPr(prhs[2]);
  size_t nB = floor(mxGetNumberOfElements(prhs[2])/3.0);


  out[0] = sphere3_sampling_intersection(n_samples, radius, 
      A, nA,
      B, nB);

}
