#include <stdlib.h>
#include <math.h>
#include <stdio.h>
#include <stdint.h>

#define M_PI 3.14159265358979323846 

double eudist2(double x1, double y1, double z1, double x2, double y2, double z2)
{
  // ||X-Y||^2
    double distance2 = pow(x1-x2,2) +pow(y1-y2,2) + pow(z1-z2, 2);
//  printf("%f %f %f , %f %f %f distance2: %f\n", x1, y1, z1, x2, y2, z2, distance2);
    return distance2;
}

void getRange(const double * restrict A, size_t nA, double * min, double * max)
{
  const size_t stride = 3;
  double min_value = INFINITY;
  double max_value = -INFINITY;

  for(size_t kk =0; kk<nA; kk++)
  {
    if(A[kk*stride]>max_value)
      max_value = A[kk*stride];

    if(A[kk*stride]<min_value)
      min_value = A[kk*stride];
  }

  min[0] = min_value;
  max[0] = max_value;

}

double sphere3_sampling(double radius,
    double * A, size_t nA)
{
  /* For one set of spheres, report the volume that is covered */

const size_t stride = 1;
  const double radius2 = radius*radius;
  double x0 = 0; double x1 = 0;
  double y0 = 0; double y1 = 0;
  double z0 = 0; double z1 = 0;
  getRange(A, nA, &x0, &x1);
  getRange(A+1, nA, &y0, &y1);
  getRange(A+2, nA, &z0, &z1);

  // volume of enclosing box 
  double volume_box =  (x1-x0+2*radius)*(y1-y0+2*radius)*(z1-z0+2*radius);
  size_t n_samples = 10e7;
  double delta = cbrt((double) volume_box/ (double) n_samples);

  printf("radius: %f\n", radius);
  printf("radius2: %f\n", radius2);
  printf("delta: %f\n", delta);
  printf("volume_box: %f\n", volume_box);
  printf("nA: %zu\n", nA);
  printf("A = [%f, %f, %f, ...\n", A[0], A[1], A[2]);


  size_t n_points = 0;
  size_t n_inside = 0;

  double xx = 0;
  double yy = 0;
  double zz = 0;

  for(double xx = x0-radius; xx<x1+radius+delta; xx=xx+delta)
    for(double yy = y0-radius; yy<y1+radius+delta; yy=yy+delta)
      for(double zz = z0-radius; zz<z1+radius+delta; zz=zz+delta)
      {
        for(size_t aa = 0; aa<nA; aa++)
        {
          if(eudist2(xx,yy,zz, A[aa*stride], A[aa*stride+1], A[aa*stride+2])<radius2)
          {
            n_inside++;
            aa = nA; // don't count twice
          }
        }

        n_points++;
      }

volume_box = (xx-x0)*(yy-y0)*(zz-z0);

  printf("n_points: %zu\n", n_points);
  printf("n_inside: %zu\n", n_inside);

  return (double) n_inside*pow(delta, 3);
  // (double) n_inside * (double) n_points * volume_box;
}


int main(int argc, char ** argv)
{

  double radius = 1;
  size_t nD = 1;// number of dots
  double * D = calloc(3*nD, sizeof(double));

  double volume =sphere3_sampling(radius, D, 1);

 printf("radius: %f, volume: %f, error: %f\n", radius, volume, volume-4.0/3.0*M_PI);
 return 0;
}
