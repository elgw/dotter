/*
 *
 * ML fitting of size (sigma, s) and number of photons (n)
 * of already localized dots using a 2D Gaussian model provided by gaussianInt2.
 * 
 * Only one dot at a time is considered, hence the 1 in mlfit1sn
 *
 * Uses 3D images however only a xy-plane at at time is used for the
 * fitting.
 *
 * See also: 
 *   mlfit1.c, fitting of xy
 *   df_mlfit1sn.c, a MATLAB interface
 *
 * 2017.04.12. Valgrind ok.
 *
 * Future work:
 * - Return the fitting status
 * - Study the failed cases
 * - More restrictions on the search domain, i.e., cap sigma depending
 *   on the window size

 ==9245== Invalid write of size 8
==9245==    at 0x1094C9: mlfit1sn_dot (mlfit1sn.c:227)
==9245==    by 0x109A9B: mlfit1sn (mlfit1sn.c:278)
==9245==    by 0x109A9B: unit_tests (mlfit1sn.c:346)
==9245==    by 0x57F73F0: (below main) (libc-start.c:291)
==9245==  Address 0x5babf98 is 24 bytes after a block of size 32,000 in arena "client"
==9245== 

*/

#include <assert.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

#include <gsl/gsl_multimin.h>
#include <gsl/gsl_statistics.h>

#include "gaussianInt2.h"
#include "mlfit.h"
#include "blit3.h"

//
// Headers
//

// Number of photons in signal
double estimateNphot(double *, size_t);
// Locate multiple dots in a volume
int    mlfit1sn(double * , size_t , size_t , size_t , 
                            double * , size_t , double * );
// Localization for single dot
int    mlfit1sn_dot(double *, size_t, double *,  double *);
// Cost function
double my_f (const gsl_vector *, void *);
// Random number in a range
double rand_range(double, double);
int    unit_tests(void);
 
// 0: no information, 1: per dot, 2: even more
#ifndef verbose
#define verbose 0
#endif

// When low on bugs,
// replace gsl_vector_get(v,i) by v->data[i*v->stride]
// #define GSL_RANGE_CHECK_OFF

// Globals
#if verbose>1
uint32_t maxInterations = 5;
#else
uint32_t maxInterations = 5000;
#endif 

double convCriteria = 1e-6;
// In theory also the window size, denoted Ws in most places

// Optimization constants
typedef struct {
  double * R; // local region
  double * G; // A already allocated temporary space for the Gaussian kernel
  size_t Rw; // R and G has size Rw*Rw
  double sigma; // For constant sigma fitting
  double bg;
  double x;
  double y;
  double midvalue; // value of central pixel in model - bg
} optParams;

double my_f (const gsl_vector *v, void *params)
  // The function to optimize
{
  optParams *p = (optParams *) params;

  size_t Rw = p->Rw;
  double * R = p->R;
  double * GI = p->G;
  double bg = p->bg;
  double x = p->x;
  double y = p->y;

  // Get the other parameters ...  
  double sigma = gsl_vector_get(v, 0);
  double Nphot = gsl_vector_get(v, 1);

#if verbose > 1
  printf("Rw: %lu\n", Rw);
  printf("Nphot: %f\n", Nphot);
  printf("sigma: %f\n", sigma);
  printf("bg   : %f\n", bg);
  printf("x: %f, y: %f\n", x, y);
  printf("GI:\n");
  showRegion(GI, Rw);
#endif 

  if(sigma<0)
    return(INFINITY);

  if(Nphot<0)
    return(INFINITY);

  // Create Gaussian ...
  double mu[] = {x,y};
  gaussianInt2(GI, mu, &sigma, Rw);
  p->midvalue = Nphot*GI[ (Rw*Rw-1)/2 ];
  for(size_t kk = 0; kk<Rw*Rw; kk++)
    GI[kk] = bg+Nphot*GI[kk];


  /* 
   * from LL2PG.m
   *   model = x(3)+x(4)*gaussianInt2([x(1), x(2)], x(5), (size(patch, 1)-1)/2);
   *   mask = disk2d((size(patch,1)-1)/2);
   *   %L = -sum(sum(-(patch-model).^2./model - .5*log(model)));
   *   L = -sum(sum( mask.*( -(patch-model).^2./model - .5*log(model) ) ));
   */

  double E = 0;
  for (size_t kk=0; kk<Rw*Rw; kk++)
  {
    E+= (GI[kk]-R[kk])*(GI[kk]-R[kk])/GI[kk] - .5*log(GI[kk]); // ML
    //E+= (GI[kk]-R[kk])*(GI[kk]-R[kk]); // Quadratic
  }
  //  E = -E;


  #if verbose > 1
  printf("E: %f\n", E);
#endif
  return E;
} 

