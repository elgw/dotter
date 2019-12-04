#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <inttypes.h>

#include <tiffio.h> 
#include "bim.c"

// Headers
void printArray(uint16_t * , uint16_t );
int readTif(bim * , char *);

void printArray(uint16 * array, uint16 width)
{
  for (uint32_t i=0;i<width;i++)
    printf("%u ", array[i]);

  printf("\n");
}

int main(int argc, char ** argv)
{
  if(argc != 2)
  {
    printf("Usage: %s filename.tif\n", argv[0]);
  }

  bim image = bim_new(3);

  if(readTif(&image, argv[1]) != 0)
  {
    printf("Failed to open %s\n", argv[1]);
    return 1;
  }

  bim_free(&image);

  return 0;
}

int readTif(bim * image, char * fName){

  TIFF * tfile = TIFFOpen(fName, "r");

  if(tfile == NULL)
    return 1;

  uint32_t w, h;

  TIFFGetField(tfile, TIFFTAG_IMAGEWIDTH, &w);           // uint32 width;
  TIFFGetField(tfile, TIFFTAG_IMAGELENGTH, &h);        // uint32 height;

  printf("File : %s\n", fName);
  printf("Size : %u x %u\n", w, h);

  tdata_t buf = _TIFFmalloc(TIFFScanlineSize(tfile)); 
  uint16_t  nsamples;
  TIFFGetField(tfile, TIFFTAG_SAMPLESPERPIXEL, &nsamples);

  printf("nsamples: %u\n", nsamples);
  for (uint32_t s = 0; s < nsamples; s++)
  {
    for (uint32_t row = 0; row < h; row++)
    {
      TIFFReadScanline(tfile, buf, row, s);
    }
  }

  image->V = malloc(w*h*sizeof(double));

  // Try to read some data
  uint32_t npixels = w * h;
  uint32_t * raster = (uint32_t *) _TIFFmalloc(npixels * sizeof (uint32_t));
  if (raster != NULL) {
    // ReadRGBAImage is the highest level of interface, does not
    // above the tile/raster level
    if (TIFFReadRGBAImage(tfile, w, h, raster, 1)) {
      for(int kk=0; kk<10; kk++)
        printf("%lu ", (unsigned long) raster[kk]);
      printf("\n");
    }
    _TIFFfree(raster);
  }

  // Go through all directories
  int dircount = 0;
  do {
    dircount++;
  } while (TIFFReadDirectory(tfile));

  printf("Dirs : %d\n", dircount);

  image->V = malloc(w*h*dircount*sizeof(double));  

  TIFFClose(tfile);

  return 0;
}
