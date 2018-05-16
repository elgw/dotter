#include <math.h>

double min(double a, double b)
{
  if(a<b)
    return a;
  return b;
}

double max(double a, double b)
{
  if(a>b)
    return a;
  return b;
}

double vmin(double * restrict V, const size_t stride, const size_t N)
{
  double m = INFINITY;
  for(size_t kk = 0; kk<N*stride; kk=kk+stride)
    m = min(m, V[kk]);
  return m;
}

double vmax(double * restrict V, const size_t stride, const size_t N)
{
  double m = -INFINITY;
  for(size_t kk = 0; kk<N*stride; kk=kk+stride)
    m = max(m, V[kk]);
  return m;
}

void sphere3(double * restrict B, const size_t M, const size_t N, const size_t P, double * restrict D, const size_t nD, const double radius, const double offset)
{
  //printf("M: %zu, N: %zu, P: %zu ,nD: %zu\n", M, N, P, nD);
  //printf("%f\n", radius);

  if(nD == 0)
    return;


  double m0 = 0; double m1 = M;
  double n0 = 0; double n1 = N;
  double p0 = 0; double p1 = P;

  if(radius>0)
  {
    m0  = max(0, vmin(D, 3, nD)  -radius-1*offset);
    m1  = min(M, vmax(D, 3, nD)  +radius-1*offset+1);
    n0  = max(0, vmin(D+1, 3, nD)-radius-1*offset);
    n1  = min(N, vmax(D+1, 3, nD)+radius-1*offset+1);

    p0  = max(0, vmin(D+2, 3, nD)-radius-1*offset);
    p1  = min(P, vmax(D+2, 3, nD)+radius-1*offset+1);
  }

  size_t M0 = (size_t) m0;
  size_t M1 = (size_t) m1;
  size_t N0 = (size_t) n0;
  size_t N1 = (size_t) n1;
  size_t P0 = (size_t) p0;
  size_t P1 = (size_t) p1;

//   printf(" %zu %zu %zu %zu %zu %zu\n", M0, M1, N0, N1, P0, P1);

  if(0)
    for(size_t dd = 0; dd<nD; dd++)
    {
      printf("[%f %f %f, ...]\n", D[dd*3] ,D[dd*3+1], D[dd*3+2]);
    }

  for(size_t mm = M0; mm<M1; mm++)
    for(size_t nn = N0; nn<N1; nn++)
      for(size_t pp = P0; pp<P1; pp++)
        for(size_t dd = 0; dd<nD; dd++)
        {
          double d2 = 
            ((double) mm-D[dd*3]+offset)*((double) mm-D[dd*3]+offset) +
            ((double) nn-D[dd*3+1]+offset)*((double) nn-D[dd*3+1]+offset) +
            ((double) pp-D[dd*3+2]+offset)*((double) pp-D[dd*3+2]+offset);

          double sd2 = sqrt(d2);
          if(sd2<B[mm + nn*M + pp*M*N])
            B[mm + nn*M + pp*M*N] = sd2;
        }

  return;

}
