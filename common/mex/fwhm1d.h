#ifndef __fwhm1d_h__
#define __fwhm1d_h__

/* Only thread safe when logFile == NULL */

#include <assert.h>
#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <gsl/gsl_errno.h>
#include <gsl/gsl_interp.h>
#include <gsl/gsl_min.h>
#include <gsl/gsl_roots.h>
#include <gsl/gsl_spline.h>

#ifndef verbose
#define verbose 0
#endif

/*
  $ ./fwhm > interp.dat
  $ graph -T ps < interp.dat > interp.ps
*/

struct dbg_data {
    double xm; // location of maxima
    double ym; // value at maxima
    double xleft;
    double xright;
};


/* Calculate the fwhm for the y at the locations x
 * Stores the result in fwhm
 *
 * Algorithm:
 * 1. Find the interpolated location of the maxima.
 * 2. Use all pixels in the profile to find the background level as the
 *    smallest value
 * 3. Use approx 50% of the central pixels to find the zero crossing of
 *    the 50% value and the profile.
 * 4. Return the distance between the left and right zero crossing if both
 *    look ok, or use 2 mid-zero crossing of only one found.
*/
int fwhm1d(const double * x, const double * y, size_t N, double * fwhm);

#endif
