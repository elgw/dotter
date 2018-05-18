#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <math.h>
#include <assert.h>
#include <time.h>
#include <unistd.h>

// For the hash function
int M; // Number of buckets along the first dimension
double m0, m1; // the range of the data in dimension M is [m0, m1)
int N;
double n0, n1;
int P;
double p0, p1;

void showPoint(double * A)
{
  printf("%f %f %f\n", A[0], A[1], A[2]);
}

double eudist2(double * A, double * B)
{
  // Squared euclidean distance between two 3D points
  return (A[0]-B[0])*(A[0]-B[0]) +(A[1]-B[1])*(A[1]-B[1]) + 
    (A[2]-B[2])*(A[2]-B[2]);
}

uint32_t hash_m(double * d)
{
  return floor(M*(d[0]-m0)/(m1-m0));
}

uint32_t hash_n(double * d)
{
  return floor(N*(d[1]-n0)/(n1-n0));
}

uint32_t hash_p(double * d)
{
  return floor(P*(d[2]-p0)/(p1-p0));
}


uint32_t hash(double * d)
{
  uint32_t m = hash_m(d);
  uint32_t n = hash_n(d);
  uint32_t p = hash_p(d);

#ifndef NDEBUG
  if(!(n<N))
    printf("%f %f %f : %u\n", d[0], d[1], d[2], n);
#endif
  assert(m<M);
  assert(n<N);
  assert(p<P);

  return m+ n*M+ p*M*N;
}

double maxs(double * D, size_t nD, int stride)
{
  double max = -INFINITY;
  for(size_t kk = 0; kk<nD; kk++)
    if(D[kk*stride]>max)
      max = D[kk*stride];
  return max;
}

double mins(double * D, size_t nD, int stride)
{
  double min = INFINITY;
  for(size_t kk = 0; kk<nD; kk++)
    if(D[kk*stride]<min)
      min = D[kk*stride];
  return min;
}

