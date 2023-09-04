#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdint.h>
#include <math.h>
#include <assert.h>
#include <gsl/gsl_math.h>

#include "com3.h"

/* Forward declarations */


// #define debugmode 1
int unit_tests(void);

const int64_t comr = 2; // Radius of com filter in pixels
// The filter will be (2*comr+1)^3 pixels

static int pointInDomain(int64_t * restrict Point, size_t * Domain, int nDim)
// Check if a point is in the domain of a 3D image
{
    for(int kk = 0; kk<nDim; kk++)
        if(Point[kk]<0 || Point[kk]>= (int64_t) Domain[kk])
            return 0;

    return 1;
}

static int checkBounds(const int64_t * restrict D,
                       const size_t M, const size_t N, const size_t P)
{
    if(D[0]>=comr && D[0]+comr<(int64_t) M &&
       D[1]>=comr && D[1]+comr<(int64_t) N &&
       D[2]>=comr && D[2]+comr<(int64_t) P)
        return 1; // ok

    return 0;
}

static void
com3_localw(const double * restrict V,
            double * restrict W,
            const size_t M, const size_t N, const size_t P,
            int64_t * restrict D, double * restrict C)
{

#ifdef debugmode
    printf("D: [%u %u %u]\n", D[0], D[1], D[2]);
    printf("M: %lu N: %lu P: %lu\n", M, N, P);
#endif

    double sum = 0;
    double dx = 0;
    double dy = 0;
    double dz = 0;

#ifdef debugmode
    printf("sum: %f\n", sum);
#endif

    if(checkBounds(D, M, N, P))
    {

        double val = V[D[0] + D[1]*M + D[2]*M*N];

        for(int kk = -comr; kk<=comr; kk++) {
            for(int ll = -comr; ll<=comr; ll++) {
                for(int mm = -comr; mm<=comr; mm++) {

                    size_t pos = (D[0]+kk) + (D[1]+ll)*M + (D[2]+mm)*M*N;
                    //  printf("pos: %lu V[pos]: %f\n", pos, V[pos]);
                    dx += kk*V[pos]*val/W[pos];
                    dy += ll*V[pos]*val/W[pos];
                    dz += mm*V[pos]*val/W[pos];

                    sum += V[pos];
                }
            }
        }

        //printf("sum: %f\n", sum);
    }

    if(sum>0)
    {
#ifdef debugmode
        printf("sum: %f (%f, %f, %f)\n", sum, dx, dy, dz);
#endif
        C[0] = D[0] + dx/sum;
        C[1] = D[1] + dy/sum;
        C[2] = D[2] + dz/sum;
    }
    else
    {
#ifdef debugmode
        printf("No com calculation\n");
#endif
        C[0] = D[0];
        C[1] = D[1];
        C[2] = D[2];
    }
}

static void
com3_local(const double * restrict V,
           const size_t M, const size_t N, const size_t P,
                int64_t * restrict D, double * restrict C)
{

#ifdef debugmode
    printf("D: [%u %u %u]\n", D[0], D[1], D[2]);
    printf("M: %lu N: %lu P: %lu\n", M, N, P);
#endif

    double sum = 0;
    double dx = 0;
    double dy = 0;
    double dz = 0;

#ifdef debugmode
    printf("sum: %f\n", sum);
#endif

    if(checkBounds(D, M, N, P))
    {

        for(int kk = -comr; kk<=comr; kk++) {
            for(int ll = -comr; ll<=comr; ll++) {
                for(int mm = -comr; mm<=comr; mm++) {

                    size_t pos = (D[0]+kk) + (D[1]+ll)*M + (D[2]+mm)*M*N;
                    //  printf("pos: %lu V[pos]: %f\n", pos, V[pos]);
                    dx += kk*V[pos];
                    dy += ll*V[pos];
                    dz += mm*V[pos];

                    sum += V[pos];
                } } }

        //printf("sum: %f\n", sum);
    }

    if(sum>0)
    {
#ifdef debugmode
        printf("sum: %f (%f, %f, %f)\n", sum, dx, dy, dz);
#endif
        C[0] = D[0] + dx/sum;
        C[1] = D[1] + dy/sum;
        C[2] = D[2] + dz/sum;
    }
    else
    {
#ifdef debugmode
        printf("No com calculation\n");
#endif
        C[0] = D[0];
        C[1] = D[1];
        C[2] = D[2];
    }
}

