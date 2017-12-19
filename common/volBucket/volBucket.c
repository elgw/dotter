/* 
   A volumetric bucket queue used to find 3D points in close proximity.

Complexity: Linear in the number of points assuming that they are
evenly distributed

Compile: gcc -std=c99 -lm -O3 volBuclet.c
To do: check the use of rmax (int vs double)

erikw 20150218
*/

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <time.h>
#include <assert.h>

#define MAX(a,b) (((a)>(b))?(a):(b))
#define MIN(a,b) (((a)<(b))?(a):(b))

typedef unsigned int uint32;
typedef struct vbNode vbNode;
typedef struct vbBucket vbBucket;

struct vbNode {
  vbNode *next; // A pointer to the next node in the bucket
  double x, y, z; // Spatial coordinates for the object
  void *object; // A pointer to any object that can be passed along
  int bucket; // The bucket that this object falls into
  int NEBuckets[26]; // Neighbouring buckets to search in
  int nNEBuckets; // Number of neighbour buckets relevant to the object
  int visited;
  uint32 number;
};

struct vbBucket{
  // A bucket is a pointer to a object or NULL
  vbNode **  buckets;
  // All objects that will be put into the vb are allocated
  // in a clump
  vbNode *  objects;
  // Number of objects
  uint32 nObjects;
  // Largest x,y,z of the elements that will be put into the vb
  // (smallest assumed to be 0)
  int maxx, maxy, maxz;
  // Number of buckets MNP, a discretization of max xyz
  int M, N, P;
  int nBuckets; // is set to MNP at initialization
  int delta; // dX/dN, i.e. the spatial size of the buckets
  int oadd; // next object to put in a bucket [0, N-1]
  // The overlap between the bucket, should be set to the radius of
  // interest
  double rmax; 
  double rr; // will be set to rmax*rmax
};


vbBucket * vbInitialize(uint32 nObjects, int maxx, int maxy, int maxz, double rmax)
{
  vbBucket * b = malloc(sizeof(vbBucket));

  b->nObjects = nObjects;
  b->maxx = maxx;
  b->maxy = maxy;
  b->maxz = maxz;
  b->delta = 20; // side length of bins
  b->oadd = 0;
  b->rmax = rmax; // Important parameter 
  b->rr = rmax*rmax;
  assert(b->rmax < b->delta);
  int M = ceil((double) maxx/b->delta);
  M = MAX(M,1);
  b->M = M;
  int N = ceil((double) maxy/b->delta);
  N = MAX(N,1);
  b->N =N;
  int P = ceil((double) maxz/b->delta);
  P = MAX(P,1);
  b->P =P;


  b->nBuckets = M*N*P;
  // allocate buckets
  b->buckets = malloc(b->nBuckets*sizeof(vbNode*));
  if(b->buckets == NULL)
    exit(1);


  for(int kk=0; kk<M*N*P; kk++)
    b->buckets[kk]=NULL;

  // allocate objects
  b->objects = malloc(b->nObjects*sizeof(vbNode));
  if(b->objects == NULL)
    exit(1);
  return b;
}

int vbFree(vbBucket * vb)
{
  free(vb->objects);
  free(vb->buckets);
  free(vb);
  return(1);
}

int vbInfo(vbBucket * b)
{
  printf("\n::: Bucket information :::\n");
  printf("nBuckets: %d nObjects: %ud\n", b->nBuckets, b->nObjects);
  printf("Spatial geometry: X Y Z: %dx%dx%d\n", b->maxx, b->maxy, b->maxz);
  printf("Bucket geometry: M N P: %dx%dx%d\n", b->M, b->N, b->P);
  printf("delta: %d > rmax: %f\n", b->delta, b->rmax);
  for(int kk=0; kk<b->nBuckets; kk++)
  {
    int nObjects=0;
    vbNode* p = b->buckets[kk];
    if(p!=NULL)
    {
      nObjects++;
      while(p->next!=NULL)
      {
        nObjects++;
        p=p->next;
      }
    }
    if(0)
      printf("bucket %d, nObjects: %d\n", kk, nObjects); 
  }
  printf("\n");
  return 1;
}

