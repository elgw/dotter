#ifndef gaussianInt2_c
#define gaussianInt2_c

#include <stdio.h>
#include <stdlib.h>
#include "string.h"
#include "math.h" // compile with -lm
#include "gaussianInt2.h"

/*

   Integrates Gaussian distributions over pixels.

   i1 = a    +c;
   i2 = a +b +c +d;
   i3 =       c;
   i3 =       c +d;
   i5 = a    +c    +e    +g;
   i6 = a +b +c +d +e +f +g +h;
   i7 =       c          +g;
   i8 =       c +d       +g +h;

*/
int gaussianInt3(double * GI, double * mu, double * sigma, int w)
{

  const double mux = mu[0];
  const double muy = mu[1];
  const double muz = mu[2];

  const int w2 = w*w;
  if(w>1000) {
    return -1;
  }

  double * erfx = malloc((w+1)*sizeof(double));
  double * erfy = malloc((w+1)*sizeof(double));
  double * erfz = malloc((w+1)*sizeof(double));

  double x0 = -(double) w/2;
  double y0 = -(double) w/2;
  double z0 = -(double) w/2;

  for(int kk=0; kk<w+1; kk++)
  {
    //  printf("x0: %f y0: %f \n", x0, y0);
    erfx[kk] = .5*(1+erf((x0++-mux)/sqrt(2)/sigma[0]));
    erfy[kk] = .5*(1+erf((y0++-muy)/sqrt(2)/sigma[1]));
    erfz[kk] = .5*(1+erf((z0++-muz)/sqrt(2)/sigma[2]));
  }

  for(int zz=0; zz<w; zz++)
    for(int yy =0; yy<w; yy++)
      for(int xx=0; xx<w; xx++)
      {
        double a   = erfx[xx+0]*erfy[yy+0]*erfz[zz+0];
        double b   = erfx[xx+0]*erfy[yy+1]*erfz[zz+0];
        double c   = erfx[xx+1]*erfy[yy+0]*erfz[zz+0];
        double d   = erfx[xx+1]*erfy[yy+1]*erfz[zz+0];
        double e   = erfx[xx+0]*erfy[yy+0]*erfz[zz+1];
        double f   = erfx[xx+0]*erfy[yy+1]*erfz[zz+1];
        double g   = erfx[xx+1]*erfy[yy+0]*erfz[zz+1];
        double h   = erfx[xx+1]*erfy[yy+1]*erfz[zz+1];
        GI[xx +w*yy +w2*zz]=-(a-b-c+d-e+f+g-h);
      }

  free(erfz);
  free(erfy);
  free(erfx);
  return 1;
}

void gaussianInt2(double * GI, double * mu, double * sigma, int w)
{

  double mux = mu[0];
  double muy = mu[1];

  double * erfx = malloc((w+1)*sizeof(double));
  double * erfy = malloc((w+1)*sizeof(double));

  double x0 = -(double) w/2;
  double y0 = -(double) w/2;
  for(int kk=0; kk<w+1; kk++)
  {
    //  printf("x0: %f y0: %f \n", x0, y0);
    erfx[kk] = .5*(1+erf((x0++-mux)/sqrt(2)/sigma[0]));
    erfy[kk] = .5*(1+erf((y0++-muy)/sqrt(2)/sigma[0]));
  }

  for(int xx=0; xx<w; xx++) {
    for(int yy =0; yy<w; yy++)
    {
      double one   = erfx[xx+1]*erfy[yy];
      double two   = erfx[xx+1]*erfy[yy+1];
      double three = erfx[xx]*erfy[yy];
      double four  = erfx[xx]*erfy[yy+1];
      GI[xx+w*yy]=two-one-four+three;
    }
  }

  free(erfy);
  free(erfx);
}

#ifdef testme
int main(int argc, char ** argv)
{

  int w = 11;

  double sigma[] = {1,3,1234144};
  double mu[] = {123,43,-124.1};

  double * V = malloc(w*w*w*sizeof(double));
  int status = gaussianInt3(V, sigma, mu, w);

  free(V);
  return status;

}

#endif

#endif
