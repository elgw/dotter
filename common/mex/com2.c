#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdint.h>
#include <math.h>

// #define debugmode 1

const int comr = 2; // Radius of com filter in pixels
// The filter will be (2*comr+1)^2 pixels


int checkBounds(int * restrict D, 
    const size_t M, const size_t N)
{
    if(D[0]>=comr && D[0]<M-comr &&
       D[1]>=comr && D[1]<N-comr)
        return 1;

return 0;
}

void com2_local(double * restrict V, const size_t M, const size_t N,
    int * restrict D, double * restrict C)
{
  
#ifdef debugmode
  printf("D: [%u %u]\n", D[0], D[1]);
  printf("M: %lu N: %lu P: %lu\n", M, N);
#endif

  double sum = 0;
  double dx = 0;
 double dy = 0;

#ifdef debugmode
printf("sum: %f\n", sum);
#endif

if(checkBounds(D, M, N))
  {
   
    for(int kk = -comr; kk<=comr; kk++) {
    for(int ll = -comr; ll<=comr; ll++) {
    
      size_t pos = (D[0]+kk) + (D[1]+ll)*M;
    //  printf("pos: %lu V[pos]: %f\n", pos, V[pos]);
      dx += kk*V[pos];
      dy += ll*V[pos];

      sum += V[pos];
    } } 

//printf("sum: %f\n", sum);
  }

if(sum>0)
{
#ifdef debugmode
  printf("sum: %f (%f, %f)\n", sum, dx, dy);
#endif
  C[0] = D[0] + dx/sum;
  C[1] = D[1] + dy/sum;
}
else
{
#ifdef debugmode
  printf("No com calculation\n");
#endif
  C[0] = D[0];
  C[1] = D[1];
  }
}

void com2(double * V, size_t M, size_t N, 
   double * D, double * C, size_t L) {
  /* Centre of mass
   *
   * V: MxNxP image
   * P 2xL list of dots
   * C 2xL list of fitted dots
   */

  int Dround[] = {0,0};

  for(size_t kk = 0; kk<L; kk++)
  {
    Dround[0] = nearbyint(D[kk*2]-1);
    Dround[1] = nearbyint(D[kk*2+1]-1);

    com2_local(V, M, N, Dround, C+kk*2);
  }

}

#ifdef skipthis
int main(int argc, char ** argv)
{
  int M = 100; 
  int N = 100;
  int P = 1;
  int L = 2;

  double * V = malloc(M*N*P*sizeof(double));
  uint16_t * D = malloc(L*2*sizeof(uint16_t));
  double * C = malloc(L*2*sizeof(double));
  
  memset(V, 0, M*N*P*sizeof(double));
  memset(C, 0, 2*L*sizeof(double));

  for(size_t kk = 0; kk<M*N*P; kk++)
    V[kk] = 0;

  D[0] = 11; D[1] = 12; D[2] = 13;
  D[3] = 0; 

  size_t pos = D[0] + M*D[1];
  V[pos] = 3;
//  V[pos+1] = 1;
//  V[pos + M] = 1;
V[pos + M*N] = 1;

  com2(V, M, N, 
      D, C, L);

  for(int kk=0; kk<L; kk++) {
  printf("%d [%u %u] -> ", kk, D[2*kk], D[2*kk+1]);
  printf(" [%f %f]\n",         C[2*kk], C[2*kk+1]);
  }
}
#endif


