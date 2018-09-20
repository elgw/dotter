/*
 * Simultaneous ML fitting of N 3D Gaussian kernels against a volumetric image
 * MATLAB interface in df_mlfitN.c
 *
 * TODO: 
 * - how to handle background, still as a constant over the
 * patch? 
 * - bg not handled yet.
 *
 */

#include <assert.h>
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>

#include <gsl/gsl_multimin.h>
#include <gsl/gsl_statistics.h>

#include "blit3.h"
#include "mlfit.h"

#ifndef verbose
#define verbose 1
#endif

// When low on bugs, uncomment the following lines for speed
// Try with valgrind and cmocka first ...
//
// replace gsl_vector_get(v,i) by v->data[i*v->stride]
// #define GSL_RANGE_CHECK_OFF

// Globals
uint32_t maxIterations = 5000;
double convCriteria = 1e-6;


// Headers
int    localizeDot(double *, size_t, double *,  double *);
int    localize(double *, size_t, size_t, size_t, double *, size_t, size_t, double *);
double matrix_get(double * , size_t, size_t, size_t, double *);
double my_f (const gsl_vector *, void *);
int    unit_tests(void);

// Optimization constants
typedef struct {
  double * V; // Volumetric image
  double * W; // Temporary space for model during iterations
  double * D; // dots, x,y,z, nphot, sigmax, sigmay, sigmaz
  size_t Vm, Vn, Vp;
  size_t Dm, Dn;
  double * bg;
} optParams;


double my_f (const gsl_vector *v, void *params)
  // The function to optimize. mlsimplex controls/varies the variables
  // in v. params are to set up the context
{

  optParams *p = (optParams *) params;

  // Size of volumetric image
  const size_t Vm = p->Vm; // Size of image
  const size_t Vn = p->Vn;
  const size_t Vp = p->Vp;
  const size_t Dn = p->Dn; // number of dots
  const size_t Dm = p->Dm;  // and number of features
  double * D = p->D;
  const double * restrict V = p->V; // Volumetric data to fit against
  double * W = p->W; // Pre allocated memory for the model
  double * bg = p->bg;


#if verbose > 0
  printf("-> my_f, %d dots\n", (int) Dn);
#endif

  // Get the other parameters ...  

  double photsum = 0;

  // Copy the cordinates and nphot at the current iteration to D
  for(size_t dd = 0; dd<Dn; dd++)
  {
#if verbose > 0
    printf("%lu: (%.1f %.1f %.1f) %.0f (%.1f %.1f %.1f)\n", dd, D[Dm*dd+0],D[Dm*dd+1], D[Dm*dd+2], D[Dm*dd+3], D[Dm*dd+4], D[Dm*dd+5], D[Dm*dd+6]);        
#endif
    D[Dm*dd+0] = gsl_vector_get(v, 4*dd+0); // x
    D[Dm*dd+1] = gsl_vector_get(v, 4*dd+1); // y
    D[Dm*dd+2] = gsl_vector_get(v, 4*dd+2); // z 
    D[Dm*dd+3] = gsl_vector_get(v, 4*dd+3); // nphot

#if verbose>0
    printf("%lu: xyz (%.1f %.1f %.1f) %.0f (%.1f %.1f %.1f)\n", dd, D[Dm*dd+0],D[Dm*dd+1], D[Dm*dd+2], D[Dm*dd+3], D[Dm*dd+4], D[Dm*dd+5], D[Dm*dd+6]);        
#endif
    if(D[Dm*dd+3]<0)
      return INFINITY;

    photsum = photsum + D[7*dd+3];
  }

#if verbose > 0
  printf("phosum of dot parameters: %f\n", photsum);
#endif

  // Copy background map to model
  memcpy(W, bg, sizeof(double)*Vm*Vn*Vp); 
  //  memset(W, 0, sizeof(double)*Vm*Vn*Vp); // W = 0;
  blit3g(W, Vm, Vn, Vp, D, Dn, mid_point,0);

  // set bg as well with blit3(g)
  for(size_t kk = 0; kk<Vn*Vm*Vp; kk++) {
    //W[kk]++;
  }

  double vmin = 10e99;
  double vmax = -10e99;
  double wmin = 10e99;
  double wmax = -10e99;
  double diffmax = 0;
  for(size_t kk = 0; kk<Vn*Vm*Vp; kk++)
  {
    vmin = GSL_MIN(vmin, V[kk]);
    vmax = GSL_MAX(vmax, V[kk]);
    wmin = GSL_MIN(wmin, W[kk]);
    wmax = GSL_MAX(wmax, W[kk]);
    diffmax = GSL_MAX(diffmax, fabs(V[kk]-W[kk]));
  }
#if verbose>0
  printf("V -- min: %f max %f\n", vmin, vmax);
  printf("W -- min: %f max %f\n", wmin, wmax);
  printf("diffmax: %f\n", diffmax);
#endif

  /* 
   * from LL2PG.m
   *   model = x(3)+x(4)*gaussianInt2([x(1), x(2)], x(5), (size(patch, 1)-1)/2);
   *   mask = disk2d((size(patch,1)-1)/2);
   *   %L = -sum(sum(-(patch-model).^2./model - .5*log(model)));
   *   L = -sum(sum(mask.*(-(patch-model).^2./model - .5*log(model))));
   */

  double E = 0;
  for (size_t kk=0; kk<Vm*Vn*Vp; kk++) {
    //E+= (V[kk]-W[kk])*(V[kk]-W[kk])/V[kk] - .5*log(W[kk]);
    E+= (V[kk]-W[kk])*(V[kk]-W[kk]);
  }
  //  E = -E;

  /* Quadratic
   * for (size_t kk=0; kk<Rw*Rw; kk++)
   * E+= (GI[kk]-R[kk])*(GI[kk]-R[kk]);
   */
#if verbose >0
  printf("E: %f\n", E);
#endif 
  return E;
} 
double matrix_get(double * V, size_t Vm, size_t Vn, size_t Vp, double * D)
  // Safely get V(D), i.e. check bounds. Returns 0 if outside
  //
{

  double x = D[0];
  double y = D[1];
  double z = D[2];

  if(x<0)
    return 0;
  if(x>Vm-1)
    return 0;
  if(y<0)
    return 0;
  if(y>Vn-1)
    return 0;
  if(z<0)
    return 0;
  if(z>Vp-1)
    return 1;

  size_t pos = (size_t) nearbyint(x) + nearbyint(y)*Vm +  nearbyint(z)*Vm*Vn; 
  assert(pos<Vm*Vn*Vp);
  return V[pos];
}

