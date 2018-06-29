#include <stdlib.h>
#include <math.h>
#include <stdio.h>
#include <stdint.h>
#include <assert.h>

#ifndef M_PI
#define M_PI 3.14159265358979323846 
#endif

#define verbose 0

#include "volume_spheres_sampling.c"

void ut_sphere3_sampling_intersection()
{
double radius = 1;
  size_t nA = 1;// number of dots
  double * A = calloc(3*nA, sizeof(double));
  size_t nB = 1;// number of dots
  double * B = calloc(3*nB, sizeof(double));

  printf("Intersecting spheres, radius = %f\n", radius);
  printf("Distance, Intersection\n");
for(double bpos = 0; bpos <= 2.01; bpos = bpos + 0.1)
{
  B[0] = bpos;
  double volume =sphere3_sampling_intersection(10e6, radius, A, 1, B, 1);
 printf("%1.3f %1.3f\n", bpos, volume);
}

}

void ut_sphere3_sampling()
{
double radius = 1;
  size_t nD = 1;// number of dots
  double * D = calloc(3*nD, sizeof(double));

  double volume =sphere3_sampling(10e6, radius, D, 1);

 printf("radius: %f, volume: %f, error: %f\n", radius, volume, volume-4.0/3.0*M_PI);
}

int main(int argc, char ** argv)
{

  ut_sphere3_sampling();
  ut_sphere3_sampling_intersection();

   return 0;
}