int vbAdd(vbBucket *b, double x, double y, double z, void * object,
    uint32 number)
{
  // Take one of the unused objects to store the object
  vbNode *node = &b->objects[b->oadd++];  
  node->x = x; 
  node->y = y; 
  node->z = z; 
  node->object = object;
  node->next = NULL;
  node->visited = 0;
  node->number = number;

  // Get bucket number
  int m = node->x/b->delta;
  int n = node->y/b->delta;
  int p = node->z/b->delta;

  // Add to bucket as first element
  int bucketNo = m+n*b->M+p*b->M*b->P;
  node->bucket = bucketNo;
  assert(bucketNo>=0);
  assert(bucketNo< b->nBuckets);

  //printf("Bucket %d\n", bucketNo);
  int neBuckets=0;
  // Figure out relevant neighbouring buckets to search in.
  for(int deltax = -1; deltax<2; deltax++)
    for(int deltay = -1; deltay<2; deltay++)
      for(int deltaz = -1; deltaz<2; deltaz++)
      {
        int tx = x+deltax*b->rmax;
        int ty = y+deltay*b->rmax;
        int tz = z+deltaz*b->rmax;

        // Get bucket number
        int m = tx/b->delta;
        int n = ty/b->delta;
        int p = tz/b->delta;

        // Add to bucket as first element
        int bucketNo = m+n*b->M+p*b->M*b->P;
        if(bucketNo>-1 && bucketNo < b->nBuckets)
        {
          int unique = 1;
          for(int tt = 0; tt< neBuckets; tt++)
            if(node->NEBuckets[tt] == bucketNo)
              unique = 0;
          if(unique)
            node->NEBuckets[neBuckets++]=bucketNo; 
        }
      }
  node->nNEBuckets = neBuckets;

  if(0){
    for(int kk=0; kk<node->nNEBuckets; kk++)
      printf("%d ", node->NEBuckets[kk]);
    printf("\n");
  }
  // Ensure that the neighbour list is unique

  // And finally, insert the node into the bucket
  vbNode* btemp = b->buckets[bucketNo];
  b->buckets[bucketNo]=node;
  node->next = btemp;

  return(1); 
}

vbNode* vbGetNext(vbBucket* b)
{
  return b->objects;
}

double vbBucketDistance2(vbNode * a, vbNode *b)
  // Returns the square of the Euclidean distance between node a and b
{
  double dx = (a->x -b->x);
  double dy = (a->y -b->y);
  double dz = (a->z -b->z);
  return (dx*dx + dy*dy + dz*dz);
}

int main2(int argc, char ** argv)
{

  srand(time(NULL));
  int verbose = 0;

  // Initialization
  int nObjects = 50000; // Number of objects
  int maxx=1024; int maxy=1024; int maxz=100; // Size of sample
  int rmax = 3; // Max distance between objects, only integer values supported

  printf("Initializing vb\n");
  vbBucket *myVB = vbInitialize(nObjects, maxx, maxy, maxz, rmax);

  vbInfo(myVB); // Print info

  /* For demonstration, points with random locations are added
     the option to point to objects is not used.
     */

  printf("Populating\n");
  for(int kk=0; kk<nObjects; kk++)
  {
    double x = maxx*(double) rand()/ (double) RAND_MAX; 
    double y = maxy*(double) rand()/ (double) RAND_MAX; 
    double z = maxz*(double) rand()/ (double) RAND_MAX; 
    if(verbose)
      printf("%f, %f, %f\n", x, y, z);
    vbAdd(myVB, x,y,z, NULL, kk); 
  }
  printf("\n");


  /* 
     Find all point pairs where the Euclidean distance is less than rmax
     This is the only query interface at the moment and should be cleaned
     up
     */
  int verbose2 = 0;
  int nPairs = 0;
  for(int kk=0; kk<nObjects; kk++) // For each node/object
  {
    vbNode *e = &myVB->objects[kk];
    int hasNeighbours = 0;
    /* For all neighbouring buckets that might contain points with
     * distance < rmax */
    for(int nB=0; nB<e->nNEBuckets; nB++)
    {
      vbNode *b = myVB->buckets[e->NEBuckets[nB]];
      if(b!=NULL) { 
        do {
          if(b != e)
            if(vbBucketDistance2(b,e)<9){
              if(verbose2)
                printf(" (%f, %f, %f)-%d\n", b->x, b->y, b->z, b->bucket);
              hasNeighbours = 1;
              nPairs++;
            }
          b = b->next;
        } while (b != NULL);
      }}
    if(verbose2 && hasNeighbours)   
      printf("  close to (%f, %f, %f)-%d\n" , e->x, e->y, e->z, e->bucket); 
  }

  printf("Found %d point pairs where d(a,b)<rmax\n", nPairs/2);

  printf("\nFreeing\n");
  // Free everything that was cleared
  vbFree(myVB);
  return 0;
}

