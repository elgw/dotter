/* Linear convolution of 2D and 3D images of type double
 *
 * Compilation example:
 *  gcc conv1.c -v -Dverbose -lpthread -Dstandalone -fprefetch-loop-arrays -DnThreads=4
 *
 *  On Intel 6700k, no gain with more than 4 threads
 *
 */

#include <assert.h>
#include <inttypes.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include <pthread.h>

#include <gsl/gsl_math.h>

#include "conv1.h"

#ifndef nThreads
#define nThreads 8
#endif

typedef struct{
  double * V; // volume
  size_t M;
  size_t N;
  size_t P;

  double * K; // kernel
  size_t nK; // elements in kernel
  double * B; // buffer, as long as V in direction

  size_t idTh;
  size_t nTh;

  int direction;

} thrJob;

int dbg;

void * conv1th(void * in)
  /* 
   * This is where new threads start 
   *
   * */
{
  thrJob * j = (thrJob*) in;

  const size_t M = j->M;
  const size_t N = j->N;
  const size_t P = j->P;
  const size_t MN = j->M*j->N;
  const size_t MP = j->M*j->P;
  const size_t MNP = j->M*j->N*j->P;

  const size_t nTh = j->nTh;
  const size_t idTh  = j->idTh;

  if(j->direction == 1)
  {
    size_t stride = 1;
    size_t length = M;
    for(size_t rr = idTh; rr<N*P; rr=rr+nTh)
    {
      size_t start = rr*M;
      //printf("start: %lu \n", start);
      //printf("nK: %lu\n", j->nK);

      conv1(j->V+start, j->B, length, j->K, j->nK, stride); 
    }
  }

//  if(j->direction == 2)
//  {
//    size_t stride = M;
//    size_t length = N;
//    size_t start = idTh;
//    for(size_t rr = idTh; rr<MP; rr=rr+nTh)
//    {
//      if(dbg>1)
//        printf("MNP: %lu MN: %lu start: %lu", MNP, MN, start);
//      if(start>=MNP)
//      { start = start-MNP+1; }
//      if(dbg>1)
//        printf(" -> %lu\n", start);
//      conv1(j->V+start, j->B, length, j->K, j->nK, stride); 
//    start = start + nTh*MN;
//    }
//  }


  if(j->direction == 2)
  {
    size_t stride = M;
    size_t length = N;
    size_t start = idTh;
    size_t row = idTh;
    assert(idTh<M);

    for(size_t rr = idTh; rr<MP; rr=rr+nTh)
    {
      if(dbg>1)
        printf("MNP: %lu row: %lu start: %lu", MNP, row, start);
      if(row >= M)
      { row = 0;
        start = start+MN-M;
      }
      if(dbg>1)
        printf(" -> %lu %lu\n", row, start);
      conv1(j->V+start, j->B, length, j->K, j->nK, stride); 
      start=start+nTh;
      row=row+nTh;
    }
  }

  if(j->direction == 3)
  {
    size_t stride = MN;
    size_t length = P;
    for(size_t rr = idTh; rr<MN; rr=rr+nTh)
    {
      size_t start = rr;
      conv1(j->V+start, j->B, length, j->K, j->nK, stride); 
    }
  }

  return NULL;
}

int conv1_3(double * V, const size_t M, const size_t N, const size_t P ,
    double * Kx, const size_t nKx,
    double * Ky, const size_t nKy,
    double * Kz, const size_t nKz)
  /**
   *  Convolve V by Kx in first direction and Ky in second direction
   *  and Kz in the third direction
   */
{

  // set buffers for all threads
  pthread_t threads[nThreads];
  thrJob jobs[nThreads];
  for(int kk = 0; kk<nThreads; kk++) {
    jobs[kk].B = malloc(GSL_MAX(GSL_MAX(M,N),P)*sizeof(double));
    jobs[kk].nTh = nThreads;
    jobs[kk].V = V;
    jobs[kk].M = M;
    jobs[kk].N = N;
    jobs[kk].P = P;
  }

  // Convolve in the x-direction
  if(nKx>1 && M>1){
    if(dbg>0)
      printf("x:\n");

    for(int kk=0; kk<nThreads; kk++)
    {
      jobs[kk].K = Kx;
      jobs[kk].nK = nKx;
      jobs[kk].idTh= kk;
      jobs[kk].direction = 1;
      pthread_create(&threads[kk], NULL, conv1th, &jobs[kk]);
    }

    for(int kk = 0; kk<nThreads; kk++)
      pthread_join(threads[kk], NULL);
  } 

  //printf("y:\n");
  // Convolve in the y-direction
  if(nKy>1 && N>1){
    if(dbg>0)
      printf("y:\n");

    for(int kk=0; kk<nThreads; kk++)
    {
      jobs[kk].K = Ky;
      jobs[kk].nK = nKy;
      jobs[kk].idTh= kk;
      jobs[kk].direction = 2;
      pthread_create(&threads[kk], NULL, conv1th, &jobs[kk]);
    }

    for(int kk = 0; kk<nThreads; kk++)
      pthread_join(threads[kk], NULL);
  } 

  //printf("z:\n");

  // Convolve in the z-direction
  if(nKz>1 && P>1){
    if(dbg>0)
      printf("x:\n");

    for(int kk=0; kk<nThreads; kk++)
    {
      jobs[kk].K = Kz;
      jobs[kk].nK = nKz;
      jobs[kk].idTh= kk;
      jobs[kk].direction = 3;
      pthread_create(&threads[kk], NULL, conv1th, &jobs[kk]);
    }

    for(int kk = 0; kk<nThreads; kk++)
      pthread_join(threads[kk], NULL);

  } 

  // Free bufferes
  for(int kk =0; kk<nThreads; kk++)
    free(jobs[kk].B);

  return 0;
}

