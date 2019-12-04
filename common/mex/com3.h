#ifndef _com3_h_
#define _com3_h_
int pointInDomain(int64_t * restrict , size_t * , int );
int checkBounds(int64_t * restrict , 
    const size_t , const size_t , const size_t );
void com3_localw(double * restrict , double * restrict , const size_t , const size_t , const size_t , 
    int64_t * restrict , double * restrict );
void com3_local(double * restrict , const size_t , const size_t , const size_t , 
    int64_t * restrict , double * restrict );
void setLmax(double *, double * , size_t * , int64_t * );
void setWeights(double * , double * , size_t , size_t , size_t , double * , size_t );
void com3(double * , size_t , size_t , size_t , 
    double * , double * , size_t , int );
#endif
