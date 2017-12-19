#ifndef _blit3_h_
#define _blit3_h_

// for blit3g
enum _photonw {
  xyz_volume,
  xy_plane,
  mid_point};
typedef enum _photonw photonw;

double rand_range(double , double );
void blit3(double * , uint32_t , uint32_t , uint32_t ,
    double * , uint32_t , uint32_t , uint32_t ,
    int64_t , int64_t , int64_t ,
    int8_t );
int blit3g(double * , uint32_t , uint32_t , uint32_t ,
    double * , size_t , photonw, int);
int unit_tests(void);

#endif