int conv1(double * restrict V, double * restrict W, 
    const size_t nV, 
    const double * restrict K, const size_t nKu, const size_t stride)
{
  /** 
   * Convolve the volumetric image V by the kernel K
   *
   * INPUTS:
   * V: Volumetric image with nV elements to be visited
   *    separated by stride
   * K: kernel with nK elements
   * W (optional): temporary buffer of length nV or more
   *
   * NOTES?
   * The gives same result as 0-padding would do.
   *  is 32 bit indexing faster?
   *  border cases not tested, i.e., nKu = 0, 1
   */

  if(verbose>1)
    printf("stride: %lu\n", stride);

  assert(nKu%2==1);
  assert(nV>nKu);

  const size_t k2 = (nKu-1)/2;
  const size_t N = nV;

  // First part
  for(size_t vv = 0;vv<k2; vv++)
  {
    double acc = 0;
    for(size_t kk = 0; kk<nKu; kk++)      
    {
      if(vv+kk+1 > k2)
        acc = acc + K[kk]*V[(vv-k2+kk)*stride];
    }
    W[vv] = acc;
  }

  // Central part where K fits completely
  for(size_t vv = k2; vv+k2<N; vv++) 
  {
    double acc = 0;
    for(size_t kk = 0; kk<nKu; kk++)
    {
      // printf("kk:%lu pos: %lu ",  kk, (vv-k2+kk)*stride);
      acc = acc + K[kk]*V[(vv-k2+kk)*stride];
    }
    W[vv] = acc;
  }

  // Last part
  for(size_t vv = N-k2;vv<N; vv++)
  {
    double acc = 0;
    for(size_t kk = 0; kk<nKu; kk++)      
    {
      if(vv-k2+kk<N)
        acc = acc + K[kk]*V[(vv-k2+kk)*stride];
    }
    W[vv] = acc;
  }

  // copy back to V
  for(size_t kk = 0; kk<nV; kk++)
    V[kk*stride] = W[kk];

  return 1;
}

void timing2d(void)
{

  size_t M = 448;
  size_t N = 448;

  double * V = malloc(M*N*sizeof(double));
  assert(M>=N);
  double * B = malloc(M*sizeof(double));

  size_t nK = 21;
  double * K = malloc(nK*sizeof(double));


  conv1_3(V, M, N, 1, K, nK, K, nK, K, nK); 

  free(K);
  free(B);
  free(V);
}

void timing3d(void)
{
  size_t M = 1024;
  size_t N = 1024;
  size_t P = 61;

  double * V = calloc(M*N*P, sizeof(double));
  assert(V!= NULL);
  V[(M*N*P-1)/2]=1;

  size_t nK = 11;
  double * Kx = calloc(nK, sizeof(double));
  Kx[(nK-1)/2]=2;
  double * Ky = calloc(nK, sizeof(double));
  Ky[(nK-1)/2]=3;

  double * Kz = calloc(nK, sizeof(double));
  Kz[(nK-1)/2]=5;


  double tx0 = clock();
  conv1_3(V, M, N, P, Kx, nK, Ky, 0, Kz, 0); 
  double tx = (clock()-tx0)/CLOCKS_PER_SEC;

  double ty0 = clock();
  conv1_3(V, M, N, P, Kx, 0, Ky, nK, Kz, 0); 
  double ty = (clock()-ty0)/CLOCKS_PER_SEC;

  double tz0 = clock();
  conv1_3(V, M, N, P, Kx, 0, Ky, 0, Kz, nK); 
  double tz = (clock()-tz0)/CLOCKS_PER_SEC;

  //printf("%f \n", V[(M*N*P-1)/2]);
  printf("--> all kernels used\n");
  printf("%f\n", V[(M*N*P-1)/2]);
  assert(V[(M*N*P-1)/2]==30);

  double sum = 0;
  for(size_t kk=0; kk<M*N*P; kk++)
    sum += V[kk];

  printf("--> correct sum\n");
  assert(sum == 30);

  free(Kx);
  free(Ky);
  free(Kz);
  free(V);

  printf("Used %d threads\n", nThreads);
  printf("Took %f s for a %lux%lux%lu image with a %lux1 kernel\n", tx+ty+tz, M,N,P,nK);
  printf("x: %f s, y: %f s, z: %f s\n", tx, ty, tz);

}

#ifdef standalone
int main(int argc, char ** argv)
{

  printf("%s: %d unused arguments\n", argv[0], argc-1);

  dbg = 0;

  if(argc>1) {
    dbg = atoi(argv[1]);
    printf("dbg: %d\n", dbg);
  }

  //printf("timing2d\n");
  //timing2d();
  printf("timing3d\n");
  timing3d();

}
#endif
