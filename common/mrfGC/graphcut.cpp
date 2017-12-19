//////////////////////////////////////////////////
// Implementation of 2D/3D graphcut segmentation
//////////////////////////////////////////////////


#include "mex.h"
#include "graph.h"
#include "graph.cpp"
#include "maxflow.cpp"
#include "image.h"
#include "util.h"

using namespace std;

typedef image<unsigned char> imagetype; 



///////////////////////////////////////
// Matlab interface
///////////////////////////////////////

void mexFunction(int nlhs, mxArray *plhs[],int nrhs, const mxArray *prhs[]) {
  if(nrhs!=2){
    mexErrMsgTxt("Function needs two arguments");
  }

  int ndim =  mxGetNumberOfDimensions(prhs[0]);
  int x_size, y_size, z_size=1;

  unsigned char *seed_elements, *cost_elements;
  bool* out_elements;
  seed_elements = (unsigned char *) mxGetPr(prhs[0]);
  cost_elements = (unsigned char *) mxGetPr(prhs[1]);

  int nelem = mxGetNumberOfElements(prhs[0]);
  const int *dim_array = mxGetDimensions(prhs[0]);
  plhs[0] = mxCreateNumericArray(ndim,dim_array,mxLOGICAL_CLASS, mxREAL);  
  out_elements = (bool*) mxGetPr(plhs[0]);
  
  x_size=dim_array[0];
  y_size=dim_array[1];
  if(ndim>2){
    z_size=dim_array[2];
  }



  imagetype seeds = imagetype(seed_elements, y_size, x_size,z_size);
  imagetype cost = imagetype(cost_elements, y_size, x_size,z_size);

  int* image2node = new int[nelem];
  vector<int> node2image;
  int i;
  
  int unknown=128;
  int inside=255;
  int outside=0;

  for(i=0; i< nelem; i++){
    out_elements[i]=false;
    if(seeds[i]==inside){
      out_elements[i]=true;
    }
    else if(seeds[i]==unknown){
      image2node[i]=node2image.size();
      node2image.push_back(i);
    }
  }

  int number_of_nodes=node2image.size();
  int connectivity=8;
  if(ndim>2) connectivity=18;


  typedef Graph<int,int,int> GraphType;
  GraphType *g = new GraphType(number_of_nodes, connectivity*number_of_nodes); 

  //Add nodes
  for(i=0; i< number_of_nodes; i++){
      g->add_node();
  }

  //Setup paths
  for(i=0; i< number_of_nodes; i++){
    vector<int> neighbors;
    if(ndim==2){
      neighbors=seeds.get_8_neighbors(node2image[i]);
    }
    else{
      neighbors=seeds.get_18_neighbors(node2image[i]);
    }
    for(int j = 0; j<neighbors.size(); j++){
      if(seeds[neighbors[j]]==unknown){
	g -> add_edge( i, image2node[neighbors[j]],cost[neighbors[j]], cost[node2image[i]] );
      }
      else if(seeds[neighbors[j]]==inside){
	g->add_tweights(i, 100000, 0);
	//add a source path
      }
      else if(seeds[neighbors[j]]==outside){
	g->add_tweights(i, 0, 100000);
	//add a sink path
      }
    }
  }

  g->maxflow();

  for(i=0; i< number_of_nodes; i++){
    if(g->what_segment(i) == GraphType::SOURCE){
      out_elements[node2image[i]]=true;
    }
  } 
  
  delete image2node;
  delete g;
}



  


