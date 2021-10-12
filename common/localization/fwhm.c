/* Not finished/used
  fwhm calculation for point in volumetric images
*/

#include <stdlib.h>
#include <stdio.h>
#include "lanczos1.c"
#include "imshift.c"

double * generateTestSignal(int N)
{
double * S = malloc(N*sizeof(double));
printf("Generating test data\n");
double centre = 4.25;
for (int kk = 0; kk<N; kk++)
{
S[kk] = 6-(kk-centre)*(kk-centre)*2;
printf("%f ", S[kk]);
}
printf("\n");
return S;
}


int fwhm(double * S, int N, double * width, double * centre, double *
left, double * right)
{

int verbose = 1;
// 1. Find approx centre
int cPos = -1;
double maxVal = -1;
for(int kk = 0; kk<N; kk++)
  {
    if(S[kk]>maxVal)
      {
        maxVal = S[kk];
        cPos = kk;
      }
  }

if(verbose)
  printf("cPos: %d\n", cPos);

// 2. Find exact centre, and max value
// 2.1 Calculate derivative of S

double * dS = malloc(N*sizeof(double));
for(int kk = 2; kk<N-2; kk++)
  dS[kk] =(0.2*S[kk+2] + 0.8*S[kk+1] - 0.8*S[kk-1]-0.2*S[kk-2])/2;

// 2.2 Get max location and value
double fZeroVal = -1;
int ok = fzero1(dS, N, 3, cPos-1, cPos+1, &fZeroVal);
if(!ok)
  return 0;

double maxValI = -1;
lanczos1(S, N, &fZeroVal, 1, 3, &maxValI);

if(verbose)
  printf("fZeroVal: %f\nmaxValI: %f\n", fZeroVal, maxValI);
centre[0] = fZeroVal;

// 3. Find min value
double minValue = S[0];
for(int kk = 0; kk<N; kk++)
  if(S[kk]<minValue)
    minValue=S[kk];

if(verbose)
  printf("minValue: %f\n", minValue);

// 4. Find L
double Left = -1;
ok = fzero1(S, N, 3, 0, fZeroVal-1, &Left);
if(!ok)
  return 0;
left[0] = Left;

// 5. Find R
double Right = -1;
ok = fzero1(S, N, 3, fZeroVal-1, N, &Right);
if(!ok)
  return 0;

right[0] = Right;

width[0] = (Right-Left);

return 1;
}

void linspace(double * X, double  min, double  max, int N)
{
// Set the values of X from min to max
  for(int kk = 0; kk<N; kk++)
    X[kk] = min + (double) kk/((double)N-1)*(max-min);
}

double * alinspace(double  min, double  max, int N)
{
// Set the values of X from min to max
double * X = malloc(N*sizeof(double));
  for(int kk = 0; kk<N; kk++)
    X[kk] = min + kk/(N-1)*(max-min);
return X;
}

int fwhm_volume(double * V, size_t Vm, size_t Vn, size_t Vp,
            double * D, size_t Dm, size_t Dn,
            double * F)
/**
V: volumetric image
D: list of dots, the first three columns used
F: array for FWHM.
*/
{

int Pn = 21; // Lenght of profiles to analyze
int PnW = (Pn-1)/2; // I.e. 2*PnW+1 = Pn
// Allocate for interpolation points
double * X = malloc(Pn*sizeof(double));
double * Y = malloc(Pn*sizeof(double));
double * Z = malloc(Pn*sizeof(double));
// Allocate for profile values
double * P = malloc(Pn*sizeof(double));


for(int kk = 0; kk<Dm; kk++)
{ // For each dot
  double x = D[kk];
  double y = D[kk+Dm];
  double z = D[kk+2*Dm];

  // A - Get fwhm in x
  // A.1 Get points to interpolate at
  linspace(X, x-PnW, x+PnW, Pn);
  linspace(Y, y, y, Pn);
  linspace(Z, z, z, Pn);
  linspace(P, 0,0,Pn);

  // A.2 Interpolate
 // lanczos3(V, Vm, Vn, Vp, X, Y, Z, P, Pn);
  // A.3 Call FWHM
  double width, centre, left, right;
  int ok = fwhm(P, Pn, &width, &centre, &left, &right);
  if(ok) {
    F[kk] = width;
    }
  else
  { F[kk] = -1; }
}
return 1;
}

int main(void){

int N = 11;
double * S = generateTestSignal(N);

double width; double centre; double left; double right;
int ok = fwhm(S, N, &width, &centre, &left, &right);
if(ok)
{
printf("Results from fwhm():\n");
printf("Widht: %f\nCentre: %f\nLeft: %f\nRight: %f\n", width, centre,
left, right);
} else {
printf("fwhm failed\n");
}

free(S);


size_t Vm = 10; size_t Vn = 1; size_t Vp =1;
double * V = malloc(Vm*Vn*Vp*sizeof(double));
double * V2 = malloc(Vm*Vn*Vp*sizeof(double));

linspace(V, 1, 10, Vm*Vn*Vp);
linspace(V2, 0, 0, Vm*Vn*Vp);
printv(V, 10);
imshift_x(V, V2,  Vm, Vn, Vp, .5);
printv(V2, 10);
free(V);
free(V2);
return 1;

}
