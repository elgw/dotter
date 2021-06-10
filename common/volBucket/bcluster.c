  #include <stdio.h>
  #include <stdlib.h>
  #include <assert.h>
  #include "string.h"
  #include "math.h"
  #include "volBucket.h"
#include "time.h"

  /*

  C = bcluster(X, r);

  Cluster the data in X (x,y,z) by the shortest distance, set by r,
  where C is a list of all the clusters with more than one point,
  separated by zeros, for example: if C = [1, 2, 0, 3, 5, 7] that means
  that there are two clusters, cluster one: 1, 2 and cluster two
  consists of the points with number 3, 5 and 7.

  This
  is comparable to the following built in MATLAB command:

  C2 = cluster(linkage(X), r)

  except from the output format.

  Can also be run standalone, for debugging,
  gcc bcluster.c volBucket.c
  ./a.out

The algorithm divides the domain (the geometry is assumed to be from a
microscopy image stack) into a regular grid of buckets. Each point is
assigned to bucket and is linked to buckets that might contain other
points with d<r.

delta, the side length of the buckets, has to be larger than rmax,
or some neighbours might not be
found

Erik, 20150317
*/

#define MAX(a,b) (((a)>(b))?(a):(b))
#define MIN(a,b) (((a)<(b))?(a):(b))

void propagate(vbBucket * myVB, vbNode *e, uint32 * C, uint32 * cpos)
/*  Recursively expand a cluster */
{
  e->visited = 1;
  C[cpos[0]++] = e->number;

  // For all buckets that possibly contain neighbours
  for(int nB=0; nB < e->nNEBuckets; nB++)
  {
    vbNode *b = myVB->buckets[e->NEBuckets[nB]];
    // Recursively visit all close by nodes and write the node numbers
    // to C and set visited to 1
    while(b!= NULL)
    {
      if(b->visited == 0)
       if(vbBucketDistance2(b,e) < myVB->rr)
         propagate(myVB, b, C, cpos);
      b=b->next;
    }
  }
}


void bcluster(double *X, int nObjects, double r, uint32 * C)
/* Input: X, the data [[x0, y0, z0], [x1, y1, z1], ... ,[xN, yN, zN]]
 r: max distance between clusters
 C: output
*/
{
int verbose = 0; // 0: none, 1: some, 2: insane
// Get from X

int maxx=ceil(X[0]);
int maxy=ceil(X[nObjects]);
int maxz=ceil(X[2*nObjects]);

int minx=floor(X[0]);
int miny=floor(X[nObjects]);
int minz=floor(X[2*nObjects]);

for(uint32  kk=0; kk<nObjects; kk++)
  {
    maxx= MAX(ceil(X[kk]), maxx);
    maxy= MAX(ceil(X[kk+nObjects]), maxy);
    maxz= MAX(ceil(X[kk+2*nObjects]), maxz);
    minx= MIN(floor(X[kk]), minx);
    miny= MIN(floor(X[kk+nObjects]), miny);
    minz= MIN(floor(X[kk+2*nObjects]), minz);
}

assert(minx >= 0);
assert(miny >= 0);
assert(minz >= 0);


if(verbose>0)
{
    printf("r: %f\n", r);
    printf("min: %d %d %d\n", minx, miny, minz);
    printf("max: %d %d %d\n", maxx, maxy, maxz);
}

vbBucket *myVB = vbInitialize(nObjects, maxx+1, maxy+1, maxz+1, r);

if(verbose)
  vbInfo(myVB);

if(verbose)
  printf("Populating\n");

for(uint32 kk=0; kk<nObjects; kk++)
{
  double x = X[kk];
  double y = X[kk+nObjects];
  double z = X[kk+2*nObjects];
  if(verbose>1)
   printf("%f, %f, %f\n", x, y, z);
  vbAdd(myVB, x,y,z, NULL, kk+1);
  if(verbose>1)
    printf("%u\n", myVB->nObjects);
}

if(verbose>0)
  vbInfo(myVB);

uint32 cpos = 0;
for(uint32 kk=0; kk<nObjects; kk++) // For each node/object
  {
   vbNode *e = &myVB->objects[kk];
   // printf("p:%d v:%d enr: %d\n", cpos, e->visited, e->number);
   int cpos0 = cpos;
   if (e->visited == 0)
      {
        propagate(myVB, e, C, &cpos);
        C[cpos++]=0;
      }

  // Exclude non - clusters
  if(cpos == cpos0+2)
    {
       C[cpos0]=0;
       cpos = cpos0;
    }
}

if(verbose>0)
 printf("\nFreeing\n");
vbFree(myVB);
}

int main(int argv, char ** argc)
{

printf("sizeof(uint32): %lu\n", sizeof(uint32));

srand(time(NULL)); rand();
int N = 10000 + (double) (5000.0*rand()/RAND_MAX);
N = 1;
double r = 1.0 + ((double) rand()/(RAND_MAX));

printf("N: %d, r: %f\n", N, r);

double *X = (double*) malloc(3*N*sizeof(double));
uint32 *C = (uint32 *) malloc(2*N*sizeof(uint32));
memset(C, 0, 2*N*sizeof(uint32));

for(int kk=0; kk<N; kk++)
{
    X[kk] = 1024.0*rand()/ (double) RAND_MAX;
    X[kk+N] = 1024.0*rand()/ (double) RAND_MAX;
    X[kk+2*N] = 20.0*rand()/ (double) RAND_MAX;
}
X[0] = 2048; X[1]=2048; X[2] = 0;

bcluster(X, N, r, C);
if(N<100)
{
uint32 last = 0;
for(uint32 kk=0; kk<2*N; kk++)
  {
  if(C[kk] == 0)
      { if(last>0) printf("\n"); }
      else
      {printf("%u ", C[kk]);}
  last = C[kk];
}
printf("\n");
}


free(X);
free(C);


return 0;
}
