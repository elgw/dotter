#include <assert.h>
#include <inttypes.h>
#include <math.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#include <gsl/gsl_math.h>

#include "imshift.h"
#include "conv1.h"

void showMatrix(double * I, size_t M, size_t N)
{
  for(size_t kk = 0; kk<N; kk++) {
    for(size_t ll = 0; ll<M; ll++)
    {
      printf("%5.2f ", I[ll*M+kk]);
    }
    printf("\n");
  }
}

int imshift3(double * V, size_t M, size_t N, size_t P, 
    double dx, double dy, double dz, int method)
{

  int status = 0;

  double * Kx = NULL; size_t nKx;
  double * Ky = NULL; size_t nKy;
  double * Kz = NULL; size_t nKz;

  status = generateShift(&Kx, dx, &nKx, method);
  if(status != 0)
    return -1;
      
  status = generateShift(&Ky, dy, &nKy, method);
  if(status != 0) {
    free(Kx);
    return -2;
  }

  status = generateShift(&Kz, dz, &nKz, method);
  if(status != 0) {
    free(Kx);
    free(Ky);
    return -3;
  }

  status = conv1_3(V, M, N, P, 
      Kx, nKx,
      Ky, nKy,
      Kz, nKz);

      free(Kz);
      free(Ky);
      free(Kx);

      return status;
}

int generateShift(double ** K, double delta, size_t * size, int order)
  /** Allocate space for a 1D shifting kernel, K, 
   * shifted by delta in [-1,1]
   * returns the size of the kernel in size
   * order sets the polynomial order, 1 = linear, 2 = quadratic
   *
   * Errors:
   *  -1, K != NULL
   *  -2, no valid interpolation method selected
   *  -3, unable to allocate memory for the kernel
   *
   * */
{

  if(K[0]!=NULL)
    return -1;

  if(order == 1)
  {
    size_t N = 3;
    size[0] = N;
    K[0] = malloc(N*sizeof(double));
    if(K[0] == NULL)
      return(-3);

    for(size_t kk = 0; kk<N; kk++)
      K[0][kk] = GSL_MAX(0, 1-fabs(kk-(1-delta)));
    return 0;
  }

  if(order == 3)
  {
    size_t N = 5;
    size[0] = N;
    K[0] = malloc(N*sizeof(double));
    if(K[0] == NULL)
      return -3;

    // set up and solve polynomial equation here
    double a = -.5;

    for(size_t kk = 0; kk < N; kk++)
    {
      double x = kk-(2-delta);
      double ax = fabs(x);
      if(ax<=1)
        K[0][kk] = (a+2)*ax*ax*ax - (a+3)*ax*ax + 1;
      if(ax>1)
        K[0][kk] = a*ax*ax*ax -5*a*ax*ax  +8*a*ax -4*a;
      if(ax>2)
        K[0][kk] = 0;
    }
    return 0;
  }

  return -2;
}

int main(int argc, char ** argv)
{

  printf("Running %s\n", argv[0]);

  if(argc>1)
    printf("Warning: unused command line arguments\n");

  {
    printf("--> Testing kernels\n");
    double * K;
    double sum;

    for(double delta = -.5; delta < .6; delta+=.1) {
    for(int method = 1; method < 4; method = method +2)
    {
      K = NULL;
      size_t nK = 0;
      assert(generateShift(&K, delta, &nK, 3)==0);

      sum = 0;
      for(int kk = 0; kk<(int) nK; kk++)
        sum += K[kk];

      printf("delta: %f order: %d sum: %f\n", delta, method, sum);

     free(K);
    }
    }
  }


  {
    printf("--> Testing 1D\n");
    double delta = .3;
    size_t N = 10;
    double * V = malloc(N*sizeof(double));

    for(size_t kk=0; kk<N; kk++)
      V[kk] = kk%2;

    double * K = NULL;
    size_t nK = 0;
    assert(generateShift(&K, delta, &nK, 3)==0);

    printf("Kernel:\n");
    for(size_t kk = 0; kk<nK; kk++)
      printf("%.1f ", K[kk]);
    printf("\n");
    printf("Input:\n");
    for(size_t kk = 0; kk<N; kk++)
      printf("%.1f ", V[kk]);
    printf("\n");

    double * buff = calloc(N,sizeof(double));

    conv1(V, buff, N, K, nK, 1);
    printf("Output\n");
    for(size_t kk = 0; kk<N; kk++)
      printf("%.1f ", V[kk]);
    printf("\n");

    free(buff);
    free(K);
    free(V);
  }

  {
    printf("Testing 2D\n");
    size_t M = 11;
    size_t N = 11;

    double * Kx = NULL;
    double * Ky = NULL;
    size_t nKx;
    size_t nKy;

    double deltax = .1;
    double deltay = .6;


    int method = 1;
    assert(generateShift(&Kx, deltax, &nKx, method)==0);
    assert(generateShift(&Ky, deltay, &nKy, method)==0);

    printf("Kernels:\n");
double sum = 0;
    printf(" deltax: %f\n", deltax);
    for(size_t kk = 0; kk<nKx; kk++) {
      printf("%5.1f ", Kx[kk]);
      sum += Kx[kk];
    }
    printf("s: %.2f\n", sum);
    sum = 0;
    printf(" deltay: %f\n", deltay);
    for(size_t kk = 0; kk<nKy; kk++) {
      printf("%5.1f ", Ky[kk]);
      sum += Ky[kk];
    }
    printf("s: %.2f\n", sum);

    double * V = calloc(M*N, sizeof(double));
    V[(M*N-1)/2] = 1;

    printf("V:\n");
    showMatrix(V, M, N);
    double * C1 = malloc(M*N*sizeof(double));
    double * C2 = malloc(M*N*sizeof(double));
    memcpy(C1,V, M*N*sizeof(double));
    memcpy(C2,V, M*N*sizeof(double));

    conv1_3(C1,  M, N, 1, Kx, nKx, Ky, nKy, NULL, 0);
    conv1_3(C2,  M, N, 1, Ky, nKy, Kx, nKx, NULL, 0);

    printf("C1\n");
    showMatrix(C1, M, N);

    printf("C2\n");
    showMatrix(C2, M, N);

    printf("Testing symmetry, C1=C2' ... ");
    for(size_t kk = 0; kk<M; kk++)
      for(size_t ll = 0; ll<N; ll++)
        assert(C1[kk+M*ll] == C2[ll+M*kk]);
    printf("ok!\n");

    free(V);
    free(Ky);
    free(Kx);
    free(C1);
    free(C2);

  }

  {
    printf("Testing 3D\n");
    double delta = .3;
    size_t M = 11;
    size_t N = 11;
    size_t P = 11;
    double * V3 = calloc(M*N*P,sizeof(double));
    V3[(M*N*P-1)/2] = 1;
    double * K = NULL;
    size_t nK = 0;
    assert(generateShift(&K, delta, &nK, 1)==0);

    clock_t t1 = clock();
    conv1_3(V3, M, N,P, K,nK,K,nK,K,nK);
    clock_t t2 = clock();

    printf("V3(:,:,6):\n");
    showMatrix(V3 + M*N*6, M, N);

    printf("Time: %f ms\n", (double) 1000*(t2-t1)/CLOCKS_PER_SEC);

    free(V3);
    free(K);
  }

  return 0;
}
