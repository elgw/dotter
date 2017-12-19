/* Most simple image structure */

#ifndef BIM_H
#define BIM_H

#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>

typedef struct{
  double * V;
  uint8_t nD;
  uint32_t * D;
} bim;

int bim_alloc(bim * , uint8_t );
int bim_alloc_im(bim * , uint8_t , size_t , size_t );
bim bim_new(uint8_t );
int bim_free(bim * );

// bim_to_double(bim *);
// bim_transpose(bim *);
// bim bim_copy(bim *);
// bim_add_scalar
// bim_add_bim
// bim_mult_scalar
// bim_mult_bim
// bim_max
// bim_min
// bim_median

int bim_alloc(bim * I, uint8_t nD)
{
  assert(nD>0);
  printf("Allocating for %uD image\n", nD);
  I->nD = nD;
  I->D = calloc(nD, sizeof(uint32_t));
  I->V = NULL;  
  return 0;
}

int bim_alloc_im(bim * I, uint8_t nD, size_t M, size_t N)
{
  if(bim_alloc(I, nD) != 0) 
    return 1;

  I->V = calloc(M*N, sizeof(double));
  if(I->V == NULL) 
    return 1;
  I->D[0] = M;
  I->D[1] = N;

  return 0;
}

bim bim_new(uint8_t nD)
{
  bim I;
  bim_alloc(&I, nD);
  return(I);
}

int bim_free(bim * I)
{
  free(I->V);
  free(I->D);
  I->nD = 0;
  return 0;
}

#endif
