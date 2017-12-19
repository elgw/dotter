#include <stdlib.h>
#include <stdio.h>

void cumsum2(double * D, size_t M, size_t N)
{

  // First column
  for(int mm = 1; mm<M; mm++)
    D[mm] = D[mm]+D[mm-1];

  for(int nn = 1; nn<N; nn++) // For each column
  {
    double cSum = D[nn*M];
    D[nn*M] = D[nn*M] + D[(nn-1)*M]; // First element in each column
    for(int mm = 1; mm<M; mm++) // Go down the column
    {
      cSum += D[nn*M+mm];
      D[nn*M+mm] = D[(nn-1)*M+mm] + cSum;
    }
  }


}

void printMatrix(double * D, int M, int N)
{
  
  for (int nn = 0; nn<N; nn++)
  {
    for(int mm = 0; mm<M; mm++)
      printf("%f ", D[nn*M+mm]);
      printf("\n");
  }

}

int main(int argc, char ** argv)
{

  printf("argc: %d\n", argc);
  unsigned long N = atol(argv[1]);
  printf("Size: %lu\n", N);

  double * T = malloc(N*N*sizeof(double));
  for(int kk=0; kk<N*N; kk++)
    T[kk] = 1;

  if(N<10)
    printMatrix(T, N, N);


  for(int kk = 0; kk<10; kk++)
    cumsum2(T, N, N);

  if(N<10)
  {
    printf("\n");
    printMatrix(T, N, N);
  }

  free(T);
  printf("Done\n");


}
