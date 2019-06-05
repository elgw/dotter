#include <assert.h>
#include <math.h>
#include <stdlib.h>
#include <stdio.h>
#include <stdint.h>
#include <string.h>

#include <gsl/gsl_math.h>

#include "gaussianInt2.h"
#include "blit3.h"

#ifndef verbose
#define verbose 1
#endif

double rand_range(double A, double B)
  // A random number between A and B
{
  if(A==B)
    return A;
  if(B>A)
    return A + (double) rand() / RAND_MAX * (B-A);
  //if(A>B)
  return B + (double) rand() / RAND_MAX * (A-B);
}

int blit3g(double * T, uint32_t Tm, uint32_t Tn, uint32_t Tp,
    double * D, size_t nD, photonw pw, int one_indexing)
  // T:  target volume
  // nD: number of dots
  // D:  list of dots (x,y,z, nphot, sigmax, sigmay, sigmaz)
{
  
  const int nF = 7; // stride for D

  double sigma_max = -1;
  for(size_t kk = 0; kk < nD; kk++)
    {
      for(int ll = 0; ll < 3; ll++)
      {
      if( D[nF*kk+4 + ll] > sigma_max)
        sigma_max = D[nF*kk+4 + ll];
      }
    }

  const size_t w = ceil(sigma_max)*3*2 + 1;
  const int hw = (w-1)/2;
  // allocate temporary space for the Gaussian
  double * G = malloc(w*w*w*sizeof(double));    

  double sigma[] = {1.6,1.6,2.1};
  double mu[] = {0,0,0};
  double nPhot;

  for(uint32_t pp = 0; pp<nD; pp++)  {

    // Round the location
    int64_t Pm =(int64_t) (D[nF*pp+0]-.5);
    int64_t Pn =(int64_t) (D[nF*pp+1]-.5); 
    int64_t Pp =(int64_t) (D[nF*pp+2]-.5); 

    //    printf("%lu %lu %lu\n", Pm,Pn,Pp);

    // Get the offset from the centre of the pixel
    mu[0] = -roundf(D[nF*pp+0])+D[nF*pp+0];
    mu[1] = -roundf(D[nF*pp+1])+D[nF*pp+1];
    mu[2] = -roundf(D[nF*pp+2])+D[nF*pp+2];

    //    printf("%f %f %f\n", mu[0], mu[1], mu[1]);

    //   printf("mu: %f %f %f\n", mu[0], mu[1], mu[2]);
    sigma[0] = D[nF*pp+4];
    sigma[1] = D[nF*pp+5];
    sigma[2] = D[nF*pp+6];    

    nPhot = D[nF*pp+3];
    // Create the kernel
    if(!gaussianInt3(G, mu,  sigma, w))
    {
      printf("Failed to allocate space for Gaussian kernel\n");
      return 1;
    }

    if(pw == xyz_volume)
      for(size_t tt =0; tt<w*w*w; tt++)
        G[tt] = G[tt]*nPhot;

    if(pw == xy_plane)
    {
      double wgt = 0;
      for(size_t tt =0; tt<w*w; tt++)
        wgt += G[tt+w*w*(w-1)/2];

      for(size_t tt =0; tt<w*w*w; tt++)
        G[tt] = G[tt]*nPhot/wgt;
    }

    if(pw == mid_point)
    {
      const double wgt = G[(w*w*w-1)/2];
      for(size_t tt =0; tt<w*w*w; tt++)
        G[tt] = G[tt]*nPhot/wgt;
    }

    // blit it
    if(one_indexing){
      blit3(T, Tm, Tn, Tp, 
          G, w, w, w,
          Pm-hw, Pn-hw, Pp-hw, 
          0);
    } else {
blit3(T, Tm, Tn, Tp, 
          G, w, w, w,
          Pm-hw+1, Pn-hw+1, Pp-hw+1, 
          0);
    }

  }
  free(G);
  return 0;
}

