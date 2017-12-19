/* 
mex file for 
Markov random field segmentation with Graph Cuts 
   
Usage:

Compile with >mex -largeArrayDims -v CFLAGS="\$CFLAGS -O3" mrfGC.cpp  (in matlab)  use ', not " in shell

Run in Matlab seg=mrfGC(vol,[class1.mean,class1.variance], [class2.mean,class2.variance], beta););
   where cube is a uint8 with the resolution set above. The output seg will also be a uint8.

(Optional, set sixHood=0 for 26-neighbourhood system. Not recommended for large volumes)

Use on your own risk and good luck!

test the code by first compiling and then running demonstration.m

Be careful to set the parameters correct.
The code will crash matlab if you don't send i all variables.

Erik Wernersson
*/

#include "mex.h"
#include <stdio.h>
#include "graph.h"
#include "maxflow.cpp"
#include "graph.cpp"

#include <iostream>
#include <math.h>


/* Global variables */
mwSize yres, xres, zres;
  double  beta;

// For six-hood, try beta~1.5 and for 26-hood, try beta~0.02
// Or: 1/(2*Nbrs) where Nbrs are the number of neighbours to each voxel

#define numel xres*yres*zres
#define min(a,b) ((a)>=(b)?(b):(a))
#define max(a,b) ((a)>=(b)?(a):(b))
#define PI 3.141592

#include "matlabCoord.cpp" // Routines to translate between matlab and c indexing

typedef unsigned char uint8;

using namespace std;

double singleton(double, double, double); // To calculate singleton potentials
void drawnow(void); // Forces matlab to print now i.e. the command drawnow in matlab

