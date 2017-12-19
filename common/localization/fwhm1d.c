#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <gsl/gsl_errno.h> 
#include <gsl/gsl_interp.h>
#include <gsl/gsl_min.h>
#include <gsl/gsl_roots.h>
#include <gsl/gsl_spline.h>

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

FILE * log;

// my_f and my_f_params defines the interpolation function that the
// root-finding functions are run on

struct my_f_params {
    gsl_spline * spline;
    gsl_interp_accel * acc;
    double  offset; // shifts the function
    };

double my_f(double x, void * p)
{
  struct my_f_params * params = (struct my_f_params*) p;
#if verbose > 0
  printf("f(%f) + %f=  ", x, params->offset);
#endif

  double y =  -gsl_spline_eval(params->spline, x, params->acc) + params->offset;
#if verbose > 0
  printf("%f\n", y);
#endif

  return(y);
}

int findmin(double a, double b, gsl_spline *spline, gsl_interp_accel * acc, size_t N, double * xm, double * ym)
{

// a, b: range of function
  int iter = 0, max_iter = 100; 
  double m = 0; // expected location of minima

  int status;  
  const gsl_min_fminimizer_type *T; 
  gsl_min_fminimizer *s;

  struct my_f_params f_params;
  f_params.spline = spline;
  f_params.acc = acc;
  f_params.offset = 0;
  
  gsl_function F;
F.function = &my_f;
F.params = (void *) &f_params;

T = gsl_min_fminimizer_brent;
s = gsl_min_fminimizer_alloc (T); gsl_min_fminimizer_set (s, &F, m, a, b);

#if verbose > 0
double m_expected = -10; 
printf ("using %s method\n", gsl_min_fminimizer_name (s));
printf ("%5s [%9s, %9s] %9s %10s %9s\n", "iter", "lower", "upper", "min", "err", "err(est)");
printf ("%5d [%.7f, %.7f] %.7f %+.7f %.7f\n", iter, a, b, m, m - m_expected, b - a); 
#endif

    do {
iter++;
status = gsl_min_fminimizer_iterate (s);

a = gsl_min_fminimizer_x_lower (s);
b = gsl_min_fminimizer_x_upper (s);

status = gsl_min_test_interval (a, b, 0.001, 0.0);

#if verbose > 0
float m = gsl_min_fminimizer_x_minimum (s); 
if (status == GSL_SUCCESS) {
  printf ("Converged:\n");
} else { printf("No convergence %d\n", status); }

printf ("%5d [%.7f, %.7f] " "%.7f %+.7f %.7f\n", iter, a, b, m, m - m_expected, b - a);
#endif

} while (status == GSL_CONTINUE && iter < max_iter);

xm[0] = (a+b)/2;
ym[0] = my_f(xm[0], &f_params);

gsl_min_fminimizer_free(s);

#if verbose > 0
printf("Status: %d\n", status);
#endif 

return status;
     }



