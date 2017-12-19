// 1D convolution along M and N
int conv1(double * restrict, double * restrict, const size_t  , const double * restrict , const size_t, const size_t);

// 1D convolution along 2 dimensions
int conv1_2(double * , double *, size_t , size_t , 
    double * , size_t ,
    double * , size_t );

// 1D convolution along 3 dimentions
int conv1_3(double * , const size_t , const size_t , const size_t  ,
    double * , const size_t ,
    double * , const size_t ,
    double * , const size_t );

void * conv1th(void *);

// Private, for testing
void timing2d(void);
void timing3d(void);
int main(int, char **);