void blit3(double * T, uint32_t Tm, uint32_t Tn, uint32_t Tp,
    double * S, uint32_t Sm, uint32_t Sn, uint32_t Sp,
    int64_t Pm, int64_t Pn, int64_t Pp,
    int8_t anchor)
  // T: target image
{
  // anchor, 0=corner, 1=center of S
  assert(anchor == 0);
  // Which ranges in T to be visited
  // in [Pma, Pmb]
  uint32_t Tma = GSL_MAX(0, Pm);
  uint32_t Tmb = GSL_MIN(Tm-1, Pm+Sm-1);
  uint32_t Tna = GSL_MAX(0, Pn);
  uint32_t Tnb = GSL_MIN(Tn-1, Pn+Sn-1);
  uint32_t Tpa = GSL_MAX(0, Pp);
  uint32_t Tpb = GSL_MIN(Tp-1, Pp+Sp-1);

  uint32_t Sma = 0;
  if(Pm<0)
    Sma = -Pm;

  uint32_t Sna = 0;
  if(Pn<0)
    Sna = -Pn;

  uint32_t Spa = 0;
  if(Pp<0)
    Spa = -Pp;

#if verbose > 0

  uint32_t Smb = GSL_MIN(Sm-1, Tm-Pm-1);
  uint32_t Snb = GSL_MIN(Sn-1, Tn-Pn-1);
  uint32_t Spb = GSL_MIN(((int64_t) Sp)-1, Tp-Pp-1);
  printf("Size of T: %u x %u x %u\n", Tm, Tn, Tp);
  printf("Size of S: %u x %u x %u\n", Sm, Sn, Sp);
  printf("P: %ld %ld %ld\n", Pm, Pn, Pp);
  printf("Will visit:\n");
  printf("T: [%u %u]x[%u %u]x[%u %u] (%u)\n", Tma, Tmb, Tna, Tnb, Tpa, Tpb, (Tmb-Tma+1)*(Tnb-Tna+1)*(Tpb-Tpa+1));
  printf("S: [%u %u]x[%u %u]x[%u %u] (%u)\n", Sma, Smb, Sna, Snb, Spa, Spb, (Smb-Sma+1)*(Snb-Sna+1)*(Spb-Spa+1));
#endif

  uint32_t ppos, npos; // For pre-caluclation of multiplications

  uint32_t smm=Sma, snn=Sna, spp=Spa;

  for(uint32_t pp = Tpa; pp<=Tpb; pp++, spp++) {
    snn = Sna;

    ppos = pp*Tm*Tn;
    for(uint32_t nn = Tna; nn<=Tnb; nn++, snn++) {
      npos = nn*Tm;
      smm = Sma;

      for(uint32_t mm = Tma; mm<=Tmb; mm++, smm++) {
#if verbose > 1
        printf("T(%u %u %u) := S(%u %u %u)\n", mm, nn, pp, smm, snn, spp);
#endif
        T[mm + npos + ppos] += S[smm + snn*Sm + spp*Sm*Sn];

      }
    }
  }


}

#ifdef standalone
int unit_tests()
{
  printf("Testing \n");
  uint32_t Tm = 10;
  uint32_t Tn = 11;
  uint32_t Tp = 12;

  double * T = malloc(Tm*Tn*Tp*sizeof(double));
  for(size_t kk = 0; kk<Tm*Tn*Tp; kk++) {
    T[kk] = 0; 
  }

  uint32_t Sm = 13;
  uint32_t Sn = 15;
  uint32_t Sp = 17;

  double * S = malloc(Sm*Sn*Sp*sizeof(double));

  for(size_t kk = 0; kk<Sm*Sn*Sp; kk++) {
    S[kk] = 1;
  }

  int64_t Pm = -7;
  int64_t Pn = -8;
  int64_t Pp = -9;

  blit3(T, Tm, Tn, Tp,   S, Sm, Sn, Sp,  Pm, Pn, Pp,  0);

  if(Pm>-1 && Pn>-1 && Pp>-1)
    if(Pm<Tm && Pn<Tn && Pp<Tp)
      printf("T(%ld,%ld,%ld) = %f\n", Pm, Pn, Pp, T[Pm + Pn*Tm + Pp*Tm*Tn]);

  free(S);
  free(T);

printf("--> blit3g\n");
size_t Gm = 11;
size_t Gn = 11;
size_t Gp = 11;
double * G = calloc(Gm*Gn*Gp,sizeof(double));
double * Dot = calloc(7,sizeof(double));
Dot[0] = 7; Dot[1] = 7; Dot[2] = 7;
Dot[3] = 100;
Dot[4] = 1; Dot[5]=1; Dot[6]=1;
blit3g(G, Gm, Gn, Gp, Dot, 1, mid_point, 0);

double maxg = 0;
for(size_t kk=0; kk<Gm*Gn*Gp; kk++)
  maxg = GSL_MAX(maxg, G[kk]);
printf("max(G): %f\n", maxg);
double midg = G[7+7*Gm+7*Gm*Gn]; 
printf("G(7,7,7)=%f\n", midg);
assert(midg == maxg);

free(G);
free(Dot);

  return 0;
}

int main(int argc, char ** argv)
{
  printf("%s\n", argv[0]);
  if(argc == 1)
    return unit_tests();
}
#endif