int localize(double * V, size_t Vm, size_t Vn, size_t Vp, 
    double * D, size_t Dm, size_t Dn, double * F)
  // Localization for a dot roughly centered in V of size Vm x Vm
  // D[0], D[1], D[3] are the global coordinates of the dot
  // F are the fitted coordinates
{

  // avoid crashing matlab
  gsl_set_error_handler_off();

#if verbose > 0
  printf("-> Localize\n");
  printf("V: %lu %lu %lu\n", Vm, Vn, Vp);
  printf("D: %lu %lu\n", Dm, Dn);
#endif
  assert(Dm == 7); // x y z nphot sigmax sigmay sigmaz

  // Non-optimized parameters
  optParams par;
  par.V = V;
  par.Vm = Vm;
  par.Vn = Vn;
  par.Vp = Vp;
  par.Dn = Dn;
  par.Dm = Dm;
  par.W = malloc(Vm*Vn*Vp*sizeof(double));
  assert(par.W != NULL);
  par.D = D;
  par.bg = malloc(Vm*Vn*Vp*sizeof(double));

#if verbose > 0
  printf("Estimating local background\n");
#endif
  // Estimating a constant from the surroundings of the first dot
  // printf("Vm: %lu %Vn: %lu Vp: %lu, D: %f %f %f\n", Vm, Vn, Vp, D[0], D[1], D[2]);
  double bg = estimateBGV(V, Vm, Vn, Vp, D);
#if verbose>0
  printf("Background estimated to %f\n", bg);
#endif
  printf("Background estimated to %f\n", bg);

  for(size_t kk=0; kk<Vm*Vn*Vp; kk++)
    par.bg[kk] = bg;

  const gsl_multimin_fminimizer_type *T = 
    gsl_multimin_fminimizer_nmsimplex2;
  gsl_multimin_fminimizer *s = NULL;
  gsl_vector *ss, *x;
  gsl_multimin_function minex_func;

  size_t iter = 0;
  int status;
  double size;

  /* Starting point */
#if verbose > 0
  printf("Setting up starting vector\n");
#endif 
  const int nf = 4; // # of features to be optimized: x, y, z, nphot
  int nParameters = nf*Dn;
  x = gsl_vector_alloc (nParameters);
  for(size_t dd = 0; dd<Dn; dd++)
  {
    gsl_vector_set(x, dd*nf+0, D[dd*Dm+0]); // x position
    gsl_vector_set(x, dd*nf+1, D[dd*Dm+1]); // y position
    gsl_vector_set(x, dd*nf+2, D[dd*Dm+2]); // z position
    
    // number of photons
    // Since the blitting is scaled by the central pixel, the number
    // of photons can be estimated as the central value of each peak -
    // background from the surrounding
    double nphot = gsl_max(0, matrix_get(V, Vm, Vn, Vp, D+ dd*Dm)-par.bg[0]); 
    printf("nphot: %f\n", nphot);
    gsl_vector_set(x, dd*nf+3, nphot); 
  }
#if verbose > 0
  printf("Setting up initial step sizes\n");
#endif
  /* Set initial step sizes */
  ss = gsl_vector_alloc(nParameters);
  gsl_vector_set_all(ss, 0.01);
  for(size_t dd = 0; dd<Dn; dd++)
  {
    gsl_vector_set(ss, dd*nf+3, 5); // Number of photons
  }

#if verbose > 0
  printf("Testing the fitting with the initial data\n");
#endif
  my_f(x,(void*) &par);

  /* Initialize method and iterate */
  minex_func.n = nParameters;
  minex_func.f = my_f;
  minex_func.params = &par;
#if verbose > 0
  printf("Allocating for the solver\n");
#endif
  s = gsl_multimin_fminimizer_alloc (T, nParameters);
#if verbose > 0
  printf("Initializing solver\n");
#endif
  gsl_multimin_fminimizer_set (s, &minex_func, x, ss);

  do
  {
    iter++;
#if verbose>0
    printf("----------------------------- Iteration: %lu\n", iter);
#endif
    status = gsl_multimin_fminimizer_iterate(s);

    if (status) 
      break;

    size = gsl_multimin_fminimizer_size(s);
    status = gsl_multimin_test_size(size, convCriteria);

    if (status == GSL_SUCCESS)
    {
#if verbose > 0
      printf ("converged to minimum at\n");
      printf ("%5lu x:%10.3e y:%10.3e z:%10.3e NP:%6.1f f() = %7.3f size = %10.3e\n", 
          iter,
          gsl_vector_get (s->x, 0), 
          gsl_vector_get (s->x, 1), 
          gsl_vector_get (s->x, 2), 
          gsl_vector_get (s->x, 3), 
          s->fval, size);
#endif
    }
  }
  while (status == GSL_CONTINUE && iter < maxIterations);

  for(size_t dd = 0; dd<Dn; dd++)
  {
    F[5*dd+0] = gsl_vector_get (s->x, nf*dd+0); // x
    F[5*dd+1] = gsl_vector_get (s->x, nf*dd+1); // y
    F[5*dd+2] = gsl_vector_get (s->x, nf*dd+2); // z
    F[5*dd+3] = gsl_vector_get (s->x, nf*dd+3); // nphot
    F[5*dd+4] = status;                            // status
  }

  gsl_vector_free(x);
  gsl_vector_free(ss);
  gsl_multimin_fminimizer_free (s);

  free(par.W);
  free(par.bg);
  return status;
}

