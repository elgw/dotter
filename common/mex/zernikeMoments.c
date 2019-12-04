#include "mex.h"
#include "string.h"
#include "math.h"
#include "matrix.h" // for mxAssert
#include "assert.h"

/* Generates Zernike moments 

@ Usage:
zernikeMoments(N, n, m)
N: size of ouput, N*2+1
n: radial degree
m: azimuthal degree
n and m can be vectorial
zernikeMoments(N, nn)
nn: number of bases (Noll index)

@ Compilation:
mex CFLAGS='$CFLAGS -std=c99 -Wall -O3' zernikeMoments.c

@ To do:
- See how high orders that can be generated without overflow, possibly
change data types where necessary.
- Allocate memory for the coefficients?

*/


// Sets the limit on the number of non-zero coefficients
#define max_nc 100

  typedef struct {
    int coeff[max_nc];
    int nc;
    } rstruct;


long factorial(int n)
{
 int c;
  long result = 1;
 
  for (c = 1; c <= n; c++)
    result = result * c;
 
  return result;
}

rstruct initR(int n, int m)
{
  rstruct rs;
 
  for(int kk=0; kk<max_nc; kk++)
    rs.coeff[kk]=0;

    for(int k =0; k<=(n-m)/2; k++)
      {
      assert(n-2*k<max_nc);      
      rs.coeff[n-2*k] += pow(-1,k)*factorial(n-k)/(
          factorial(k)*factorial( (n+m)/2-k)*factorial( (n-m)/2-k));
      }

    // Find the last index with non-zero coefficient
    for(int kk=0; kk<max_nc; kk++)
      if(rs.coeff[kk]>0)
        rs.nc = kk+1;

    if(0) // Debug: show the coefficients
    {
      for(int kk=0; kk<rs.nc; kk++)
         printf("%d ", rs.coeff[kk]);
    printf("\n");
    }

  return rs;
}

double R(rstruct rs, double d)
{

  double r = 0;

  double dp = 1; // d^p, initially the power, p=0;
  for(int kk = 0; kk<rs.nc; kk++)
  {
   // printf("kk %d coeff %d dp %f\n", kk,  rs.coeff[kk], dp);
    r+=dp*rs.coeff[kk]; // construct the polynomial
    dp*=d; // rise dp with one power
  }

  return r;
}
 
void zernikeMoment(double * Z, int N, int n, int m)
{

int w = 2*N+1; // width of output image
int R2 = N*N; // radius squared
 
rstruct rs = initR(n, abs(m)); // Initialize the polynomial R for n and m

for(int xx=0; xx<w; xx++)
  for(int yy =0; yy<w; yy++)
    {
      int xc = xx-N; // image coordinate x
      int yc = yy-N;
      double d2 = xc*xc+yc*yc;
      double dn = sqrt(d2)/(N+1); // normalized distance in [0,1] on the disk 
      if(d2 > R2)
        { Z[xx+w*yy]=0; } 
      else
        {
          double theta = atan2(xc, yc);
          if(m>=0)
            { Z[xx+w*yy]=cos(m*theta)*R(rs, dn); } 
          else
            { Z[xx+w*yy]=sin(m*theta)*R(rs, dn); }
        }
    }
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray
*prhs[])
{

if( ! mxIsDouble(prhs[0]))
 { mexErrMsgTxt("Check the data type of the input arguments."); }

if( ! mxIsDouble(prhs[1]))
 { mexErrMsgTxt("Check the data type of the input arguments."); }

if( ! mxIsDouble(prhs[2]))
 { mexErrMsgTxt("Check the data type of the input arguments."); }

if(!(nrhs == 3 || nrhs ==2))
  { mexErrMsgTxt("Requires two or three input arguments"); }

  double * N = mxGetPr(prhs[0]);
  double * n = mxGetPr(prhs[1]);
  double * m = mxGetPr(prhs[2]);
  
  int w = 2*N[0]+1;
  int ut_dim[]={ w, w, 0};

    
  plhs[0] = mxCreateNumericArray(2, ut_dim, mxDOUBLE_CLASS, mxREAL);  
  double * Z = (double *) mxGetPr(plhs[0]); 

if(nrhs == 3)
{
  mxAssert(n>=m, "n>=m not satisfied");
  zernikeMoment(Z, (int) N[0], (int) n[0], (int) m[0]); 
}

if(nrhs == 2)
  mexErrMsgTxt("Not implemented"); 

}
