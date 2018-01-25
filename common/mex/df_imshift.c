#include <string.h>
#include <stdio.h>
#include <math.h>
#include "mex.h"
#include "imshift.h"
#include "conv1.h"

// Provides a MATLAB interface from imshift.c

// Also compiles in octave, 
// mkoctfile --mex imshift.c df_imshift.c -I/usr/local/Cellar/gsl/2.3/include -L/usr/local/Cellar/gsl/2.3/lib -lgsl -lgslcblas -lm

#ifndef verbose
#define verbose 1
#endif

void mexFunction(int nlhs, mxArray *plhs[],int nrhs, const mxArray *prhs[]) 
{


  if (! (nrhs == 2 || nrhs==3)) {
    mexErrMsgTxt("There should be two or three inputs");
  }

  /* Check data types of the input arguments. */
  if (!(mxIsDouble(prhs[0]))) {
    mexErrMsgTxt("First argument must be of type double.");
  }

  if (!(mxIsDouble(prhs[1]))) {
    mexErrMsgTxt("Second argument must be of type double.");
  }

  double * V = (double *) mxGetPr(prhs[0]);
  mwSize VnDim = mxGetNumberOfDimensions(prhs[0]);
  const mwSize * Vdim = mxGetDimensions(prhs[0]);
  const mwSize Vnel = mxGetNumberOfElements(prhs[0]);

  double * shift = (double *) mxGetPr(prhs[1]);
  mwSize KnDim = mxGetNumberOfDimensions(prhs[1]);
  const mwSize * Kdim_temp = mxGetDimensions(prhs[1]);
  const mwSize Knel = mxGetNumberOfElements(prhs[1]);

  int method = 1; // linear

  if(nrhs == 3)
  {
    char * methodStr = (char *) malloc((mxGetN(prhs[2])+1)*sizeof(char));
    mxGetString(prhs[2], methodStr, mxGetN(prhs[2])+1);
    if(strcasecmp(methodStr, "Linear")==0)
    {
      method = 1;
    }
    if(strcasecmp(methodStr, "Cubic")==0)
    {
      method = 3;
    }
  }

  if(verbose)
    printf("Using interpolation of order %d\n", method);

  if(verbose) { 
    printf("V: %dx%dx%d\n", Vdim[0], Vdim[1], Vdim[2]);
  }

  plhs[0] = mxCreateNumericArray(VnDim,  Vdim, mxDOUBLE_CLASS, mxREAL);
  double * W = (double *) mxGetPr(plhs[0]);
  memcpy(W, V, Vnel*sizeof(double));

  if(VnDim == 2 && Vdim[1] == 1)
  {
    if(verbose)
      printf("1D input\n");
    if(Knel != 1)
      mexErrMsgTxt("Expecting one delta");


    double delta = shift[0];
    if(verbose)
      printf("delta: %f\n", delta);

    double * K = NULL;
    size_t nK = 0;

    if(fabs(delta)>.5)
      mexErrMsgTxt("abs(delta)>.5");

    if(verbose)
      printf("generateShift\n");
    generateShift(&K, delta, &nK, method);

    double * buff = malloc(Vdim[0]*sizeof(double));

    conv1(W, buff, Vdim[0], K, nK, 1);

    free(buff);
    free(K);

  }
   else
  {
    if(VnDim == 2)
    {
      if(verbose)
        printf("2D input\n");
    if(Knel != 2)
      mexErrMsgTxt("Expecting two deltas");


      double * Kx = NULL; double * Ky = NULL;
      size_t nKx; size_t nKy;

      if(fabs(shift[0])>.5)
      mexErrMsgTxt("abs(delta)>.5");

      if(fabs(shift[1])>.5)
      mexErrMsgTxt("abs(delta)>.5");



      generateShift(&Kx, shift[0], &nKx, method);
      generateShift(&Ky, shift[1], &nKy, method);

      if(verbose)
        for(int kk = 0; kk<nKx; kk++)
          printf("Kx[%d] : %f\n", kk, Kx[kk]);

      if(verbose)
        for(int kk = 0; kk<nKy; kk++)
          printf("Ky[%d] : %f\n", kk, Ky[kk]);


      size_t M = Vdim[0];
      size_t N = Vdim[1];

      conv1_3(W,  M, N, 1, Kx, nKx, Ky, nKy, NULL, 0);

      free(Ky);
      free(Kx);
    }

    if(VnDim == 3)
    {
      if(verbose)
        printf("3D input\n");

    if(Knel != 3)
      mexErrMsgTxt("Expecting three deltas");

      double * Kx = NULL; 
      size_t nKx; 
      double * Ky = NULL;
      size_t nKy;
      double * Kz = NULL;
      size_t nKz;

      if(fabs(shift[0])>.5)
      mexErrMsgTxt("abs(delta)>.5");
      if(fabs(shift[1])>.5)
      mexErrMsgTxt("abs(delta)>.5");
      if(fabs(shift[2])>.5)
      mexErrMsgTxt("abs(delta)>.5");

      generateShift(&Kx, shift[0], &nKx, method);
      generateShift(&Ky, shift[1], &nKy, method);
      generateShift(&Kz, shift[2], &nKz, method);

      size_t M = Vdim[0];
      size_t N = Vdim[1];
      size_t P = Vdim[2];

      conv1_3(W, M, N, P, Kx, nKx, Ky, nKy, Kz, nKz);

      free(Kz);
      free(Ky);
      free(Kx);
    }

  }
}