int fwhm(double * x, double * y, size_t N, double * w)
  {

    int useLog = 1;

    if(useLog)
      LOG = fopen("/tmp/fwhmlog", "w");


gsl_set_error_handler_off ();

int N2 = (N-1)/2; // even number

// Set up interpolation
gsl_interp_accel *acc = gsl_interp_accel_alloc();  // Neccessary?
gsl_spline *spline = gsl_spline_alloc (gsl_interp_cspline, N);
gsl_spline_init(spline, x, y, N);

// See that the correct value is given at x=0
#if verbose > 0
printf("y[%f] = %f\n", x[N2], gsl_spline_eval(spline, x[N2], acc));
#endif

// Find position of max, i.e., centre in [xmin, xmax]
double xmin = -1.5;
double xmax = 1.5;

double xm = 10e99;
double ym = 10e99;
if( findmin(xmin, xmax, spline, acc, N, &xm, &ym) )
{
#if verbose > 0
  printf("Could not find the position of the maxima!\n");
#endif
  gsl_spline_free (spline);
  gsl_interp_accel_free (acc);

  
  if(useLog)
    fclose(LOG);
  return 1;
}

if(useLog)
  fprintf(LOG, "xm: %f, ym: %f\n", xm, ym);

#if verbose > 0
printf("Minima: f(%f) = %f\n", xm, ym);
#endif 

// Determine background
double bg = (y[0]+y[N])/2;
#if verbose > 0
printf("Background level: %f\n", bg);
#endif

// Find intersection .5*(max-bg) for each side
// ROOT FINDING

const gsl_root_fsolver_type * Tsolve = gsl_root_fsolver_bisection;
gsl_root_fsolver * rsolve = gsl_root_fsolver_alloc(Tsolve);

// Search for left and right intersections

double intersections[2];
intersections[0] = 0; intersections[1] = 0;

for(int dire = 0; dire<2; dire++)
{
// Search in range [x_lo, x_hi] 
double x_lo;
double x_hi;

if(dire==0)
{
  x_lo = -N2;
  x_hi = xm;
}

if(dire==1)
{
  x_lo = xm;
  x_hi = N2;
}

struct my_f_params f_params;
f_params.spline = spline;
f_params.acc = acc;
f_params.offset = -(bg+(ym+bg)/2);
 
gsl_function F;
F.function = &my_f;
F.params = (void *) &f_params;

/* 
 * Function: int gsl_root_fsolver_set (gsl_root_fsolver * s, gsl_function * f, double x_lower, double x_upper)
 * This function initializes, or reinitializes, an existing solver s to use the function f and the initial 
 * search interval [x_lower, x_upper]
 */

int status =  gsl_root_fsolver_set(rsolve, &F, x_lo, x_hi);

  size_t iter = 0;
  size_t max_iter = 10;

#if verbose > 0
  double r_expected = (x_lo+x_hi)/2;
printf ("using %s method\n", gsl_root_fsolver_name (rsolve));
printf ("%5s [%9s, %9s] %9s %10s %9s\n", "iter", "lower", "upper", "root", "err", "err(est)");
#endif

do {
iter++;
status = gsl_root_fsolver_iterate (rsolve);
// update bounds
x_lo = gsl_root_fsolver_x_lower (rsolve);
x_hi = gsl_root_fsolver_x_upper (rsolve);
// see if converged
status = gsl_root_test_interval (x_lo, x_hi, 0, 0.001);
#if verbose > 0
double r = gsl_root_fsolver_root (rsolve); 
if (status == GSL_SUCCESS)
  printf ("Converged:\n");
printf ("%5lu [%.7f, %.7f] %.7f %+.7f %.7f\n", iter, x_lo, x_hi,
        r, r - r_expected,
        x_hi - x_lo);
#endif
}
while (status == GSL_CONTINUE && iter < max_iter); 
#if verbose > 0
printf("Found intersection at %f\n", (x_lo+x_hi)/2);
#endif
intersections[dire] = (x_lo+x_hi)/2;
}

gsl_root_fsolver_free(rsolve);

// Clean up
gsl_spline_free (spline);
gsl_interp_accel_free (acc);

// fwhm: right-left positions
w[0] = intersections[1] - intersections[0];

if(useLog)
  fclose(LOG);

return 0; // Ok

  }

void createGaussian(double * x, double * y, size_t N, double x0)
{
  int N2 = (N-1)/2; // middle element

  for(int kk=0; kk<N; kk++)
  {
    double p = 2*((double) kk - N2)/N; // [-1,1];
    p = p*3;
    y[kk] =  exp(-p*p);
    x[kk] = kk-N2; // Set x to pixel position from centre
#if verbose>0
    printf("%f %f\n", x[kk], y[kk]);
#endif
  }
}


int main(int argc, char ** argv)
{

  int N = 11; // Size of test signal

  double * y = malloc(N*sizeof(double));
  double * x = malloc(N*sizeof(double));

  createGaussian(x,y, N, 0);

  double w = -1; // output

  if(fwhm(x, y, N, &w))
  {
    printf("# Error!\n");
    free(y);
    return(1);
  }

  printf("# fwhm: %f pixels\n", w);

  free(y);
  return(0);

}
