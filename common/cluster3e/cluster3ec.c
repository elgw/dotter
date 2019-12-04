  #ifdef MATLAB_MEX_FILE
  #include "mex.h"
  #include "matrix.h"
  #endif
  #include <stdio.h>
  #include <stdlib.h>
  #include <assert.h>
  #include "string.h"
  #include "math.h"
  #include <stdint.h>
  /* 
cluster3ec.c 

Purpose: Cluster points that are within a certain Euclidean distance to each
other.

Interface/Input: 3D points, [x1,y2,z1, x2,y2,z2, ...]
Output: A label for each points, indicating the cluster it belongs to

Worst case O(N^2), but usually a little better.

Is easy to adapt to other (symmetric) metrics.
Can be adapted to higher/lower dimensions in ed2()

Use with MATLAB:
mex cluster3ec.c CXXOPTIMFLAGS='-O3 -Wall' -largeArrayDims

Erik Wernersson, 2015 08 31

*/

double ed2(double * a, double *b)
{
// Euclidean distance, squared 
  return  (a[0]-b[0])*(a[0]-b[0]) 
        + (a[1]-b[1])*(a[1]-b[1]) 
        + (a[2]-b[2])*(a[2]-b[2]);
}

size_t cluster3e(double * P, size_t N, double d2, uint32_t * C)
{

  // Store indexes of all remaining dots
  uint32_t * Q = (uint32_t*) malloc(N*sizeof(uint32_t));
  for(int kk = 0; kk<N; kk++)
    Q[kk] = kk;

uint32_t  cNum = 1; // Current cluster
uint32_t  cStart = 0; // First index of the cluster (in Q)
uint32_t  cEnd = 0; // Last index of the cluster (in Q)
uint32_t  cExp = 0; // Next point to expand from
uint32_t  pp = 0; // Q[pp] is the next element to be compared to Q[cExp]
uint32_t t; // used for swapping 

// printf("N: %lu\n", N);

while(cEnd<N) { // Until no more points
//   printf("= cStart: %d, cExp: %d, cEnd: %d\n", cStart, cExp, cEnd);

while(cExp <= cEnd && cExp <N) // If there is something more to expand
{
   pp = cEnd+1;
  while(pp < N) // The points to compare to
    {
   // printf("cStart: %d, cExp: %d, cEnd: %d\n", cStart, cExp, cEnd);
      if(ed2(P + 3*Q[pp], P + 3*Q[cExp])<d2)
        {
        //  printf("pp: %d\n", pp);
          cEnd++;
          t = Q[cEnd]; 
          Q[cEnd] = Q[pp];      
          Q[pp] = t;
        }
      pp++;
    }
    cExp++;
}
// Set cluster labels in C
for(int kk = cStart; kk<=cEnd; kk++)
  C[Q[kk]] = cNum;
cNum++;
// Prepare for a new cluster
  cStart = cEnd+1;
  cEnd = cStart;
  cExp = cStart;
}
 
  free(Q);
  return cNum-1;
}


#ifdef MATLAB_MEX_FILE

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray
*prhs[])
{

if (nrhs != 2)
  mexErrMsgTxt("Requires two inputs");

int verbose = 0;
if( ! mxIsDouble(prhs[0]))
 { mexErrMsgTxt("Check the data type of the input arguments."); }

  double * X = mxGetPr(prhs[0]);
  double * r = mxGetPr(prhs[1]);
  const mwSize * sizeX = mxGetDimensions(prhs[0]);

  size_t M = sizeX[0];
  size_t N = sizeX[1]; // get from X

  size_t NN = mxGetNumberOfElements(prhs[0]);

if ((NN) % 3 != 0)
 { mexErrMsgTxt("3*N coordinates required"); }

if( M!=3)
  { mexErrMsgTxt("Only 3D vectors supported"); }

if(verbose) 
 printf("got %d points\n", N);

if( N == 0)
 { mexErrMsgTxt("Requires at least one point."); }

//printf("%lu, %lu\n", M, N);
uint32_t *C = malloc(N*sizeof(uint32_t));
//memset(C, 0, 3*N*sizeof(uint32));
for(int kk = 0; kk<N; kk++)
  C[kk]=0;

size_t nC = cluster3e(X, N, r[0]*r[0], C); 

  mwSize ut_dim[]={ N, 1}; 
  plhs[0] = mxCreateNumericArray(2, ut_dim, mxUINT32_CLASS, mxREAL);  
  uint32_t * C2 = (uint32_t *) mxGetPr(plhs[0]);

for(size_t kk=0; kk<N; kk++)
  C2[kk]=C[kk]; 

free(C);
}

#else

int main(int argc, char ** argv)
{

  size_t N = 23;
  double * X = (double *) malloc(N*3*sizeof(double));
  uint32_t * C = (uint32_t *) malloc(N*sizeof(uint32_t));
  double d2 = 1;

size_t nC = cluster3e(X, N,d2,C);
free(C);
free(X);

}

#endif
