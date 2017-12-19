/*      

mex code to do quickly make histogram for 16 bit data. 

Input:  A 16 bit n-dimensional matrix. 
Output: A 32 bit 256x1 matrix where bin k contains the numer of elements of value k in the input.  

Warning: Only 32 bit output. I.E max cout per number= 4,294,967,295 

Performance?
example:
   >> t=uint16(255*255*rand(10000000,1));
   MATLAB, BUILT IN:
   >> tic; h=hist(t, 1:255); toc    
   Elapsed time is 1.182038 seconds.
   THIS:
   >> tic; h=histo16(t); toc          
   Elapsed time is 0.015440 seconds.

   approximately 100 times faster

Erik Wernersson

*/

#include "mex.h"

typedef unsigned char uint8;
typedef unsigned short uint16;
typedef unsigned int uint32;
typedef unsigned long int uint64;

void mexFunction(int nlhs, mxArray *plhs[],int nrhs, const mxArray *prhs[]) 
{

/*
  prhs     An array of right-hand input arguments.
  plhs     An array of left-hand output arguments.
  nrhs     The number of right-hand arguments, or the size of the prhs array.
  nlhs     The number of left-hand arguments, or the size of the plhs array
*/ 

  unsigned int *in_reg;
  int *maxheights;
  size_t numel; 
  int n, maxregion;
  int current_label, npixlab;
  const int  *dim_array;
  int number_of_dims, xres, yres, zres;

  if (!nrhs==1) {
     mexErrMsgTxt("There should be one input.");
  }

  /* Check data types of the input arguments. */
  if (!(mxIsUint16(prhs[0]))) {
    mexErrMsgTxt("First argument must be of type uint16.");
  }

  in_reg = (unsigned int *) mxGetPr(prhs[0]);
  numel = mxGetNumberOfElements(prhs[0]);  
  number_of_dims = mxGetNumberOfDimensions(prhs[0]);
  dim_array = mxGetDimensions(prhs[0]);

  uint16* in; // Input data matrix
  in = (uint16 *) mxGetPr(prhs[0]);

  uint32* seg; // The output, [ 2^bits x 1 ] matrix, uint32;
  int ut_dim[]={ 65536,1,0};

  plhs[0] = mxCreateNumericArray(1,ut_dim,mxUINT32_CLASS, mxREAL);  
  seg = (uint32 *) mxGetPr(plhs[0]);

  // Go throught the volume and cout the number of occurances of all the posible uint8 values.

  for (size_t i =1; i<=numel; i++)
    {
      seg[in[i-1]]++; // The -1 is to match the matlab indexing.
    }
}


