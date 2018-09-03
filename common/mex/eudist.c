// https://github.com/elgw/edt
// 2018-09-03

#ifndef _POSIX_C_SOURCE
#define _POSIX_C_SOURCE 199309L
#endif

#include <stdlib.h>
#include <string.h>
#include <stdio.h>
#include <math.h>
#include <assert.h>
#include <time.h>
#include <pthread.h>
#include <unistd.h>
#include <stdint.h>
#include "eudist.h"

#ifndef verbose
#define verbose 0
#endif

/* The structure for the "private" given to each thread */
typedef struct{
  double * B; // Binary mask
  double * D; // Output
  double * D0; // Line buffer of size max(M, N, P)

  int * S; // Line buffers for pass 3 and 4
  int * T;

  int thrId;
  int nThreads;

  size_t M; // Image dimensions
  size_t N;
  size_t P;

  double dx; // Voxel size
  double dy;
  double dz;
} thrJob;

size_t randi(size_t max)
  /* return a value in [0,max] */
{ 
  size_t val = (size_t) ( (double) rand()/ (double) RAND_MAX * max );
  return val;
}

double randf(double min, double max)
  /* Returns a random value in [min,max] */
{
  return min + (double) rand() / (double) RAND_MAX * (max-min);
}


void edt_brute_force(double * B, double * D, // binary mask and distance
    size_t M, size_t N, size_t P, // domain size
    double dx, double dy, double dz) // voxel size
  /* Brute force O(n^2) implementation of the euclidean distance
   * transform
   *
   * This is used for testing correctness
   *
   * */
{
  for(size_t mm = 0; mm<M; mm++)
    for(size_t nn = 0; nn<N; nn++)
      for(size_t pp = 0; pp<P; pp++)
      {
        double d_min = INFINITY; // Fallback, everything will be set to this if B is all zeros
        size_t elm  =mm+ M*nn +M*N*pp; // element to consider
        if(B[elm] == 1)
        {
          D[elm] = 0;
        }
        else
        {
          for(size_t kk = 0; kk<M; kk++)
            for(size_t ll = 0; ll<N; ll++)
              for(size_t qq = 0; qq<P; qq++)
              {
                if(B[kk+ M*ll+M*N*qq] == 1)
                {
                  double d = pow(dx*((int64_t) kk-(int64_t) mm),2)+
                    pow(dy*((int64_t) ll-(int64_t) nn),2)+
                    pow(dz*((int64_t) qq-(int64_t) pp),2);
                  if( d < d_min)
                    if( ! ((kk == mm ) && (ll == nn) && (qq == pp)))
                    {
                      d_min = d;
                    }
                }
              }
          D[elm] = sqrt(d_min);
        }
      }
  return;
}

size_t max_size_t(size_t a, size_t b)
{
  if(a>b)
    return a;
  return b;
}

void matrix_show(double * M, size_t m, size_t n, size_t p)
  /* Utility to print out small matrices */
{
  if(m>20 || n>20 || p>20)
  {
    printf("%zu x %zu x %zu matrix (not shown)\n", m, n, p);
    return;
  }

  for(size_t zz = 0; zz<p; zz++)    
  {
    printf("z=%zu\n", zz);
    for(size_t kk = 0; kk<m ; kk++)
    {
      for(size_t ll = 0; ll<n ; ll++)
      {
        size_t pos = ll*m+kk + zz*m*n;
        printf("%3.2f ", M[pos]);
      }
      printf("\n");
    }
  }
  return;
}

void pass12(double * restrict B, double * restrict D, const size_t L, const double dx)
  /* Pass 1 and 2 for a line (stride 1, since only run along the first dimension) */
{

  // Pass 1
  double d = INFINITY;
  for( size_t ll = 0; ll<L; ll++) // For each row
  {
    d = d + dx;
    if(B[ll] == 1)
      d = 0;
    D[ll] = d;
  }

  // Pass 2
  d = INFINITY;
  for( size_t ll = L ; ll-- > 0; ) // For each row
  {
    d = d + dx;
    if(B[ll] == 1)
      d = 0;
    if(d<D[ll])
      D[ll] = d;
  }
  return;
}


void * pass12_t(void * data)
{
  thrJob * job = (thrJob *) data;

  int last = job->N*job->P; 
  int from = job->thrId * last/job->nThreads;
  int to = (job->thrId + 1)*last/job->nThreads-1;

//  printf("Thread: %d. From: %d To: %d, last: %d\n", job->thrId, from, to, last);
//  fflush(stdout);

  for(int kk = from; kk<=to; kk++) // For each column
  {
    size_t offset = kk*job->M;
    pass12(job->B+offset, job->D+offset, job->M, job->dx);
  }
  return NULL;
}

