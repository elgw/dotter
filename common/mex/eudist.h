void edt(double * restrict B, 
    double * restrict D, 
    const size_t M, const size_t N, const size_t P, 
    const double dx, const double dy, const double dz, 
    int nThreads);
  /*  Euclidean distance transform 
     B specifies a binary mask, 1 == object, 0 = background
     Distances are stored in D
     Matrices are of size M x N x P
     nThreads has to be at least 1.
     */

 
