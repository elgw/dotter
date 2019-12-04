/* Public */
int imshift3(double * , size_t , size_t , size_t , 
    double , double , double , int );void showMatrix(double * , size_t, size_t );

/* Private */

// Generate a kernel to shift an image
int generateShift(double **, double, size_t *, int);


