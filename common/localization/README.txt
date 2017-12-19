Ways to go:
 . Simulations for evaluation
 . Fitting of an arbitrary number of points at the same time
 . 3D fitting from PSF, theoretical or measured
 . More user friendly, ... save and load localization results automatically
 . Smarter data structure for the dots, that stores information about fitting etc
 . Re-factorization.

To do: 
- Verify that the fitting windows are round, and not square.
- Use the clustering result for simultaneous fitting of larger dot clusters.
- Use the implementation in the GNU Scientific Library for NM
     https://www.gnu.org/software/gsl/manual/html_node/Multimin-Examples.html
- Add ML localization (Appriximately there, Gaussians approximating Poissonian)
- How to sort dots that are note fitted? - DoG is good
- What to do when fitting doesn't converge, and how to handle fitting
  when errors are large... sometimes for anisotropic regions, a model
  with several dots could be used (will produce a more likely result. 
- Heuristics to try: 1) Find all dots roughly, 2) fit sigma, 
  3) remove all of them from the image, 4) put back one at a time and fit
  the parameters. . By doing this, the effect of nearby dots in lowered, 
  although not completely removed. Might be an alternative for really dotty
  FISH images. As an alternative, the fitted dots can be removed directly 
  after fitting. Assuming the largest are fitted first, that would remove 
  quite much of possible bias.
- The bcluster.c crashes when no input points
- Use a global background estimation. In contrast to the current
  procedure where the background is estimated per dot. Gain: speed.
- Study when the input is pure noise.
- Create calibration images, be inspired by A. Allalou.
- Incorporate nuclei segmentation.
- Click on dot to get information.
- Implement a BLIT function to blit the PSF onto local maximas (kind
  of deconvolution but really local).
- Multiple pixelated images to a high res PSF.
- Use GNU scientific library for the optimization (sub pixel).

Done:
- Estimation of PSF from DOTS (external script), deconv/estimatePSF.m

Features:
 - Show sum projection or slide throught slices.
 - Click and drag to change the number of visualized dots
 - Fitting in the plane where dots are detected
 - Dot detection using several methods
 - z-localization in an interpolated line through the fitted xy-coordinates

Notes:

Lower errors/higher likelihood when sigma is fitted, I fitted the 125 first dots:
s.fitSigma  = 1
>> sum(PFIT(1:125, 5))
   3.0094e+05
 vs:
s.fitSigma = 0
   >> sum(PFIT(1:125, 5))
 3.9715e+05

§ Independent parameters
According to [abraham2009quantitative], "estimation of the photon
detection rate and is uncorrelated with the estimation of the
location" ... this has practical consequences, i.e., much faster
fitting can be implemented since most (assumedly) most optimization
routines are worse than linear in the number of estimation parameters.

§ Reasons to fit xy independently of z:
- Less chance of overlapping PSFs from other dots, since the domain is
  2D instead of 3D. Less errors due to assymetric psf?
- xy localization less sensitive to psf errors due to uneven
  z-stepping by the moving stage.