static void
setLmax(const double * restrict V,
        double * restrict W,
        const size_t * Domain, const int64_t * Dot)
// Adds V(dot) to all W within comr of dot
// uses global value comr
{
    uint32_t m = Dot[0];
    uint32_t n = Dot[1];
    uint32_t p = Dot[2];

    size_t M = Domain[0];
    size_t N = Domain[1];
    size_t P = Domain[2];

    double val = V[m + n*M + p*M*N];

    for(uint32_t     pp = GSL_MAX(p-comr,0) ; pp<= GSL_MIN(p+comr, P-1) ; pp++) {
        for(uint32_t   nn = GSL_MAX(n-comr,0) ; nn<= GSL_MIN(n+comr, N-1) ; nn++) {
            for(uint32_t mm = GSL_MAX(m-comr,0) ; mm<= GSL_MIN(m+comr, M-1) ; mm++) {
                W[mm + nn*M + pp*M*N] += val;
            }
        }
    }
}

void com3(const double * restrict V,
          size_t M, size_t N, size_t P,
          const double * restrict D,
          double * restrict C,
          size_t L, int weighted)
{
    int64_t Dround[] = {0,0,0};
    size_t Domain[] = {M, N, P};

    double * W;
    if(weighted == 1)
        // Set up the weighting matrix
    {
        W = (double *) calloc(M*N*P, sizeof(double));
        for(size_t kk = 0; kk<L; kk++)
        {
            Dround[0] = nearbyint(D[kk*3]-1);
            Dround[1] = nearbyint(D[kk*3+1]-1);
            Dround[2] = nearbyint(D[kk*3+2]-1);
            if(pointInDomain(Dround, Domain, 3))
            {
                setLmax(V, W, Domain, Dround);
            }
        }
    }

    if(weighted == 1)
        for(size_t kk = 0; kk<L; kk++)
        {
            Dround[0] = nearbyint(D[kk*3]-1);
            Dround[1] = nearbyint(D[kk*3+1]-1);
            Dround[2] = nearbyint(D[kk*3+2]-1);

            //    printf("%d %d %d\n", Dround[0], Dround[1], Dround[2]);

            com3_localw(V, W, M, N, P, Dround, C+kk*3);
        }

    if(weighted ==0)
        for(size_t kk = 0; kk<L; kk++)
        {
            Dround[0] = nearbyint(D[kk*3]-1);
            Dround[1] = nearbyint(D[kk*3+1]-1);
            Dround[2] = nearbyint(D[kk*3+2]-1);

            //    printf("%d %d %d\n", Dround[0], Dround[1], Dround[2]);

            com3_local(V, M, N, P, Dround, C+kk*3);
        }


    if(weighted == 1){

        // This was used for debugging
        //for(size_t xx = 0; xx<M*N*P; xx++)
        //  V[xx] = W[xx];

        free(W);
    }
}

#ifdef standalone

int unit_tests() {

    // Size of image
    uint32_t M = 100;
    uint32_t N = 100;
    uint32_t P = 100;
    uint32_t L = 2; // number of dots

    double * V = malloc(M*N*P*sizeof(double));
    double * D = malloc(L*3*sizeof(double));
    double * C = malloc(L*3*sizeof(double));

    memset(V, 0, M*N*P*sizeof(double));
    memset(C, 0, 3*L*sizeof(double));

    for(size_t kk = 0; kk<M*N*P; kk++)
        V[kk] = 0;

    D[0] = 11; D[1] = 12; D[2] = 13;
    D[3] = 0; D[4] = 15; D[5] = 16;

    size_t pos = D[0] + M*D[1] + M*N*D[2];
    V[pos] = 3;
    //  V[pos+1] = 1;
    //  V[pos + M] = 1;
    V[pos + M*N] = 1;

    // Ordinary
    com3(V, M, N, P,
         D, C, L, 0);

    // Weighted
    com3(V, M, N, P,
         D, C, L, 1);

    for(uint32_t kk=0; kk<L; kk++) {
        printf("%d [%f %f %f] -> ", kk, D[3*kk], D[3*kk+1], D[3*kk+2]);
        printf(" [%f %f %f]\n",         C[3*kk], C[3*kk+1], C[3*kk+2]);
    }

    free(C);
    free(D);
    free(V);

    return 0;
}

int main(int argc, char ** argv)
{
    printf("%s\n", argv[0]);
    if(argc == 1)
        return unit_tests();
}
#endif
