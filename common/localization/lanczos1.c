/* Lanczos interpolation of a 1D signal (double) at a point within
 * bounds. */

#include <math.h>
#include <stdlib.h>

#define PI 3.141592653589793238462643383279502884197
 
double sinc(double x)
{
/* Inspired by the boost lib */

   double const taylor_0_bound =  1e-16;
   double const taylor_2_bound = sqrt(taylor_0_bound);
   double const taylor_n_bound = sqrt(taylor_2_bound);
  
  if    (fabs(x) >= taylor_n_bound)
    {
      return(sin(x)/x);
    }
  else
    {
      printf(".");
      // approximation by taylor series in x at 0 up to order 0
      double result = 1;
     if    (fabs(x) >= taylor_0_bound)
       {
	 double x2 = x*x;
	 // approximation by taylor series in x at 0 up to order 2
	 result -= x2/6;
	 
	 if    (fabs(x) >= taylor_2_bound)
	   {
	     // approximation by taylor series in x at 0 up to order 4
	     result += x2*x2/120;
	   }
       }     
     return(result);
    }
}

double dsinc(double x)
{
// Derivative of sinc
   double const taylor_0_bound = 1e-16;
   double const taylor_2_bound = sqrt(taylor_0_bound);
   double const taylor_n_bound = sqrt(taylor_2_bound);
  
  if    (fabs(x) >= taylor_n_bound)
    {
      return( (x*cos(x)-sin(x))/(x*x));
    }
  else
    {
      printf("+");

	     return -x/3+x*x*x/30;
    }
}


void lanczos1(double * S, size_t N, double * X, size_t K, int a, double * Y)
{
// Input:
// S: 1D signal, evenly distributed
// N: number of elements in D 
// x: interpolation points
// a: size of interpolation kernel
// K: number of interpolation points
// 
// Output: Y(x), same size as X


for(int kk = 0; kk < K; kk++)
{ 

// For each interpolation point
double x = X[kk];

        long int iStart = round(x)-a;
        long int iEnd = round(x)+a;
        if(iStart<0)
          iStart = 0;
        if (iEnd>=N)
          iEnd = N-1;

	 double w = 0;
        double y = 0;

	 for( int ff=iStart; ff<=iEnd; ff++)
	   { // For each sample point
	     double v = S[ff]; // value at that point
	     double r = x-ff; // offset from interpolation point
	     //	     printf("v: %f r: %f\n", v, r);
	       {
		 double kw = sinc(PI*r)*sinc(PI*r/a);
		 y += v*kw;
		 w+=kw;
                }
	   }
      if(w>0) {
	 Y[kk]=y; //y/w; 
}
      else {Y[kk] = 0; }
	 //	 printf("\n");	
       }
}
void lanczos1_d(double * S, size_t N, double * X, size_t K, int a, double * Y)
{
// Input:
// S: 1D signal, evenly distributed
// N: number of elements in D 
// x: interpolation points
// a: size of interpolation kernel
// K: number of interpolation points
// 
// Output: Y(x), same size as X


for(int kk = 0; kk < K; kk++)
{ 

// For each interpolation point
double x = X[kk];

        long int iStart = round(x)-a;
        long int iEnd = round(x)+a;
        if(iStart<0)
          iStart = 0;
        if (iEnd>=N)
          iEnd = N-1;

	 double w = 0;
        double y = 0;

	 for( int ff=iStart; ff<=iEnd; ff++)
	   { // For each sample point
	     double v = S[ff]; // value at that point
	     double r = x-ff; // offset from interpolation point
	     //	     printf("v: %f r: %f\n", v, r);
	       {
		  double kw  =  sinc(PI*r)*sinc(PI*r/a);
                  double kwd = dsinc(PI*r)*sinc(PI*r/a);
 
		 y += v*kwd;
		 w+=kw;
                }
	   }
      if(w>0) {
	 Y[kk]=y;///w; 
}
      else {Y[kk] = 0; }
	 //	 printf("\n");	
       }
}
int fzero1_d(double * S, size_t N, int a, double L, double R, double * Y)
{
// Look for ONE zero crossing between S(a) and S(b), return -1 on
// error.
// Input: 
// S: signal with size N
// a: order of lanczos interpolation
// Y: location of the zero (if return value is 1);

double Lv;
double Rv;
double Cv;
double C = (R+L)/2;

lanczos1_d(S, N, &L, 1, a, &Lv);
lanczos1_d(S, N, &R, 1, a, &Rv);
printf("Lv(%f): %f, Rv(%f): %f\n", L, Lv, R, Rv);
if(Lv*Rv>0)
  return -1;

while(fabs(L-R)>0.0001)
{
printf("[%f, %f] : %f:%f (delta: %f)\n", L, R, Lv, Rv, R-L);

lanczos1_d(S, N, &C, 1, a, &Cv);

int nOk = 0;

if(Lv*Cv<0)
{
R = C;
Rv = Cv;
C = (R+L)/2;
nOk++;
}

if(Cv*Rv<0)
{
L = C;
Lv = Cv;
C = (R+L)/2;
nOk++;
}

if (nOk != 1)
  return -1;
}

Y[0] = (L+R)/2;
return 1;
}


int fzero1(double * S, size_t N, int a, double L, double R, double * Y)
{
// Look for ONE zero crossing between S(a) and S(b), return -1 on
// error.
// Input: 
// S: signal with size N
// a: order of lanczos interpolation
// Y: location of the zero (if return value is 1);

double Lv;
double Rv;
double Cv;
double C = (R+L)/2;

lanczos1(S, N, &L, 1, a, &Lv);
lanczos1(S, N, &R, 1, a, &Rv);

if(Lv*Rv>0)
  return -1;

while(fabs(L-R)>0.0001)
{
printf("[%f, %f] : %f:%f (delta: %f)\n", L, R, Lv, Rv, R-L);

lanczos1(S, N, &C, 1, a, &Cv);

int nOk = 0;

if(Lv*Cv<0)
{
R = C;
Rv = Cv;
C = (R+L)/2;
nOk++;
}

if(Cv*Rv<0)
{
L = C;
Lv = Cv;
C = (R+L)/2;
nOk++;
}

if (nOk != 1)
  return -1;
}

Y[0] = (L+R)/2;
return 1;
}

int fminsearch1(double * S, size_t N, int a, double L, double R, double * Y)
{
// Look for the min value between S(a) and S(b), return -1 on
// error.
// Input: 
// S: signal with size N
// a: order of lanczos interpolation
// Y: location of the min;

// Method: Nelder-Mead simplex method?

return 1;
}

