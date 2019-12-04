int centreOfMass(double * V, size_t M, size_t N, size_t P, double *
com)
{
/* Centre of Mass of volumetric image V of size MxNxP 
   V should be pre-processed for beads, an erf-threshold between min
   and max is probably a good option.
*/

// Reset, just to be sure...
com[0] = 0;
com[1] = 0;
com[2] = 0;

for(size_t xx = 0; xx<M; xx++)
  for(size_t yy = 0; yy<N; yy++)
    for(size_t zz = 0; zz<P; zz++)
      {
        pos = xx+yy*M+zz*M*N;
        com[0]+=V[pos] * (xx+1);
        com[1]+=V[pos] * (yy+1);
        com[2]+=V[pos] * (zz+1);
      }
  
com[0]/=(N*P)*M*M/2;
com[1]/=(M*N)*N*N/2;
com[2]/=(M*N)*P*P/2;

}
