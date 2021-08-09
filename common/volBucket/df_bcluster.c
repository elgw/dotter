#include "mex.h"
#include "matrix.h"
#include "bcluster.c"
#include <stdint.h>

/* MATLAB interface for volBucket.c
  To compile and test:

  On mac:
  mex bcluster.c volBucket.c
  On UBUNTU:
  mex -v CFLAGS='$CFLAGS -std=c99' bcluster.c volBucket.c
  X = 100*rand(10,3);
  C = bcluster(X, 21.2);
*/

  void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray
*prhs[])
{

int verbose = 0; //

if (nrhs != 2)
  mexErrMsgTxt("Requires two inputs");

for(int kk = 0; kk< 2; kk++)
{
if( ! mxIsDouble(prhs[kk]))
 { mexErrMsgTxt("Check the data type of the input arguments."); }
}


if( mxGetNumberOfElements(prhs[1]) != 1)
  {
      mexErrMsgTxt("Radius has to be a single number");
  }

  size_t NN = mxGetNumberOfElements(prhs[0]);
  if( NN < 3)
  {
      mexErrMsgTxt("Requires at least one point.");
  }

  double * X = mxGetPr(prhs[0]);
  double * r = mxGetPr(prhs[1]);

  if(r[0] <= 0)
  {
      mexErrMsgTxt("r has to be positive");
  }


  const mwSize * sizeX = mxGetDimensions(prhs[0]);

  size_t N = sizeX[0]; // get from X


  if( N == 0 || NN < 3)
  { mexErrMsgTxt("Requires at least one point."); }

  double min = X[0];
  for(size_t kk = 0 ; kk<N; kk++)
  {
      if(X[kk] < min)
      {
          min = X[kk];
      }
  }

  if(min < 0)
  {
      mexErrMsgTxt("Only positive coordinates are allowed\n");
  }



if ((NN) % 3 != 0)
 { mexErrMsgTxt("3*N coordinates required"); }

if ( !(N*3 == NN) )
{ mexErrMsgTxt("Wrong dimensions of input coordinate list"); }

if(verbose)
 printf("got %d points\n", N);

uint32_t *C = malloc(3*N*sizeof(uint32_t));
memset(C, 0, 3*N*sizeof(uint32_t));

bcluster(X, N, r[0], C);

// Find out how long the list of clusters is and then prune it
size_t last = 0;
for(uint32_t kk=0; kk<3*N; kk++)
  if(C[kk]>0)
    last = kk;

if(verbose)
  printf("last: %ld\n", last+1);

  mwSize ut_dim[]={ last+1, 1};
  plhs[0] = mxCreateNumericArray(2, ut_dim, mxUINT32_CLASS, mxREAL);
  uint32_t * C2 = (uint32_t *) mxGetPr(plhs[0]);

for(size_t kk=0; kk<=last; kk++)
  C2[kk]=C[kk];

free(C);
}
