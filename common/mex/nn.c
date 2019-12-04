#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdint.h>
#include <math.h>
#include <assert.h>
#include <time.h>
#include <unistd.h>

#define verbose 0

typedef struct{
  int M;
  int N;
  int P;
  size_t nH;
  double m0, m1, n0, n1, p0, p1;
  double d; // min distance between points
  size_t nD; // Number of points to consider
  size_t stride; // Stride in D.
} nn_settings;

void showPoint(double * A)
{
  printf("%f %f %f\n", A[0], A[1], A[2]);
}

double eudist2(const double * restrict A, const double * restrict B)
{
  // Squared euclidean distance between two 3D points
  return (A[0]-B[0])*(A[0]-B[0]) +(A[1]-B[1])*(A[1]-B[1]) + 
    (A[2]-B[2])*(A[2]-B[2]);
}

uint32_t hash_m(const double * restrict d, const nn_settings s)
{
  return floor(s.M*(d[0]-s.m0)/1.0001/(s.m1-s.m0));
}

uint32_t hash_n(const double * restrict d, const nn_settings s)
{
  return floor(s.N*(d[1]-s.n0)/1.0001/(s.n1-s.n0));
}

uint32_t hash_p(const double * restrict d, const nn_settings s)
{
  return floor(s.P*(d[2]-s.p0)/1.0001/(s.p1-s.p0));
}

uint32_t hash(const double * restrict d, const nn_settings s)
{
  uint32_t m = hash_m(d,s);
  uint32_t n = hash_n(d,s);
  uint32_t p = hash_p(d,s);

#ifndef NDEBUG
  if(!(n<s.N))
    printf("%f %f %f : %u\n", d[0], d[1], d[2], n);
#endif
  assert(m<s.M);
  assert(n<s.N);
  assert(p<s.P);

  return m+ n*s.M+ p*s.M*s.N;
}

double maxs(const double * restrict D, const size_t nD, const int stride)
{ // max of double vector with stride
  double max = -INFINITY;
  for(size_t kk = 0; kk<nD; kk++)
    if(D[kk*stride]>max)
      max = D[kk*stride];
  return max;
}

double mins(const double * restrict D, const size_t nD, const int stride)
{
  double min = INFINITY;
  for(size_t kk = 0; kk<nD; kk++)
    if(D[kk*stride]<min)
      min = D[kk*stride];
  return min;
}

nn_settings nn_setParameters(double * D, size_t nD, size_t stride, double d)
{
  nn_settings s;
  s.d = d;
  s.nD = nD;
  s.stride = stride;

  // Set up M, N, P that determines the grid size of the domain of the
  // points
  s.M = sqrt(s.nD);
  s.N = sqrt(s.nD);
  s.P = sqrt(s.nD);

  s.m0 = mins(D, s.nD, stride);
  s.m1 = maxs(D, s.nD, stride);
  s.m1 = s.m1 + 0.001*(s.m1-s.m0);

  if(1000000*s.d>(s.m1-s.m0))
    s.M = floor((s.m1-s.m0)/s.d);

  // assert((m1-m0)/M>=d); // bin size at least d
  if(s.M==0)
    s.M = 1;

  s.n0 = mins(D+1, s.nD, stride);
  s.n1 = maxs(D+1, s.nD, stride);
  s.n1 = s.n1 + 0.001*(s.n1-s.n0);
  if(1000000*s.d>(s.n1-s.n0))
    s.N = floor((s.n1-s.n0)/s.d);

  // assert((n1-n0)/N>=d); // bin size at least d
  if(s.N==0)
    s.N = 1;
  s.p0 = mins(D+2, s.nD, stride);
  s.p1 = maxs(D+2, s.nD, stride);
  s.p1 = s.p1 + 0.001*(s.p1-s.p0);
  if(1000000*s.d>(s.p1-s.p0))
    s.P = floor((s.p1-s.p0)/s.d);
  // assert((p1-p0)/P>=d); // bin size at least d
  if(s.P==0)
    s.P = 1;

  // Avoid using too much memory. 
  // get some system statistics from proc
  // to tune better
  while(0.1*s.M*s.N*s.P>s.nD || s.M*s.N*s.P > 1000000000)
  {
    if(s.M>1)
      s.M--;
    if(s.N>1)
      s.N--;
    if(s.P>1)
      s.P--;
  }

  s.nH = s.M*s.N*s.P;

  if(verbose)
  {
    printf("M: %d : [%f, %f]\n", s.M, s.m0, s.m1);
    printf("N: %d : [%f, %f]\n", s.N, s.n0, s.n1);
    printf("P: %d : [%f, %f]\n", s.P, s.p0, s.p1);
  }
  //sleep(2);

  return s;
}

void setup_H(const double * restrict D, uint32_t * restrict H, nn_settings s)
{
  /* Hash all elements in D and count them in the second row of H */

  for(size_t kk = 0; kk<s.nD; kk++)
  {
    uint32_t h = hash(D+kk*s.stride, s);
    assert(h<s.M*s.N*s.P);
    H[2*h]++;
  }

  // for(size_t kk = 0; kk<nH; kk++)
  //   printf("H0[%zu]=%u, %zu\n", kk, H[2*kk], H[2*kk+1]);

  // Convert to start positions
  uint32_t acc = 0;
  for(size_t kk = 0; kk<s.nH; kk++)
  {
    uint32_t a = H[2*kk];
    H[2*kk] = acc;
    acc += a;
  }


}

