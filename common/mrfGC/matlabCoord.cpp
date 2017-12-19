/* 

Routines to convert between the different indexing schemes used by
matlab for matrixes and and the 1D vectors in C++ that arises when data 
is accessed by the mex-interface.

Usage:
the variables xres, yres and zres has to be defined globally before 
importing this file.

*/

int m2c(int, int, int); // convert matlab style to c-style

int c2mx(int); // c style to matlab x coordinate
int c2my(int); // c style to matlab y coordinate
int c2mz(int); // c style to matlab z coordinate

int xp(int); // x+1  Position functions. Returns -1 if no element there
int xm(int); // x-1
int yp(int); // y+1
int ym(int); // y-1
int zp(int); // z+1
int zm(int); // z-1


int m2c(int y, int x, int z)
{
  // converts matlab matrix indices to cpp vector index number
  return y-1 + (x-1)*yres + (z-1)*xres*yres;
}

int c2mx(int c)
{
  return ((c)%(xres*yres)) / (yres)+1;
}

int c2my(int c)
{
  return c%yres+1;
}

int c2mz(int c){
  return (int) floor((c)/(yres*xres))+1;
}

int yp(int p)
{ // ok
  if (p>-1 && c2my(p)==yres)
    { return -1; }
  else {return p+1; }
}
int ym(int p)
{ // ok
  if (p>-1&&c2my(p)==1)
    {return -1;}
  else { return p-1;}
}

int xp(int p)
{ // ok
  if (p>-1&&c2mx(p)==xres)
    { return -1;} 
  else
    { return p+yres;} 
}
int xm(int p)
{ // ok
  if (p>-1&&c2mx(p)==1)
    { return -1; }
  else { return p-yres;}
}
int zp(int p)
{ // ok
  if(p>-1&&c2mz(p)==zres)
    {return -1; }
  else {return p+xres*yres;}
}
int zm(int p)
{ // ok
  if(p>-1&&c2mz(p)==1)
    {return -1;}
  else{ return p-xres*yres;}
}

