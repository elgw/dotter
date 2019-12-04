typedef struct vbNode vbNode;
typedef struct vbBucket vbBucket;
typedef unsigned int uint32;

struct vbNode {
vbNode *next; // A pointer to the next node in the bucket
double x, y, z; // Spatial coordinates for the object
void *object; // A pointer to any object that can be passed along
int bucket; // The bucket that this object falls into
int NEBuckets[26]; // Neighbouring buckets to search in
int nNEBuckets; // Number of neighbour buckets relevant to the object
int visited;
uint32 number; // The number of the cluster that the point belongs to
// by default set to -1, which means that it is undecided
// 0 means that is is an isolated point
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
  double rr;
};



vbBucket * vbInitialize(uint32 nObjects, int maxx, int maxy, int maxz,
double r );
int vbFree(vbBucket * vb);
int vbInfo(vbBucket * b);
int vbAdd(vbBucket *b, double x, double y, double z, void * object,
uint32 number);
vbNode* vbGetNext(vbBucket* b);
double vbBucketDistance2(vbNode * a, vbNode *b);
int main(int argc, char ** argv);




