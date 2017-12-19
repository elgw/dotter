#include <stdlib.h>
#include <stdio.h>
#include <math.h>

/*

Just playing around with arrays/vectors and function pointers.
Implements some basic functionality which is otherwise found in
MATLAB.

To make this a little more elegant we could
- Define a struct for an array which includes the number of elements
- Have a routine to free all allocated vectors and another one to
  deallocate specific ones.

*/

double * linspace(double min, double max, int steps)
{
// Create a new vector 
 double * x = malloc(steps * sizeof(double));

for(int kk = 0; kk<steps; kk++)
  x[kk] = kk*(max-min)/(steps-1)+min;
return x;
}

void printv(double * x, int N)
{
// Print the components of x
for(int kk = 0; kk<N; kk++)
  printf("%f ", x[kk]);
printf("\n\n");
}

double * vcopy(double *x, int N)
{
// Copy vector x into new vector which is returned
  double * z= malloc(N*sizeof(double));
for(int kk = 0; kk<N; kk++)
  z[kk] = x[kk];
return z;
}

void vcalc(double * x, double  fun(double), int N)
{
// Apply fun to each element of x
for(int kk = 0; kk<N; kk++)
  x[kk] = fun(x[kk]);
}

void vcalc2(double *x, double fun(double, double), double y, int N) {
// Apply fun to each element of x
for(int kk = 0; kk<N; kk++)
  x[kk] = fun(x[kk], y);
}



double sinc(double x ){
// sinc = sinx/x
if(fabs(x)>0.0001)
{
  return sin(x)/x;
}
else {
return 1-x*x;
}
}

double dsinc(double x){
// d/dx sinc(x)
if(fabs(x)>0.0001) {
return (x*cos(x)-sin(x))/(x*x);
} else {
return -2*x;
}
}

double vdiv(double x, double y)
{ return x/y; }

double * vconv(double * x, int N, double * k, int K)
{
double * y = malloc(N*sizeof(double));

int w = (K-1)/2;

// Set edges to 0
for(int kk = 0; kk<w; kk++)
  y[kk] = 0;

for(int kk = N-w; kk<N; kk++)
  y[kk] = 0;

// Actual convolution
for(int kk = w; kk<N-w; kk++)
// For each position of the input vector
{
  int start = kk-w;

  int end = kk+w;
  double c = 0;
 int kpos = 0; 
  for (int ll = start; ll<= end; ll++){
    printf("(%d, %f)", ll, x[ll]);
    c+=x[ll]*k[kpos++];}
  printf(" : %f \n", c);
  y[kk] = c;
}
return y;
}

int main(void){

int N = 13;
double start = -0.1;
double end = 0.1;

double * x = linspace(start,end,N);
printf("linspace(%f, %f, %d)\n", start, end, N);
printv(x, N);

double * y = linspace(0,0,N);
double * z = vcopy(x, N);

vcalc(x, &sinc, N);
printf("sinc(x)\n");
printv(x, N);

// Define a convolution kernel
double *k = linspace(0,0,3);
k[0]=-1; k[2]=1;
printf("k\n");
printv(k, 3);

// Convolve
double * d = vconv(x, N, k, 3);
printf("[-1,0,1]*sinc(x)\n");
vcalc2(d, &vdiv, (end-start)/(N-1)*2, N);
printv(d, N);

vcalc(z, &dsinc, N);
printf("d/dx sinc(X)\n");
printv(z, N);


free(d);
free(y);
free(x);
free(z);
return 1;

}
