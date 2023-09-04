#ifndef _com3_h_
#define _com3_h_

/* Centre of mass
 *
 * Input:
 * Image of size MxNxP
 * P 3xL list of dots
 * Output:
 * C 3xL list of fitted dots
 * not used: weighted
 *
 * Note: The caller should allocate enough room for C
 * i.e. 3*L*sizeof(double)
 * Dots and COM need to point to different memory regions
 */


void
com3(const double * restrict Image,
     size_t M, size_t N, size_t P,
     const double * restrict Dots,
     double * restrict COM,
     size_t L,
     int weighted);

#endif