void pass34(double * restrict D, // Read distances
    double * restrict D0, // Write distances
    int * restrict S, int * restrict T, // Temporary pre-allocated storage
    const int L, // Number of elements in this dimension
    const int stride, 
    const double d) // voxel size in this dimension
{

  // Make a copy of D into D0
  for(int kk = 0; kk<L; kk++)
    D0[kk] = D[kk*stride]; 

  // 3: Forward
  int q = 0;
  double w = 0;
  S[0] = 0;
  T[0] = 0;
  const double d2 = d*d;

  for(int u = 1; u<L; u++) // For each column
  {
    // f(t[q],s[q]) > f(t[q], u)
    // f(x,i) = (x-i)^2 + g(i)^2
    while(q >= 0 && ( (pow(d*(T[q]-S[q]),2) + pow(D0[S[q]],2)) >=
          (pow(d*(T[q]-u), 2) +  pow(D0[u],2)) ) )
      q--;

    if(q<0)
    {
      q = 0;
      S[0] = u;
      T[0] = 0;
      if(verbose > 2)
        printf("reset, S[0] = %d\n", S[0]);
    }
    else
    {
      // w = 1 + Sep(s[q],u)
      // Sep(i,u) = (u^2-i^2 +g(u)^2-g(i)^2) div (2(u-i))
      // where division is rounded off towards zero
      w = 1 + trunc( ( pow(d*u,2)  - pow(d*(double) S[q],2) 
            + pow(D0[u],2) - pow(D0[S[q]],2))/(d2*2*(u-(double) S[q])));
      // because of overflow, w is double. T does not have to be
      // double
      // printf("q: %d, u: %d, S[q]: %d, D[stride*u]: %f D[stride*S[q]] %f, w: %f\n", q, u, S[q], D[stride*u], D[stride*S[q]], w);
      if(verbose > 1)
        printf("u/kk: %d, S[q] = %d, q: %d w: %f\n", u, S[q], q, w);

      if(w<L)
      {
        q++;
        S[q] = (int) u; // The point where the segment is a minimizer
        T[q] = (int) w; // The first pixel of the segment
      }
    }
    if(0){
      printf(" #, minPos, firstPixel, minValue\n"); 
      for(int tt = 0; tt<=q; tt++)
      {
        printf(" %d, %6d, %d, %6.2f\n", tt, S[tt], T[tt], D[stride*S[tt]]);
      }
    }
  }

  // 4: Backward  
  for(int u = L-1; u > -1 ; u--)
  {
    //dt[u,y]:=f(u,s[q])
    if(verbose>3)
      printf("u: %d, q: %d S[%d] = %d\n", u, q, q, S[q]);
    D[u*stride] = sqrt(pow(d*(u-S[q]),2)+pow(D0[S[q]], 2));
    if(u == (int) T[q])
      q--;
  }
}

void * pass34y_t(void * data)
{  
  thrJob * job = (thrJob *) data;

  // Second dimension
  int length = job->N;
  int stride = job->M;
  double dy = job->dy;
  
  for(size_t kk = 0; kk< job->P; kk++) // slice
    {
  for(size_t ll = job->thrId; ll<job->M; ll=ll+job->nThreads) // row
    {
      size_t offset = kk*job->M*job->N + ll;
      pass34(job->D+offset, job->D0, job->S, job->T, length, stride, dy);
    }
  }
  return NULL;
}

void * pass34z_t(void * data)
{  
  thrJob * job = (thrJob *) data;

  // Second dimension
  int length = job->P;
  int stride = job->M*job->N;
  double dz = job->dz;

  for(size_t kk = job->thrId; kk<job->M; kk=kk+job->nThreads)
  {
    for(size_t ll = 0; ll<job->N; ll++)
    {
      size_t offset = kk + ll*job->M;
      pass34(job->D+offset, job->D0, job->S, job->T, length, stride, dz);
    }
  }
  return NULL;
}


