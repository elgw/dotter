/*
 *
 * ML fitting of dots using a 2D Gaussian model provided by gaussianInt2.
 * I.e., only x and y are fitted.
 *
 * Compilation:
 * For debugging:
 *  gcc  3.c -Wall -std=c99 -I/usr/local/include -L/usr/local/lib -lgsl -lgslcblas -lm -g -o 3 
 *  valgrind ./3
 * For speed:
 *  gcc  -Wall -std=c99 3.c -I/usr/local/include -L/usr/local/lib -lgsl -lgslcblas -lm -O3 -o 3
 *  ./3
 * Memory accesses can also be checked with Valgrind or the gcc -fmudflap memory protection option. 
 *
 * MATLAB interface in df_mlfit1.c
 * 2017.04.12. Valgrind ok.
 *
 * TODO: 
 *  - Fitting in Z after X and Y.
 *
 */


/*
   From the GSL documentation:

   If necessary you can turn off range checking completely without
   modifying any source files by recompiling your program with the
   preprocessor definition GSL_RANGE_CHECK_OFF. Provided your compiler
   supports inline functions the effect of turning off range checking is
   to replace calls to gsl_vector_get(v,i) by v->data[i*v->stride] and
   calls to gsl_vector_set(v,i,x) by v->data[i*v->stride]=x. Thus there
   should be no performance penalty for using the range checking
   functions when range checking is turned off. 

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

// use the compile flag -D verbose=0 etc
// 0 = no information
// 1 = per dot information
// 2 = per iteration information
#ifndef verbose
#define verbose 1
#endif

// Globals
const int32_t maxIterations = 1000;
const double convCriteria = 1e-6;
// Possibly, add the window size, denoted Ws in most places

// Headers
double lxy (const gsl_vector *, void *);
double lz (const gsl_vector *, void *);
int localizeDotXY(double *, size_t, double *,  double *);
int localizeDotZ(double *, size_t, double *,  double *);
int localize(double *, size_t, size_t, size_t, double *, size_t, double *);
int unit_tests(void);

// Optimization constants
typedef struct {
  double * R; // local region
  double * G; // A already allocated temporary space for the Gaussian kernel
  size_t Rw; // R and G has size Rw*Rw
  double sigma; // For constant sigma fitting
  double bg;
} optParams;


double lz (const gsl_vector *v, void *params)
{
  double x;

  optParams *p = (optParams *) params;

  size_t Rw = p->Rw;
  double * R = p->R;
  double * GI = p->G;
  double sigma = p->sigma;
  double bg = p->bg;

#if verbose > 2
  printf("Rw: %lu\n", Rw);
  printf("Nphot: %lu\n", Nphot);
  printf("sigma: %f\n", sigma);
  printf("bg   : %f\n", bg);
#endif

  // Get the other parameters ...  
  x = gsl_vector_get(v, 0);
  double Nphot = gsl_vector_get(v,2);

  // Create Gaussian ...
  double mu[] = {x};
  gaussianInt1(GI, mu, &sigma, Rw);
  for(size_t kk = 0; kk<Rw; kk++)
    GI[kk] = bg+Nphot*GI[kk];
#if verbose
  printf("GI:\n");
  showRegion(GI, Rw);
#endif 

  /* 
   * from LL2PG.m
   *   model = x(3)+x(4)*gaussianInt2([x(1), x(2)], x(5), (size(patch, 1)-1)/2);
   *   mask = disk2d((size(patch,1)-1)/2);
   *   %L = -sum(sum(-(patch-model).^2./model - .5*log(model)));
   *   L = -sum(sum(mask.*(-(patch-model).^2./model - .5*log(model))));
   */

  double E = 0;
  for (size_t kk=0; kk<Rw; kk++)
    E+= (GI[kk]-R[kk])*(GI[kk]-R[kk])/GI[kk] - .5*log(GI[kk]);
  //  E = -E;

  /* Quadratic
   * for (size_t kk=0; kk<Rw*Rw; kk++)
   * E+= (GI[kk]-R[kk])*(GI[kk]-R[kk]);
   */

  return E;
}

double lxy (const gsl_vector *v, void *params)
  // likelihood in xy, function to optimize
{

  double x, y;

  optParams *p = (optParams *) params;

  size_t Rw = p->Rw;
  double * R = p->R;
  double * GI = p->G;
  double sigma = p->sigma;
  double bg = p->bg;

#if verbose > 2
  printf("Rw: %lu\n", Rw);
  printf("Nphot: %lu\n", Nphot);
  printf("sigma: %f\n", sigma);
  printf("bg   : %f\n", bg);
#endif

  // Get the other parameters ...  
  x = gsl_vector_get(v, 0);
  y = gsl_vector_get(v, 1);
  double Nphot = gsl_vector_get(v,2);

  // Create Gaussian ...
  double mu[] = {x,y};
  gaussianInt2(GI, mu, &sigma, Rw);
  for(size_t kk = 0; kk<Rw*Rw; kk++)
    GI[kk] = bg+Nphot*GI[kk];
#if verbose
  printf("GI:\n");
  showRegion(GI, Rw);
#endif 

  /* 
   * from LL2PG.m
   *   model = x(3)+x(4)*gaussianInt2([x(1), x(2)], x(5), (size(patch, 1)-1)/2);
   *   mask = disk2d((size(patch,1)-1)/2);
   *   %L = -sum(sum(-(patch-model).^2./model - .5*log(model)));
   *   L = -sum(sum(mask.*(-(patch-model).^2./model - .5*log(model))));
   */

  double E = 0;
  for (size_t kk=0; kk<Rw*Rw; kk++)
    E+= (GI[kk]-R[kk])*(GI[kk]-R[kk])/GI[kk] - .5*log(GI[kk]);
  //  E = -E;

  /* Quadratic
   * for (size_t kk=0; kk<Rw*Rw; kk++)
   * E+= (GI[kk]-R[kk])*(GI[kk]-R[kk]);
   */

  return E;
} 

