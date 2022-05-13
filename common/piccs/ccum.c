#include "ccum.h"


/*
   Calculates C_{cum} in the following paper:


   @article{semrau2011quantification,
   title = "Quantification of Biological Interactions with Particle Image Cross-Correlation Spectroscopy (PICCS) ",
   journal = "Biophysical Journal ",
   volume = "100",
   number = "7",
   pages = "1810 - 1818",
   year = "2011",
   note = "",
   issn = "0006-3495",
   doi = "http://dx.doi.org/10.1016/j.bpj.2010.12.3746",
   url = "http://www.sciencedirect.com/science/article/pii/S0006349511001846",
   author = "Stefan Semrau and Laurent Holtzer and Marcos González-Gaitán and Thomas Schmidt"
   }

   The implementation is for 2D images at the moment although it takes 3D coordinates as input.

   Too speed up, use pthreads and a quadtree.

   Compile:
   gcc ccum.c -o ccum -lm

*/

/* Euclidean distance squared between P1 and P2 */
static double d2(double *P1, double *P2)
{
    double dx = P1[0]-P2[0];
    double dy = P1[1]-P2[1];
//  double dz = P1[2]-P2[2];

    return dx*dx + dy*dy; // + dz*dz;
}

void ccum(double * C, uint64_t nC,
          double * A, uint64_t nA,
          double * B, uint64_t nB,
          double w, double h,
          double lMAX)
{

    double nDots = 0; // Keeps track of the number of dots in A that was used for later normalization
    double lMAX2 = lMAX*lMAX;

    for(uint64_t kk = 0; kk<nA; kk++)
    {

        // Check distance to boundaries
        int ok = 1;
        if (A[3*kk]  >w-lMAX)
            ok = 0;
        if (A[3*kk+1]>w-lMAX)
            ok = 0;
        if (A[3*kk]  <  lMAX)
            ok = 0;
        if (A[3*kk+1]<  lMAX)
            ok = 0;

        if(ok)
        {
            nDots++;
            for(uint64_t ll = 0; ll<nB; ll++)
            {
                double d = d2(B+ll*3, A+kk*3);
                uint64_t index = roundl(d/lMAX2*(nC-1));
                if(index<nC)
                {
                    C[index] = C[index]+1;
                }
            }
        }
    }

/* Create the Cumulative Distribution Function (CDF)
 * Method: Integrate
 * and normalize by the number of dots that was used from P to
*/
    double sum = 0;
    if(nDots>0)
    {
        for(uint64_t kk = 0; kk<nC; kk++)
        {
            sum = sum + C[kk];
            C[kk] = sum/nDots;
        }
    }
}

void test_ccum()
{
    double pixelSize = 130;
    double lMAX = 10*pixelSize; // nm
    uint64_t nC = (uint64_t) 1024;
    double * C = calloc(nC,sizeof(double));
    uint64_t nA = 1000;
    uint64_t nB = 1000;
    double * A = malloc(3*nA*sizeof(double));
    double * B = malloc(3*nA*sizeof(double));
    double w = 1024*pixelSize;
    double h = 1024*pixelSize;

    for(int kk = 0; kk<nA; kk++)
    {
        A[kk*3]   = pixelSize*kk;
        A[kk*3+1] = pixelSize*kk;
        A[kk*3+2] = pixelSize*kk;
        B[kk*3]   = pixelSize*kk;
        B[kk*3+1] = pixelSize*kk;
        B[kk*3+2] = pixelSize*kk;
    }

    ccum(  C, nC,  A, nA,  B, nB, w, h, lMAX);
    assert(fabs(C[0] - 1)<0.0001);
    assert(C[nC-1] > 1);

    free(C);
    free(A);
    free(B);

}

void test_d2()
{
    double A[3] = {0,0,0};
    double B[3] = {0,0,0};
    assert(d2(A,B) == 0);
    A[1]=7;
    assert(fabs(d2(A,B) - 49)<0.0000000001);
}

int ccum_ut()
{
    printf("Testing components\n");
    test_d2();
    test_ccum();
    printf("All tests passed\n");
    return EXIT_SUCCESS;
}
