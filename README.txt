This file contains ideas and bugs for DOTTER 

- Implement centre of mass as another feature. That would be a really
  fast method with quite high precision, at least for sparse dots. Use lpthreads.
- USE XML/JSON./... for meta data (easier to juggle with data, less dependant on
  MATLAB).
- Use found dots to decrease the weighting, W, locally. That will
  reduce the effect of having dots closely packed. Compare to what is
in DAOPHOT.
- When using DoG for ranking of dots, compensate for dots being close
  by weighting up.
- More unit tests
- For threshold selection, histogram of all dots after dog/gcorr
  filtering
- Dots per cell vs threshold, a standard plot that should be generated
  automatically.

> Add a blob detector. 
get_blobs, get_blobs_ui
 There are problems associated with really
  strong blobs right now, mostly that several dots are found in them
which depletes the number of dots in other regions. Use information
about blobs to: a) Join multiple
  dots in a blob into one dot. b) Create diagnostics
The most obvious approach is region growing down to half max, see
also:
  Kittler, “Region Growing: A New Approach,” IEEE Trans. Image
  Process., vol. 7, no. 7, pp. 1079–1084, July 1998. Or go for active
  contours... functional?

> Compare different methods to count the number of photons in dots:
- Deconvolution
- DoG
- Central Pixel value
- Region growing and integration
- ...

> Automated screen shots in the unit tests.
> Add M.nd2file string
> Add test images to a special repo
> Create a clean file structure, and rename functions consistently
