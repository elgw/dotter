#include <mex.h>
#include "ccum.c"

#define debug

// Matlab interface to ccum.c
//
// Compilation:
// mex CFLAGS='$CFLAGS -std=c99' ccum_mex.c

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray
*prhs[])
{

if (nrhs != 4)
  mexErrMsgTxt("Requires three inputs!");

double * A = mxGetPr(prhs[0]); // First channel
double * B = mxGetPr(prhs[1]); // Second channel
double * S = mxGetPr(prhs[2]); // Size of domain
double * lMAX = mxGetPr(prhs[3]); // the setting lMax from the paper, padding, largest distance

const mwSize * sizeA = mxGetDimensions(prhs[0]);
const mwSize * sizeB = mxGetDimensions(prhs[1]);

if(sizeA[0] != 3)
  mexErrMsgTxt("Wrong size of A");

if(sizeB[0] != 3)
  mexErrMsgTxt("Wrong size of B");

#ifdef debug
printf("calling ccum\n");
printf("A [%d x %d], lmax: %f\n", sizeA[0], sizeA[1], lMAX[0]);
printf("Domain: %f x %f\n", S[0], S[1]);
#endif

//double alpha = piccs(A, (uint64_t) sizeA[1], B, (uint64_t) sizeB[1], S[0], S[1], lMAX[0]);

#ifdef debug
printf("piccs done\n");
#endif

uint64_t nC = 1024; 
printf("nC: %lu\n", nC);

plhs[0] = mxCreateDoubleMatrix(nC, 1, mxREAL);
double * C = mxGetPr(plhs[0]);

ccum(C, nC, A, sizeA[1], B, sizeB[1], S[0], S[1], lMAX[0]);

}