void edt(double * restrict B, double * restrict D, const size_t M, const size_t N, const size_t P, 
    const double dx, const double dy, const double dz, int nThreads)
{
  /* Euclidean distance transform 
     B specifies a binary mask, 1 == object, 0 = background
     Distances are stored in D
     Matrices are of size M x N x P
     */

  size_t nL = max_size_t(M,max_size_t(N, P)); // largest possible line

  /* Set up threads and their buffers
   * -------------------------------
   */

#ifdef timings
  struct timespec tic, toc;
  double tot;
#endif

  pthread_t threads[nThreads];
  thrJob jobs[nThreads];

  for(int kk = 0; kk<nThreads; kk++)
  {
    jobs[kk].B = B;
    jobs[kk].D = D;
    jobs[kk].S = malloc(nL*sizeof(int));
    jobs[kk].T = malloc(nL*sizeof(int));
    jobs[kk].D0 = malloc(nL*sizeof(double));
    jobs[kk].thrId = kk;
    jobs[kk].nThreads = nThreads;
    jobs[kk].M = M;
    jobs[kk].N = N;
    jobs[kk].P = P;
    jobs[kk].dx = dx;
    jobs[kk].dy = dy;
    jobs[kk].dz = dz;
  }


  // 
  // First dimension, pass 1 and 2
  //
#ifdef timings
    clock_gettime(CLOCK_MONOTONIC, &tic);
#endif

  for(int kk = 0; kk<nThreads; kk++) // Run
    pthread_create(&threads[kk], NULL, pass12_t, &jobs[kk]);

  for(int kk = 0; kk<nThreads; kk++) // Synchronize
    pthread_join(threads[kk], NULL);
 
#ifdef timings 
 clock_gettime(CLOCK_MONOTONIC, &toc);
   tot = (toc.tv_sec - tic.tv_sec);
   tot += (toc.tv_nsec - tic.tv_nsec) / 1000000000.0;
   printf("x Took %f s\n", tot);
#endif

  if(verbose>1)
  {
    printf("D:\n");
    matrix_show(D, M, N, P);
  }

  // 
  // Pass 2 and 3, for dimension 2, 3, ...
  //

  // Second dimension
#ifdef timings
  clock_gettime(CLOCK_MONOTONIC, &tic);
#endif

  for(int kk = 0; kk<nThreads; kk++) // Run
    pthread_create(&threads[kk], NULL, pass34y_t, &jobs[kk]);

  for(int kk = 0; kk<nThreads; kk++) // Synchronize
    pthread_join(threads[kk], NULL);
#ifdef timings
   clock_gettime(CLOCK_MONOTONIC, &toc);
   tot = (toc.tv_sec - tic.tv_sec);
   tot += (toc.tv_nsec - tic.tv_nsec) / 1000000000.0;
   printf("y Took %f s\n", tot);
#endif
  if(verbose>1)
  {
    printf("D2:\n");
    matrix_show(D, M, N, P);
  }

  // Third dimension
#ifdef timings
  clock_gettime(CLOCK_MONOTONIC, &tic);
#endif
  if(P>1)
  {
    for(int kk = 0; kk<nThreads; kk++) // Run
      pthread_create(&threads[kk], NULL, pass34z_t, &jobs[kk]);

    for(int kk = 0; kk<nThreads; kk++) // Synchronize
      pthread_join(threads[kk], NULL);
  }
#ifdef timings
   clock_gettime(CLOCK_MONOTONIC, &toc);
   tot = (toc.tv_sec - tic.tv_sec);
   tot += (toc.tv_nsec - tic.tv_nsec) / 1000000000.0;
   printf("z Took %f s\n", tot);
#endif

  if(verbose>1)
  {
    printf("D3:\n");
    matrix_show(D, M, N, P);
  }

  for(int kk = 0; kk<nThreads; kk++)
  {
    free(jobs[kk].S);
    free(jobs[kk].T);
    free(jobs[kk].D0);
  }

  return;
}