int nn(double * D, uint8_t * X, size_t nD, size_t stride, double d)
{
  const int verbose = 0;

  double d2 = d*d; // squared distance

  m0 = mins(D, nD, stride);
  m1 = maxs(D, nD, stride);
  m1 = m1 + 0.001*(m1-m0);
    M = floor((m1-m0)/d);
  assert((m1-m0)/M>=d); // bin size at least d
    if(M==0)
      M = 1;
  n0 = mins(D+1, nD, stride);
  n1 = maxs(D+1, nD, stride);
  n1 = n1 + 0.001*(n1-n0);
  N = floor((n1-n0)/d);
  assert((n1-n0)/N>=d); // bin size at least d
  if(N==0)
    N = 1;
  p0 = mins(D+2, nD, stride);
  p1 = maxs(D+2, nD, stride);
  p1 = p1 + 0.001*(p1-p0);
  P = floor((p1-p0)/d);
  assert((p1-p0)/P>=d); // bin size at least d
  if(P==0)
    P = 1;

  if(verbose)
  {
  printf("M: %d : [%f, %f]\n", M, m0, m1);
  printf("N: %d : [%f, %f]\n", N, n0, n1);
  printf("P: %d : [%f, %f]\n", P, p0, p1);
  }
  //sleep(2);

  size_t nH = M*N*P;
  uint32_t * H = malloc(2*nH*sizeof(uint32_t));
  if(H==NULL)
  {
    perror("Failed to allocate H");
    return -1;
  }

  uint32_t * T = malloc(nD*sizeof(uint32_t));
  if(T==NULL)
  {
    free(H);
    perror("Failed to allocate T");
    return -1;
  }

  memset(H, 0, 2*nH*sizeof(uint32_t));

  // Count the number of elements in each bucket
  for(size_t kk = 0; kk<nD; kk++)
  {
    uint32_t h = hash(D+kk*stride);
    assert(h<M*N*P);
    H[2*h]++;
  }

 // for(size_t kk = 0; kk<nH; kk++)
 //   printf("H0[%zu]=%u, %zu\n", kk, H[2*kk], H[2*kk+1]);


  // Convert to start positions
  uint32_t acc = 0;
  for(size_t kk = 0; kk<nH; kk++)
  {
    uint32_t a = H[2*kk];
    H[2*kk] = acc;
    acc += a;
  }

  if(verbose)
  printf("Insert points in T\n");

  for(size_t kk = 0 ; kk<nD; kk++)
  {
    uint32_t h = hash(D+kk*stride);
    T[H[2*h]+H[2*h+1]] = kk;
    H[2*h+1]++; // increase the next write position
  }

//  for(size_t kk = 0; kk<nH; kk++)
//    printf("H[%zu]=%u, %zu\n", kk, H[2*kk], H[2*kk+1]);


//  for(size_t kk = 0; kk<nD; kk++)
//    printf("T[%zu]=%u\n", kk, T[kk]);

  if(verbose)
  printf("Scan all the points and see if there is a neighbour\n");

  for(size_t kk =0; kk<nD; kk++)
  {
    uint32_t h = hash(D+kk*stride);
    assert(h+1<2*M*N*P);
    double * curr_point = D+kk*stride; 
    double curr_set = curr_point[stride-1];

    int hashm = hash_m(D+kk*stride); 
    int hm0 = hashm;
    int hm1 = hashm;
    if(hashm > 0)
      hm0 = hashm-1;
    if(hashm + 1 < M)
      hm1 = hashm +1;

    int hashn = hash_n(D+kk*stride); 
    int hn0 = hashn;
    int hn1 = hashn;
    if(hashn > 0)
      hn0 = hashn-1;
    if(hashn + 1 < N)
      hn1 = hashn +1;

    int hashp = hash_p(D+kk*stride); 
    int hp0 = hashp;
    int hp1 = hashp;
    if(hashp > 0)
      hp0 = hashp-1;
    if(hashp + 1 < P)
      hp1 = hashp +1;

 //   printf("Will search in %d %d %d %d %d %d\n", hm0, hm1, hn0, hn1, hp0, hp1);

    for(int hm = hm0 ; hm<= hm1; hm++)
    for(int hn = hn0 ; hn<= hn1; hn++)
    for(int hp = hp0 ; hp<= hp1; hp++)
    {
      uint32_t hnear = hm+ hn*M + hp*M*N;
    for(size_t nn = H[2*hnear]; nn<H[2*hnear]+H[2*hnear+1]; nn++)
    {
      double * cmp_point =D+T[nn]*stride;
      double cmp_set = cmp_point[stride-1];
    //  printf("%f vs %f\n", curr_set, cmp_set);
      if(curr_set != cmp_set) // Don't check within the same set
     if(curr_point != cmp_point) // Don't check against self
     { 
      double dist = eudist2(curr_point, cmp_point );
      if(dist<d2)
      {
        // Mark for deletion
        assert(kk<nD);
        assert(T[nn]<nD);
        X[kk] = 1;
        X[T[nn]] = 1;
        //printf(" dist: %f\n", sqrt(dist));
        //showPoint(curr_point);
        //showPoint(cmp_point);
      }
    }
  }
  }
  }

  free(T);
  free(H);
  return 0;
}

int main(int argc, char ** argv)
{

  int seed = time(NULL);
  printf("random seed: %d\n");
  srand(seed);
  size_t N = 100; // number of points
  size_t M = 10; // number of values per point, i.e., (x,y,z,id,color)
  double * D = malloc(N*M*sizeof(double));
  uint8_t * X = malloc(N*sizeof(uint8_t));
  memset(X, 0, N*sizeof(uint8_t));
  for(size_t kk = 0; kk<N*M; kk++)
    D[kk] = 102*(rand()/ (double) RAND_MAX);
  for(size_t kk = 0; kk<N; kk++)
    D[kk*M+9] = 1;
  
  nn(D,X,N,M, 20);

  free(X);
  free(D);

}
