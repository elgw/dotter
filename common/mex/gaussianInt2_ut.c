#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include "gaussianInt2.h"

int main(int argc, char ** argv)
{
    double mu[] = {0, 0};
    double sigma[] = {1, 1};
    double side = 3;

    if(argc == 6)
    {
        mu[0] = atof(argv[1]);
        mu[1] = atof(argv[2]);
        sigma[0] = atof(argv[3]);
        sigma[1] = atof(argv[4]);
        side = atof(argv[5]);
    }


    int w = 2*side + 1;
    double * G = malloc(w*w*sizeof(double));

    gaussianInt2(G, mu, sigma, w);

    for(int kk = 0; kk<w; kk++)
    {
        for(int ll = 0; ll<w; ll++)
        {
            printf("%.2f ", G[kk*w+ll]);
        }
        printf("\n");
    }
    free(G);
    return EXIT_SUCCESS;
}