//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////
void mexFunction(int nlhs, mxArray *plhs[],int nrhs, const mxArray *prhs[]) 
{

  mexPrintf("Version 1.6");

/*
  prhs     An array of right-hand input arguments.
  plhs     An array of left-hand output arguments.
  nrhs     The number of right-hand arguments, or the size of the prhs array.
  nlhs     The number of left-hand arguments, or the size of the plhs array
*/ 

  if(nrhs!=4)
    {
      mexErrMsgTxt("Wrong number of input parameters");
    }

  // User variables. Change according to your data.
  int nClasses=2;
  
  double mean[2]; // means
  double stdev[2];  // standard deviations

  double *class1 = mxGetPr(prhs[1]);
  double *class2 = mxGetPr(prhs[2]);

  mean[0]=class1[0];
  mean[1]=class2[0];

  stdev[0]=class1[1];
  stdev[1]=class2[1];

  beta= mxGetPr(prhs[3])[0];

  mexPrintf("beta=%f\n", beta);  

  double dt, t, m, s, p;
  int sixHood=1;  // Use six-connectivity or twentysix connectivity


  if (sixHood==1) {
    mexPrintf("Using six-connectivity\n");
  } else {
    mexPrintf("Using twenty-six connectivity"); 
  }

  mexPrintf("%d classes are defined:\n", nClasses);
  mexPrintf("class \t mean \t stddev\n");


  for (int k=0; k<nClasses; k++)
    {
      mexPrintf("%d \t %f \t %f \n", k+1, mean[k], stdev[k]);
    }

// Prepare the input data - in

/* get dimensions of the input matrix */

  int ndims=mxGetNumberOfDimensions(prhs[0]);
  yres= (mxGetDimensions(prhs[0]))[0];

  if(ndims>1){
  xres= (mxGetDimensions(prhs[0]))[1];
  } else { xres=1; }

  if(ndims>2)
    { zres= (mxGetDimensions(prhs[0]))[2]; }
  else { zres=1; }
  
  cout << "xres:" << xres << " yres: " << yres << " zres: " << zres << endl;
    
  mwSize dims[]={yres,xres,zres};
  uint8* in; // Input data (1GB);
  in = (uint8 *) mxGetPr(prhs[0]);

  mexPrintf("Creating the graph object...\n"); drawnow();

  int nn=numel;

  typedef Graph<double,double,double> GraphType;
  GraphType *g = new GraphType(numel+2, numel*6);
			       // krackar någonstans innan 16 777 216*2

mexPrintf("Adding initial nodes...\n"); drawnow();
  for (int i=0; i<numel; i++) // For each voxel, add a node
    { 
      g -> add_node();      
    }

mexPrintf("Adding connections to source (s) and sink (t)...\n"); drawnow();
  int a, b;
  a=0; b=0;
  for (int i=1; i<numel; i++)
    {
      double lambda=log(singleton(in[i],mean[0],stdev[0])/singleton(in[i],mean[1],stdev[1]));
      if (lambda>0)
	{ // Connection to source
	  g -> add_tweights(i,   lambda,0);
	  a++;
	}
      else
	{ // Connection to sink
	  g -> add_tweights(i,   0,   -lambda);
	  b++;
	}
	
    }  
  mexPrintf("Connections to s: %d, to t: %d.\n", a,b);


  mexPrintf("Adding connections between nodes..."); drawnow();
  int ttt=0;
  
  if (sixHood==0){ // Create a list of the 13 neighbours in the forward direction.
    int nbrs[13];  // store the neighbours here
    for (int i=0; i<numel; i++)       // Find the neighbours  
      {
	int x = c2mx(i); int y = c2my(i); int z = c2mz(i);  // Get the coordinates of the current voxel       
	// For propagation for y, for x, for z 
	// Observe that the elements in the input vector is arranged in that way;
	// All nine in the z+ plane
	nbrs[0]=zp(xm(ym(i)));
	nbrs[1]=zp(xm(i));
	nbrs[2]=zp(xm(yp(i)));
	nbrs[3]=zp(yp(i));
	nbrs[4]=zp(i);
	nbrs[5]=zp(ym(i));
	nbrs[6]=zp(xp(yp(i)));
	nbrs[7]=zp(xp(i));
	nbrs[8]=zp(xp(ym(i)));
	// Three more in the x+ plane
	nbrs[9]=xp(i);
	nbrs[10]=xp(yp(i));
	nbrs[11]=xp(ym(i));
	// one last in the y+ plane
	nbrs[12]=yp(i);
	
	// For each neighbour, add a bidirectional neighbour with capacity beta
	for (int k=0; k< 13; k++)
	  {
	    if (nbrs[k]>-1)
	      {
		g -> add_edge(i, nbrs[k], beta,  beta);
		ttt++;
	      }
	  }	
      }
  }
  else // If six-hood:
    {
      int nbrs[3];  // store the neighbours here
      for (int i=0; i<numel; i++) // For each voxel
	{       // Find the neighbours  
	  // Only add connections to voxels in front (front propagation)
	  nbrs[0]=xp(i); nbrs[1]=yp(i); nbrs[2]=zp(i);
	  
	  for (int k=0; k< 3; k++) // For each neighbour
	    {
	      if(nbrs[k]>0) // I.E. if there is an element there (nbrs[k]!=-1)
		{
		  g -> add_edge(i, nbrs[k], beta,  beta);
		  ttt++;
		}
	    }
	}       
    }
  
  mexPrintf("%d connections added\n", ttt);
  
  mexPrintf("Running the max-flow/min-cut optimization...\n"); drawnow();  
  double flow = g -> maxflow();
  
  mexPrintf("Allocating %d byte of memory for output...\n", numel); drawnow();
  uint8* seg; // The output vector
  plhs[0] = mxCreateNumericArray(3,dims,mxUINT8_CLASS, mxREAL);  
  seg = (uint8 *) mxGetPr(plhs[0]);
  
  mexPrintf("Flow = %d\n", flow);
  mexPrintf("Obtaining the result...\n"); drawnow();
  for (int i=0; i< numel; i++) // For each voxel:
    {
      if (g->what_segment(i) == GraphType::SINK)
	{
	  seg[i]=0;  // If source
	}
      else
	{
	  seg[i]=1;
	}
    }

  delete g; // Free the memory from the graph

} // end of mexFunction

///////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////
double singleton(double p,double m, double s)
{
  /* Calculate the singleton potential for a voxel with value p 
   with respect to a class with mean m and standard deviation s 
  i.e. returns a low value (very negative) if good matching*/

  return  1/(sqrt(2*PI)*s)*exp((p-m)*(p-m) / (2*s*s));
}

//////////////////////////////////////////////////////////////
//////////////////////////////////////////////////////////////
void drawnow(void)
{ /* Force matlab to print now */
  mexEvalString("drawnow"); 
}
