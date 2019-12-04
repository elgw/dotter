#include <stdlib.h>
#include "gsl.h" // the GNU Scientific Library
// https://www.gnu.org/software/gsl/manual/html_node/Multimin-Algorithms-without-Derivatives.html#Multimin-Algorithms-without-Derivatives
#include "gaussianInt2/gaussianInt2.c"

// Compilation: 

struct {
  double x, y, z;
  double sigma;
  double bg;
  double nphotons;
} fit_result;

typedef struct fit_result fit_result;

ml_nm(double * P, int * size, fit_result * fit)
{

  // P: image patch
  // size [M,N,P]
  // Output: fit


  gsl_multimin_fminimizer_nmsimplex();
  gaussianInt2()

    fit-> x = 0;
  fit -> y = 0;
  fit -> z = 0;
  fit -> sigma = 1;
  fit -> nphotons = 1;
}