int mlfit1sn_dot(double * V, size_t Vm, 
    double * D,  double * F)
  // Localization for a dot roughly centered in V of size Vm x Vm
  // D[0], D[1], D[3] are the global coordinates of the dot
  // F are the fitted coordinates
{
  // Non-optimized parameters
  optParams par;
  par.R = V;
  par.Rw = Vm;
  par.x = D[0]-nearbyint(D[0]);
  par.y = D[1]-nearbyint(D[1]);
  // par.z required for accurate nphot counting, sigma is invariant to
  // this shift
  par.bg = estimateBG(V, Vm);
  par.G = malloc(Vm*Vm*sizeof(double));

#if verbose>0
  printf("localizeDot\n");
  printf("x: %f y: %f\n", par.x, par.y);
  printf("bg: %f\n", par.bg);
#endif

  const gsl_multimin_fminimizer_type *T = 
    gsl_multimin_fminimizer_nmsimplex2;
  gsl_multimin_fminimizer *s = NULL;
  gsl_vector *ss, *x;
  gsl_multimin_function minex_func;

  size_t iter = 0;
  int status;
  double size;

  /* Starting point */
  x = gsl_vector_alloc (2);
  gsl_vector_set(x, 0, 1.2); // sigma
  double nphot0 =estimateNphot(V, Vm); 
  gsl_vector_set(x, 1, nphot0); // Nphot

  /* Set initial step sizes */
  ss = gsl_vector_alloc(2);
  gsl_vector_set(ss, 0, 0.1); // sigma
  gsl_vector_set(ss, 1, nphot0/100); // Number of photons

  /* Initialize method and iterate */
  minex_func.n = 2;
  minex_func.f = my_f;
  minex_func.params = &par;

  s = gsl_multimin_fminimizer_alloc (T, 2);
  gsl_multimin_fminimizer_set (s, &minex_func, x, ss);

  do
  {
    iter++;
    status = gsl_multimin_fminimizer_iterate(s);

    if (status) 
      break;

    size = gsl_multimin_fminimizer_size(s);
    status = gsl_multimin_test_size(size, convCriteria);

    if (status == GSL_SUCCESS)
    {
#if verbose > 0
      printf ("converged to minimum at\n");
      printf ("%5lu sigma:%10.3e NP:%10.3e f() = %7.3f size = %10.3e\n", 
          iter,
          gsl_vector_get (s->x, 0), 
          gsl_vector_get (s->x, 1), 
          s->fval, size);
#endif
    }
  }
  while (status == GSL_CONTINUE && iter < maxInterations);

  F[0] = gsl_vector_get(s->x, 0);
  F[1] = par.midvalue;
  F[2] = s->fval;
  F[3] = status;
  F[4] = par.bg;

  gsl_vector_free(x);
  gsl_vector_free(ss);
  gsl_multimin_fminimizer_free(s);

  free(par.G);

  return status;
}