int test_size(size_t M, size_t N, size_t P, double dx, double dy, double dz, int nThreads)
{
  printf("Problem size: %zu x %zu x %zu\n", M, N, P);
  printf("Voxel size: %.2f x %.2f x %.2f\n", dx, dy, dz);

  /* Allocate memory */
  double * B = calloc(M*N*P, sizeof(double));
  double * D = calloc(M*N*P, sizeof(double));
  double * D_bf = calloc(M*N*P, sizeof(double));

  // For timing
  struct timespec start0, end0, start1, end1;

  /* Initialize binary mask */
  size_t nB = randi(M*N*P);
  printf("Setting %zu random elements to 1 in B\n", nB);
  for(size_t bb = 0; bb<nB; bb++)
    B[randi(M*N*P-1)] = 1;

  //B[5*2+2] = 1;
  //B[3] = 1;
  if(verbose>0)
  {
    printf("Binary mask:\n");
    matrix_show(B, M, N, P);
  }

  //  printf("Edt^2:\n");
  // matrix_show(D, M, N, P);
  // printf("Edt^2 -- brute force reference:\n");
  clock_gettime(CLOCK_MONOTONIC, &start1);
  int bf_run = 0;
  if(M*N*P<1000000)
  {
    bf_run = 1;
    edt_brute_force(B, D_bf, 
        M, N, P, 
        dx, dy, dz);
  }

  clock_gettime(CLOCK_MONOTONIC, &end1);

  clock_gettime(CLOCK_MONOTONIC, &start0);
  edt(B, D, 
      M, N, P,
      dx, dy, dz, nThreads);

  clock_gettime(CLOCK_MONOTONIC, &end0);

  double elapsed0, elapsed1;
  elapsed0 = (end0.tv_sec - start0.tv_sec);
  elapsed0 += (end0.tv_nsec - start0.tv_nsec) / 1000000000.0;
  elapsed1 = (end1.tv_sec - start1.tv_sec);
  elapsed1 += (end1.tv_nsec - start1.tv_nsec) / 1000000000.0;

  if(verbose>0)
  {
    printf("D_bf:\n");
    matrix_show(D_bf, M, N, P);
  }

  int failed = 0;
  double max_error = 0;

  for(size_t kk = 0; kk<M*N*P; kk++)
  {
    double err = fabs(D[kk] - D_bf[kk]); 
    if(err > max_error)
      max_error = err;

    if(err > 10e-5)
      failed = 1;
  }

  if(bf_run)
  {
    if(failed)
    {
      printf("Wrong result! ");
      printf(" -- Largest difference: %f\n", max_error);
    } else
    {
      printf("Correct! ");
      printf("Timing: Edt: %f s, bf: %f s\n", elapsed0, elapsed1);
    }
  }
  else {
    printf("Not verified against brute force\n");
    printf("Timing: %f s\n", elapsed0);
  }


  free(D_bf);
  free(D);
  free(B);

  printf("\n"); 
  fflush(stdout);

  return failed;
}

void usage()
{
  printf("Usage:\n");
  printf("-n nThreads : Specify the number of threads to use\n");
  printf("-M #        : Size along first dimension\n");
  printf("-N #        : Size along second dimension\n");
  printf("-P #        : Size along third dimension\n");
  printf("-x #        : Pixel size in first dimension\n");
  printf("-y #        : Pixel size in second dimension\n");
  printf("-z #        : Pixel size in third dimension\n");
  printf("-r          : Run tests with random image and pixel size\n");
  printf("-R          : Use a random seed\n");
  printf("-h          : Show this help message\n");
  return;
}

int main(int argc, char ** argv)
{

  // Defaults:
  int nThreads = 4;
  size_t M = 1024; size_t N = 1024; size_t P = 60;
  double dx = 1; double dy = 1; double dz = 1;
int test_one = 1;

if(argc == 1)
{
  usage();
  return 0;
}
char ch;
while((ch = getopt(argc, argv, "Rn:M:N:P:rx:y:z:h\n")) != -1)
{
  switch(ch) {
    case 'n':
      nThreads = atoi(optarg);
      break;
    case 'M':
      M = atoi(optarg);
      break;
    case 'N':
      N = atoi(optarg);
        break;
    case 'P':
      P = atoi(optarg);
      break;
    case 'r':
      test_one = 0;
      break;
    case 'x':
      dx = atof(optarg);
      break;
    case 'y':
      dy = atof(optarg);
      break;
     case 'z':
      dz = atof(optarg);
      break;
     case 'h':
      usage();
      break;
     case 'R':
      srand((unsigned int) time(NULL));
      break;

   }
}

  printf("Using %d threads\n", nThreads);

  if(test_one == 1)
  {
test_size(M,N,P, dx, dy, dz, nThreads);
return 0;
  }

  printf("Testing random sizes and voxel sizes\n");
  printf("Abort with Ctrl+C\n");

  size_t nTest = 0;
  while(1)
  {
    nTest++;
    printf(" --> Test %zu\n", nTest);
    M = randi(15)+5;
    N = randi(15)+5;
    P = randi(45)+5;
    dx = randf(0.1, 20); // wrong result when dx != 1
    dy = randf(0.1, 20);
    dz = randf(0.1, 20);

    if(test_size(M,N,P, dx, dy, dz, nThreads) > 0)
    {
      printf(" --! Test %zu failed\n", nTest);
      printf("Wrong result for M=%zu, N=%zu, P=%zu, dx=%f, dy=%f, dz=%f\n",
          M, N, P, dx, dy, dz);
      assert(0);
    }
  }

  return 0;
}
