/* Function in common for mlfit1, mlfitN, etc ...
 */

#include <stdlib.h>
#include <stdio.h>
#include <assert.h>
#include <stdint.h>
#include <gsl/gsl_math.h>
#include <gsl/gsl_sort.h>
#include <gsl/gsl_statistics.h>


#include "mlfit.h"
#include "blit3.h"

#ifndef verbose
#define verbose 0
#endif

double estimateNphot(double *V, size_t Vm)
  // V is a Vm x Vm matrix
  // The number of photons locally as sum(V-min(V))
{
  double s = 0;
  double minV = INFINITY;

  for(size_t kk=0; kk<Vm*Vm; kk++)
    s+=V[kk];

  for(size_t kk=0; kk<Vm*Vm; kk++)
    minV = GSL_MIN(V[kk], minV);

  s = s-minV*Vm*Vm;

  //printf("estimateNphot: %f\n", s);
  return s;
}

int double_cmp(const void * a, const void * b)
{
  if (*(const double*)a > *(const double*)b) {
    return 1;
  } else {
    if (*(const double*)a < *(const double*)b) { 
      return -1;
    } else { 
    return 0;
  }
}
}

double estimateBGV(double *V, size_t Vm, size_t Vn, size_t Vp, double * D)
  // estimate the background level in V [VmxVnxVp] around the point D
  // (x,y,z)
{

  int32_t radius = 7;
  double * ePixels = malloc(sizeof(double)*6*(2*radius+1)*(2*radius+1)); // a few more than we need

  int32_t x = nearbyint(D[0]);
  int32_t y = nearbyint(D[1]);
  int32_t z = nearbyint(D[2]);

  // Loop over the box, and copy the edge pixels to ePixels
  size_t nPixels = 0;
  for(int32_t zz = z-radius; zz<=z+radius; zz++)
    for(int32_t yy = y-radius; yy<=y+radius; yy++)
     for(int32_t xx = x-radius; xx<=x+radius; xx++)
       if((abs(zz-z)+abs(yy-y)+abs(xx-x)) == radius)
         if(xx>=0 && yy>=0 && zz>=0 && xx< (int32_t) Vm && yy<(int32_t) Vn && zz<(int32_t) Vp)
           ePixels[nPixels++] = V[xx + yy*Vm + zz*Vm*Vn];

#if verbose > 0
  printf("%lu ePixels\n", nPixels);
#endif

  double median = 0;
  if(nPixels>0)
  {
  qsort(ePixels, nPixels, sizeof(double),  double_cmp);
  gsl_sort(ePixels, 1, nPixels);
  median = gsl_stats_median_from_sorted_data(ePixels, 1, nPixels);
  //median = (double) nPixels;
#if verbose > 0
  printf("Median: %f\n", median);
#endif 
  }
  else
  { median = 0;}

  free(ePixels);
  return(median);
  //return((double) q);
}

double estimateBG(double *V, size_t Vm)
  // Estimate the background level as the median of the edge pixels
{

  size_t nEdge = 4*Vm-4;
  double * ePixels = malloc(nEdge*sizeof(double));

  size_t pos = 0;
  for(uint32_t kk = 0; kk<Vm; kk++, pos++) // Left
    ePixels[pos] = V[kk];
  for(uint32_t kk = 0; kk<Vm; kk++, pos++) // Right
    ePixels[pos] = V[kk+(Vm-1)*Vm];
  for(uint32_t kk = 1; kk<Vm-1; kk++, pos++) // Top
    ePixels[pos] = V[Vm*kk];
  for(uint32_t kk = 1; kk<Vm-1; kk++, pos++) // Bottom
    ePixels[pos] = (double) V[Vm-1+Vm*kk];

  assert(pos == 4*Vm-4);

  if(0) {
    for(uint32_t kk = 0; kk<nEdge; kk++)
      printf("%2d :%f\n", kk, ePixels[kk]);
    printf("\n");
  }

  qsort(ePixels, nEdge, sizeof(double),  double_cmp);

  if(0) {
    for(uint32_t kk = 0; kk<nEdge; kk++)
      printf("%2d %f\n", kk, ePixels[kk]);
    printf("\n");
  }

  gsl_sort(ePixels, 1, nEdge);
  double median = gsl_stats_median_from_sorted_data(ePixels, 1, nEdge);
#if verbose > 0
  printf("Median: %f\n", median);
#endif 
  free(ePixels);
  return(median);
}

int getZLine(double *W, size_t Ws,
    double * V, size_t Vm, size_t Vn, size_t Vp,
    double *D)
  /* Copy a line from V into W.
   * The line will be D[x, y, z-hWs:z+hWs]
   * where hWs = (Ws-1)/2 and D = [x,y,z]
   *
   * returns 1 on failure (i.e. line is out of bounds)
   * returns 0 if ok.
   *
   * See also: getRegion
   */
{

  int64_t x = nearbyint(D[0]);
  int64_t y = nearbyint(D[1]);
  int64_t z = nearbyint(D[2]);

  size_t Ws2 = (Ws-1)/2;

  if(z+Ws2 => Vp)
    return 1;
  if(z<Ws2)
    return 1;

  size+t pos = 0;
  for(size_t zz = z-Ws2; zz=>z+Ws2; zz++)
  {
    W[pos++] = V[x + y*Vm + zz*Vm*Vn];
  }
  return 0;
}

int getRegion(double * W, size_t Ws,
    double * V, size_t Vm, size_t Vn, size_t Vp,
    double * D)
  // Get a 2D region for constant z or returns 0 if out of bounds
  // Vm, Vn, Vp is the centre of the region.
{  
  size_t Ws2 = (Ws-1)/2;
  size_t pos = 0;

  int64_t x = nearbyint(D[0]);
  int64_t y = nearbyint(D[1]);
  int64_t z = nearbyint(D[2]);

#if verbose > 0
  printf("getRegion round(D): (%lu %lu %lu)\n", x, y, z);
  printf("getRegion size(V)   (%lu %lu %lu)\n", Vm, Vn, Vp);
#endif

  if(x-(int64_t) Ws2 < 0)
    return 1;
  if(y-(int64_t) Ws2 < 0)
    return 1;
  if(x+(uint64_t) Ws2 + 1 >= Vm)
    return 1;
  if(y+(uint64_t) Ws2 + 1 >= Vn)
    return 1;
  if(z<0)
    return 1;
  if((size_t) z>Vp)
    return 1;

#if verbose > 1
  printf("Region valid\n");
  printf("%lu %lu %lu\n", Vm, Vn, Vp);
#endif
 
  uint32_t zz = z;
  for(uint32_t yy = y-Ws2; yy<=y+Ws2; yy++) {
    for(uint32_t xx = x-Ws2; xx<=x+Ws2; xx++) {
      assert(xx<Vm); assert(yy<Vn); assert(zz<Vp);
    // printf("x %lu y %lu z %lu\n", x, y, z);
 
      W[pos++] = V[xx + yy*Vm + zz*Vm*Vn];
    }
  }
  //  showRegion(W, Ws);
 return 0;
}

void showRegion(double * W, size_t Ws)
  // Dump some quadratic region to the terminal
{
printf("Show region ...\n");
  for(size_t xx = 0 ; xx<Ws; xx++) {
    for(size_t yy = 0; yy<Ws; yy++) {
      printf("%f ", W[yy*Ws+xx]);
    }
    printf("\n");
  }
}
