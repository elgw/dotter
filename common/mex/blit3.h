#ifndef _blit3_h_
#define _blit3_h_

// for blit3g
enum _photonw {
  xyz_volume,
  xy_plane,
  mid_point};
typedef enum _photonw photonw;

double rand_range(double , double );

/* Place 3D Gaussian shapes defined by D into the volumetric image T
 * photonw says if the 7th column of D specifies the total number 
 * of photons, the number of photons in the plane or the number of
 * photons in the central pixel. I.e., how the Gaussian should be scaled.
 * Supports sub pixel precision coordinates. 
 */

int blit3g(double * T, // Target image
    uint32_t Tm, uint32_t Tn, uint32_t Tp, // Rows, Columns, Slices of T
    double * D,  // Table with point to blit, x, y, z, nphot, sigmax, sigmay, sigmaz
    size_t nD, // Number of points
    photonw pw, // says how nphot should be interpreted
    int one_indexing); // set to 0 if the coordinates in D are 0-indexed. 1 if 1-indexed

/* Similar to blit3g, however, in this case a volumetric image defined by
 * S is blitted to the coordinate given by (Pm, Pn, Pp)
 * Possible values for anchor:
 * 0 = corner
 * 1 = centered over P (not supported yet)
 */
void blit3(double * T, uint32_t Tm, uint32_t Tn, uint32_t Tp,
    double * S, uint32_t Sm, uint32_t Sn, uint32_t Sp,
    int64_t Pm, int64_t Pn, int64_t Pp,
    int8_t anchor);
 
int unit_tests(void);

#endif