int mlfit1sn(double * V, size_t Vm, size_t Vn, size_t Vp, 
    double * D, size_t Dm, double * F)
  // run the localization routine for a list of dots, D [3xDm]
{

  // Return values have to be checked
  gsl_set_error_handler_off();
  // as a custom error handler can also be used.

  int Ws_pref = 15; // Window size is Ws x Ws
  int Ws = Ws_pref;
  double * W = malloc(Ws_pref*Ws_pref*sizeof(double));

  for(size_t kk =0; kk<Dm; kk++)
  {
    // Copy the neighbourhood around each D into W
    int hasRegion = 0;

    for(Ws = Ws_pref; Ws>7; Ws = Ws-2) {
      if(getRegion(W, Ws, V, Vm, Vn, Vp, D+kk*3) == 0) {
        hasRegion = 1;
        break;
      } else {
#if verbose >0
        printf("Ws: %d not possible\n", Ws);
#endif
      }
    }
#if verbose>0
    printf("Ws: %d\n", Ws);
#endif

    if(hasRegion == 1) {
#if verbose > 1
      printf("W:\n");
      showRegion(W, Ws);
#endif
      // Local fitting in W
#if verbose > 0
      int status = mlfit1sn_dot(W,  Ws, D+kk*3, F+kk*5);
      printf("Status: %d\n", status);
#else
     mlfit1sn_dot(W,  Ws, D+kk*3, F+kk*5);
#endif
    }
    else
    {
      F[kk*5] = -1;
      F[kk*5+1] = -1;
      F[kk*5+2] = -1;
      F[kk*5+3] =  -3;
      F[kk*5+4] = 0;
    }
  }
  free(W);
  return 0;
}


#ifdef standalone
int unit_tests()
{
  double * V; // image
  int Vm = 1024; int Vn = 1024; int Vp = 60;
  double * D; // list of dots
  size_t Dm = 1000; // number of dots
  double * F; // fitted dots

  printf("Image size: %dx%dx%d\n", Vm, Vn, Vp);
  printf("Localizing %lu dots\n", Dm);

  V = malloc(Vm*Vn*Vp*sizeof(double));
  D = malloc(3*Dm*sizeof(double));
  F = malloc(4*Dm*sizeof(double));

  // Initialize the data
  for(int kk=0; kk<Vm*Vn*Vp; kk++)
    V[kk] = rand_range(0,0);

  for(uint32_t kk=0; kk<Dm; kk++)
  {
    size_t pos = kk*3;
    D[pos] =   rand_range(-1, Vm+1); 
    D[pos+1] = rand_range(6, Vn-7); 
    D[pos+2] = rand_range(6, Vp-7); 
    if(D[pos] < 6)
      D[pos] = 6;
    if(D[pos+1] < 6)
      D[pos+1] = 6;
    if(D[pos+2] < 6)
      D[pos+2] = 6;
#if verbose > 0
    printf("D %03d %f %f %f\n", kk, D[pos], D[pos+1], D[pos+2]);
#endif
  }

  for(uint32_t kk=0; kk<Dm; kk++)
  {
    size_t pos = D[kk*3] + D[kk*3+1]*Vm + D[kk*3+2]*Vm*Vn;
    V[pos] = 5;
  }

  D[0] = 100; D[1] = 100; D[2] = 30;
  V[(int) D[0]+(int) D[1]*Vm+(int) D[2]*Vm*Vn] = 7;
  V[(int) D[0]+1+(int) D[1]*Vm+(int) D[2]*Vm*Vn] = 6;

  // Run the optimization
  mlfit1sn(V, Vm, Vn, Vp, D, Dm, F);

  // In next version, also supply clustering information

#if verbose >0
  for(size_t kk = 0; kk<Dm; kk++)
  {
    size_t pos = kk*3;
    size_t dpos = kk*4;
    printf("%6lu (%f, %f, %f) : s: %f, n: %f e: %f status: %d\n", kk,
        D[pos], D[pos+1], D[pos+2],
        F[dpos], F[dpos+1], F[dpos+2], (int) F[dpos+3]);
  }
#endif 
  free(F);
  free(D);
  free(V);
  return 0;  
}

int main(int argc, char ** argv)
  // For testing, not used any more, see the MATLAB interface in
  // df_mlfit.c
{

  printf("%s\n", argv[0]);

  if(argc == 1) {
    return unit_tests();
  }

  return 1;
}
#endif 

