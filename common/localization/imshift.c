void printv(double * V, size_t N)
{
for(int kk = 0; kk<N; kk++)
  printf("%f ", V[kk]);
printf("\n");
}


void imshift_x(double * V, double * V2, 
               size_t Vm, size_t Vn, size_t Vp, 
               double shift)
/**
Shift V by shift in dimension x.
fabs(shift) <= .5

Note: 
- Shifting with linear filters is nothing but a convolution. Then this
  function should use a convolution function defined somewhere else
(DRY). Is it the same for cubic/lanczos interpolation?

Todo: 
  Implement more filters
  Let the dimension to filter along be a parameter.
  
*/
{
int debug = 1;
int filter = 3;

// F Design the fixed filter
int Fn = 7; // Filter length
int Fn2 = (Fn-1)/2;
double * F = malloc(Fn*sizeof(double));

// F.1 A linear filter:
if(filter == 1)
{
for(int kk = 0; kk<Fn; kk++)
  {
    F[kk] = 1-fabs( ((double) kk- (double) Fn2)-shift);
    if(F[kk]<0)
      F[kk] = 0;
  }
}
// F.2 Cubic, ...

// F.3 Lanczos
if(filter == 3)
{
double a = 2;
  double norm = 0;

for(int kk = 0; kk<Fn; kk++)
{
  double pos = ((double) Fn2-(double) kk)+shift;
  printf("%f - ", pos);
  if(fabs(pos)<a){
    F[kk] = sinc(PI*pos)*sinc(PI*pos/a);
    printf("%f\n", F[kk]);
    norm+=F[kk];
    //norm = 1;
} else {
F[kk]=0;
}
}

for(int kk = 0; kk<Fn; kk++)
  F[kk] = F[kk]/norm;
}

printf("\n");
if(debug)
  printv(F, Fn);

// S. Shift.

// S.1 If X-dimension

// For all start positions
for(int yy=0; yy<Vn; yy++)
  for(int zz=0; zz<Vp; zz++)
    {
      size_t start = yy*Vm+zz*Vm*Vn;
      for(int xx = start+Fn2; (start+xx)<(Vm-Fn2); xx++) 
      {
        double v = 0;
        for(int ll = 0; ll<Fn; ll++)
          v+= V[xx+ll-Fn2]*F[ll];
        V2[xx] = v;
      }
    }

// Cleanup
free(F);
}