void setup_T(uint32_t * restrict T, 
    uint32_t * restrict H, 
    const double * restrict D, 
    nn_settings s)
{
  /* Setup the bucket table */

  if(verbose)
    printf("Insert points in T\n");

  for(size_t kk = 0 ; kk<s.nD; kk++)
  {
    uint32_t h = hash(D+kk*s.stride, s);
    T[H[2*h]+H[2*h+1]] = kk;
    H[2*h+1]++; // increase the next write position
  }

  //  for(size_t kk = 0; kk<nH; kk++)
  //    printf("H[%zu]=%u, %zu\n", kk, H[2*kk], H[2*kk+1]);


  //  for(size_t kk = 0; kk<nD; kk++)
  //    printf("T[%zu]=%u\n", kk, T[kk]);
}

void hash_range(double * PT, uint32_t * HR, nn_settings s)
{
  // Get ranges for the neighbouring buckets to look in
  uint32_t hashm = hash_m(PT,s); 
  HR[0] = hashm;
  HR[1] = hashm;
  if(hashm > 0)
    HR[0] = hashm-1;
  if(hashm + 1 < s.M)
    HR[1] = hashm +1;

  uint32_t hashn = hash_n(PT,s); 
  HR[2] = hashn;
  HR[3] = hashn;
  if(hashn > 0)
    HR[2] = hashn-1;
  if(hashn + 1 < s.N)
    HR[3] = hashn +1;

  uint32_t hashp = hash_p(PT,s); 
  HR[4] = hashp;
  HR[5] = hashp;
  if(hashp > 0)
    HR[4] = hashp-1;
  if(hashp + 1 < s.P)
    HR[5] = hashp +1;

#ifndef NDEBUG  
  printf("Will search in %d %d %d %d %d %d\n", HR[0], HR[1], HR[2], HR[3], HR[4], HR[5]);
#endif

}

int nn(double * restrict D, uint8_t * restrict X, 
    const nn_settings s)
{

  const double d2 = s.d*s.d; // squared distance

  uint32_t * H = malloc(2*s.nH*sizeof(uint32_t));
  if(H==NULL)
  {
    perror("Failed to allocate H");
    return -1;
  }

  memset(H, 0, 2*s.nH*sizeof(uint32_t));

  // Count the number of elements in each bucket
  setup_H(D, H, s);

  uint32_t * T = malloc(s.nD*sizeof(uint32_t));
  if(T==NULL)
  {
    free(H);
    perror("Failed to allocate T");
    return -1;
  }

  setup_T(T, H, D, s);

  if(verbose)
    printf("Scan all the points and see if there is a neighbour\n");

  for(size_t kk =0; kk<s.nD; kk++)
  {
    if(X[kk] == 0)
    {
#ifndef NDEBUG
      uint32_t h = hash(D+kk*s.stride, s);
      assert(h+1<2*s.M*s.N*s.P);
#endif

      double * curr_point = D+kk*s.stride; 
      double curr_set = curr_point[s.stride-1];

      uint32_t HR[6];
      hash_range(D+kk*s.stride, HR, s);

      for(uint32_t hm = HR[0] ; hm<= HR[1]; hm++)
        for(uint32_t hn = HR[2] ; hn<= HR[3]; hn++)
          for(uint32_t hp = HR[4] ; hp<= HR[5]; hp++)
          {
            uint32_t hnear = hm+ hn*s.M + hp*s.M*s.N; // hash value for the neighbouring bucket

            // All elements in the bucket
            for(size_t nn = H[2*hnear]; nn<H[2*hnear]+H[2*hnear+1]; nn++)
            {
              double * cmp_point =D+T[nn]*s.stride;
              double cmp_set = cmp_point[s.stride-1];
              //  printf("%f vs %f\n", curr_set, cmp_set);
              if(curr_set != cmp_set) // Don't check within the same set
                if(curr_point != cmp_point) // Don't check against self
                { 
                  double dist = eudist2(curr_point, cmp_point );
                  if(dist<d2)
                  {
                    // Mark for deletion
                    assert(kk<s.nD);
                    assert(T[nn]<s.nD);
                    X[kk] = 1; // corresponding to the curr_point
                    X[T[nn]] = 1; // corresponding to cmp_point
                  }
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
  printf("random seed: %d\n", seed);
  srand(seed);
  size_t N = 1000000; // number of points
  size_t M = 10; // number of values per point, i.e., (x,y,z,id,color)
  double * D = malloc(N*M*sizeof(double));
  uint8_t * X = malloc(N*sizeof(uint8_t));
  memset(X, 0, N*sizeof(uint8_t));
  for(size_t kk = 0; kk<N*M; kk++)
    D[kk] = 1024*(rand()/ (double) RAND_MAX);
  for(size_t kk = 0; kk<N; kk++)
    D[kk*M+9] = 1;

  double d= 2;
  nn_settings s = nn_setParameters(D, N, M, d);

  nn(D,X, s);

  free(X);
  free(D);

}