int localizeDotXY(double * V, size_t Vm, 
    double * D,  double * F)
  // Localization for a dot roughly centered in V of size Vm x Vm
  // D[0], D[1], D[3] are the global coordinates of the dot
  // F are the fitted coordinates
{

  // Non-optimized parameters
  optParams par;
  par.R = V;
  par.Rw = Vm;
  par.sigma = 1.6;
  par.bg = estimateBG(V, Vm);
  par.G = malloc(Vm*Vm*sizeof(double));

  const gsl_multimin_fminimizer_type *T = 
    gsl_multimin_fminimizer_nmsimplex2;
  gsl_multimin_fminimizer *s = NULL;
  gsl_vector *ss, *x;
  gsl_multimin_function minex_func;

  size_t iter = 0;
  int status;
  double size;

  /* Starting point */
  x = gsl_vector_alloc (3);
  gsl_vector_set(x, 0, 0); // x position
  gsl_vector_set(x, 1, 0); // y position
  gsl_vector_set(x, 2, estimateNphot(V, Vm)); // Nphot

  /* Set initial step sizes */
  ss = gsl_vector_alloc(3);
  gsl_vector_set_all(ss, 0.1);
  gsl_vector_set(x, 2, 10); // Number of photons

  /* Initialize method and iterate */
  minex_func.n = 3;
  minex_func.f = lxy;
  minex_func.params = &par;

  s = gsl_multimin_fminimizer_alloc (T, 3);
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
      printf ("%5lu x:%10.3e y:%10.3e NP:%6.1f f() = %7.3f size = %10.3e\n", 
          iter,
          gsl_vector_get (s->x, 0), 
          gsl_vector_get (s->x, 1), 
          gsl_vector_get (s->x, 2), 
          s->fval, size);
#endif
    }
  }
  while (status == GSL_CONTINUE && iter < maxIterations);

  F[0] = gsl_vector_get (s->x, 0)+D[0];
  F[1] = gsl_vector_get (s->x, 1)+D[1];
  F[2] = D[2]; // Not optimized

  gsl_vector_free(x);
  gsl_vector_free(ss);
  gsl_multimin_fminimizer_free (s);

  free(par.G);

  return status;
}


int localize(double * V, size_t Vm, size_t Vn, size_t Vp, 
    double * D, size_t Dm, double * F)
  // run the localization routine for a list of dots
{

  int Ws = 7; // Window size
  double * W = malloc(Ws*Ws*sizeof(double));

  for(size_t kk =0; kk<Dm; kk++)
  {
    // Copy the neighbourhood around each D into W
    if(getRegion(W, Ws,
          V, Vm, Vn, Vp, D+kk*3) == 0)
    {
#if verbose > 1
      printf("W:\n");
      showRegion(W, Ws);
#endif
      // Local fitting in W
#if verbose > 0
      int status = localizeDotXY(W,  Ws, D+kk*3, F+kk*3);
      printf("Status: %d\n", status);
#else
      localizeDotXY(W,  Ws, D+kk*3, F+kk*3);
#endif
    }
    else
    {
      // TODO: add also Nphot and status to the output 
      F[kk*3] = -1;
      F[kk*3+1] = -1;
      F[kk*3+2] = -1;
    }
  }
  free(W);
  return 0;
}

int unit_tests(){
  double * V; // image
  int Vm = 1024; int Vn = 1024; int Vp = 60;
  double * D; // list of dots
  size_t Dm = 1000; // number of dots
  double * F; // fitted dots

  printf("Image size: %dx%dx%d\n", Vm, Vn, Vp);
  printf("Localizing %lu dots\n", Dm);

  V = malloc(Vm*Vn*Vp*sizeof(double));
  D = malloc(3*Dm*sizeof(double));
  F = malloc(3*Dm*sizeof(double));

  // Initialize the data
  for(int kk=0; kk<Vm*Vn*Vp; kk++)
    V[kk] = rand_range(0,0);

  for(uint32_t kk=0; kk<Dm; kk++)
  {
    size_t pos = kk*3;
    D[pos] =   rand_range(6, Vm-7); 
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
  localize(V, Vm, Vn, Vp, D, Dm, F);

  // In next version, also supply clustering information

#if verbose >0
  for(size_t kk = 0; kk<Dm; kk++)
  {
    size_t pos = kk*3;
    printf("%6lu (%f, %f, %f) -> (%f, %f, %f)\n", kk,
        D[pos], D[pos+1], D[pos+2],
        F[pos], F[pos+1], F[pos+2]);
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

  if(argc == 1)
    return unit_tests();

  return 0;
}