#ifndef _MAIN
#define _MAIN
int unit_tests(){
  double * V; // image
  int Vm = 102; int Vn = 107; int Vp = 60;
  double * D; // list of dots
  size_t Dm = 7; // number of features of the dots
  size_t Dn = 10; // number of dots
  double * F; // fitted dots

  printf("Image size: %dx%dx%d\n", Vm, Vn, Vp);
  printf("Localizing %lu dots\n", Dn);

  V = malloc(Vm*Vn*Vp*sizeof(double));
  D = malloc(Dm*Dn*sizeof(double));
  F = malloc(5*Dn*sizeof(double));

  // Initialize the data
  for(int kk=0; kk<Vm*Vn*Vp; kk++)
    V[kk] = rand_range(2,9);

  for(uint32_t kk=0; kk<Dn; kk++)
  {
    size_t pos = kk*Dm;
    D[pos] =   rand_range(6, Vm-7); 
    D[pos+1] = rand_range(6, Vn-7); 
    D[pos+2] = rand_range(6, Vp-7);
    D[pos+3] = 1000;
    D[pos+4] = 1.2;
    D[pos+5] = 1.2;
    D[pos+6] = 1.4;

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

  for(uint32_t kk=0; kk<Dn; kk++)
  {
    size_t pos = nearbyint(D[kk*7]) + nearbyint(D[kk*7+1])*Vm + nearbyint(D[kk*7+2])*Vm*Vn;
    assert(pos<(size_t) Vm*Vn*Vp);
    assert(pos>0);
    V[pos] = 5;
  }

  // Run the optimization
  localize(V, Vm, Vn, Vp, D, Dm, Dn, F);

  // In next version, also supply clustering information

#if verbose >0
  for(size_t kk = 0; kk<Dm; kk++)
  {
    size_t Dpos = kk*7;
    size_t Fpos = kk*5;
    printf("%6lu (%f, %f, %f) -> (%f, %f, %f)\n", kk,
        D[Dpos], D[Dpos+1], D[Dpos+2],
        F[Fpos], F[Fpos+1], F[Fpos+2]);
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
#endif

