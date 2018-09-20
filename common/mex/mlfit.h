#ifndef _mlfit_h_
#define _mlfit_h_

double estimateNphot(double *, size_t );
double estimateNphotV(double *, size_t , size_t , size_t , double * );
int double_cmp(const void * , const void * );
double estimateBGV(double *V, size_t Vm, size_t Vn, size_t Vp, double * D);
double estimateBG(double *, size_t );
int getZLine(double *W, size_t Ws,
    double * V, size_t Vm, size_t Vn, size_t Vp,
    double *D);
 int getRegion(double * , size_t ,
    double * , size_t , size_t , size_t ,
    double * );
void showRegion(double * , size_t );

#endif
