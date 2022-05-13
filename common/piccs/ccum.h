#ifndef __ccum_h__
#define __ccum_h__

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdint.h>
#include <assert.h>

/* Construct the cumulative correlation function, $C_{cum}$ in the
 *  paper
 *  C: an array for C_{cum}, nC number of elements
 *  A, B: coordinates of the dots
 *  w, h: size of image in the same unit as the dots
 *  lMAX largest distance to consider, i.e. C[nC-1] corresponds to
 *  lMAX^2
 * Algorithm: Brute force. Loop over all coordinate pairs and
 * add them to a histogram.
 */

void ccum(double * C, uint64_t nC,
          double * A, uint64_t nA,
          double * B, uint64_t nB,
          double w, double h,
          double lMAX);

/* Place unit tests here */
int ccum_ut(void);
#endif
