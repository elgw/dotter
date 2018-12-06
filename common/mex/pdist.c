#include <stdio.h>
#include <stdlib.h>
#include <math.h>

/* About the same speed as matlab.
 * actually pdist(X) is very fast
 * while squareform(pdist(X)) takes about 10x more time
 *
 *
%   X         5500x3             132000  double 
 >> tic, d = pdist(X); toc
Elapsed time is 0.037554 seconds.
>> tic, d = squareform(pdist(X)); toc
Elapsed time is 0.348866 seconds.
 *
 */

void pdist3(double * restrict X, const size_t M, double * restrict D)
{
  /* Assumes that X is a 3xM matrix with coordinates
   * and that D is large enough to store the output
   */

  size_t idx = 0;
  for(size_t kk = 0; kk<M; kk++)
    for(size_t ll = kk+1; ll<M; ll++)
    {
      D[idx++] = sqrt(
          pow(X[3*kk] - X[3*ll],2) +
          pow(X[3*kk+1] - X[3*ll+1],2) +
          pow(X[3*kk+2] - X[3*ll+2],2));
    }
  return;
}

int main(int argc, char ** argv)
{

  size_t M = 5500; // number of points
  size_t nD = M*(M-1)/2; // number of distance
  double * X = malloc(M*3*sizeof(double));
  double * D = malloc(M*(M-1)/2*sizeof(double));

  X[0] = 1;  
  X[1] = 1;  
  X[2] = 1;  
  X[3] = 2;  
  X[4] = 2;  
  X[5] = 2;  
  X[6] = 4;  
  X[7] = 4;  
  X[8] = 4;  

    pdist3(X,M,D);

//  for(int kk=0; kk<nD; kk++)
    printf("%f\n", D[0]);

free(X);
free(D);
  return 0;
}
