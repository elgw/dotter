<link rel="stylesheet" href="style.css">

[Requests](REQUESTS.html)
[Bugs](BUGS.html)
[Help](HELP.html)

![DOTTER LOGO](dotter/logo_758.jpg)

# Changes to DOTTER 

## 0.495
 * K-means clustering does now support auto detection of the number of
   clusters as well as constraints on the maximum number of dots per
cluster and channel.
 * Same structure for all tests to run, they end with `_df.m`.
 * Bugs detected in several of the `.c` files, `mwSize` was not used.
   Corrected.
 * Other minor bug fixes.
 * New measurements available for `df_plot`.

## 0.486
 * Adding the option to import masks generated externally.

## 0.485
 * `df_plot` did behave unreasonable if images with mixed sets of
   channels were loaded. This is prevented now by refusing to load
such images.
 * Added more measurement options.

## 0.483
 * Moved to github.

## 0.479
 * Changes in detection of local maxima. Previously a
   3x3x3 unit cube was used. Now a 3D 'plus' is used. Might be too
sensitive for really noisy images.

## 0.478
 * SetUserDots 
   * Dots can be added with the right button
   * The closest dot is picked (behaviour is still undefined if there
     are two identical dots)

## 0.471
 * Bug fix, MaxDots would not be applied to the last channel.

## 0.462
 * Support for up to eight clusters in `setUserDotsDNA`
 * Hierachical clustering, need some validation before use.

## 0.460, 2017-11-21
 * Contours for dilated nuclei also shown

## 0.456, 2017-11-17
 * Changes in `setUserDotsDNA`:
  * Possible to turn on/off markers, per class
  * Plots for dots per nuclei in the current slide
  * Possible to jump directly to any nuclei.

## 0.455, 2017-11-17
 * First clustering plugins put in place.

## 0.454, 2017-11-16
 * _Visual thresholds_ works again in setUserDotsDNA
 * Major improvements in the export GUI.
 * Docked the nd2tif conversion dialog into DOTTER.
 * Rewrote the logistics beyond the clustering in setUserDotsDNA so
   that it will be possible to write new clustering methods as
plugins.

## 0.449, 2017-11-15
 * Added missing help section.
 * Linked axes when plotting fwhm.

## 0.446, 2017-11-07
 * Fixed a bug in `A_settings`, it did not care about what ranking
   method that was used before.
 * Set the number of dots to calculate fwhm for to be variable and
   increased the default number.
 * Set _nkmers_ to 96 by default.

## 0.440, 2017-11-03
 * Updated functions for correction of chromatic aberrations. The
   major change is how the dots are clustered which much smarter now.
On top of that the API is completely rewritten except for the piece of
GUI used to create the cc-files that needs to be refreshed at some
point. Properties:
   * Handles bead samples with more dots without getting puzzled and
     seems to be more stable in general.
   * Much faster in correcting 3D images.
   * Can be applied in `df_plot` as well as when exporting userDots.
   * cc-files can be 'viewed' for some quick statistics.

## 0.428, 2017-10-30
 * 'setUserDotsDNA'
   * Looking for the double number of dots for G2 nuclei.
   * Showing that the outlier distance is given in pixels.
   * Load/save metadata ok

## 0.427, 2017-10-30
 * Working towards integration of DNA- and RNA-FISH analysis.
 * New functions to compare dot pickings, `df_compareUserDots` and
   `df_compareUserDotsGUI`.
 * `setUserDotsDNA` now dilates the mask by default 10 pixels before
   assigning dots to nuclei.
 * Set a max area in the cell segmentation gui `get_nuclei_dapi_ui` to
   15000 pixels by default. No key to change this but the property is
accessible by pressing `e`.

##  0.425, 2017-10-24
 * `get_nuclei_manual.m` got some improvements. It is now possible to
   refine the contours with the button `s`.
 * Removed any non alpha-numeric character from channel names when
   converting to tif.
* Useful example on how to update the name of the DAPI file reference
  for all NM files in a folder:
```
files = dir('*.NM');
for kk = 1:numel(files)
    load(files(kk).name, '-mat');
    M.dapifile  = regexprep(M.dapifile,'_*','_')    
```   
* Better _glow filter_ in the nuclei segmentation.
* HP filter enabled by default in the nuclei segmentation
* Fixed flipped image in some cases (the image was display upside
  down)
* Fixed some minor things in the `setUserDotsDNA`, in some cases dots
  could not be clicked.
* Fixed some broken keyboard shortcuts in `setUserDotsDNA`.

## 0.416, 2017-10-13
 * setUserDots will now avoid fields with 0 nuclei instead of
   crashing.

## 0.415, 2017-10-12
 * Major changes in `setUserDotsDNA` which includes filtering on Z and
   FWHM. Also some batch processing included now.

## 0.410, 2017-09-29
 * `df_fwhm` is now about 14x faster by using a new function to
   determine fwhm from 1d lines that I implemented in C `df_fwhm1d`.
Compared to the previous routine, `getw`, `df_fwhm1d` is about 1000x
faster.
 * The tool to correct for chromatic aberrations in images seems to
   run well again. It was broken at some point when a bunch of
functions were renamed.

## 0.390, 2017-09-21
 * New plot tool, accessible from _DNA-FISH->basic plots_. File:
   `df_plot`.
 * Changes in menu
 * Bug fixes in `df_getNucleiFromNM`

## 0.388, 2017-09-20
 * Dot's can now be localized using weighted centre of mass via `df_com3`. This option is enabled in _nuclei -> find nuclei and dots_. Will be default after some more testing.
 * Better integration with DAPI threshold (an upper limit on the
   integrated DAPI intensity). A DAPI threshold is picked already
directly after nuclei are segmented and is used when selecting
userDots and when exporting userDots. 
 * Old data sets have to be given a DAPI threshold from _nuclei->set upper DAPI threshold
  for calc folder_.

## 0.387, 2017-09-19
 * Now asks for number of kmers per probe for new experiments, this
   information is saved to the metadata, M.
 * By default generates plots showing dot threshold vs how similar the
   distribution of dots per nuclei is to a binomial distribution, for
an explanation, see the notes from the GM 20170915.
 * `df_setNUserDotsDNA` now compatible with `setUserDotsDNA` in the
   sense that dots can be edited in the later now.
 * Fixed a bug in `setUserDotsDNA` which caused dots from all channels
   to be reset when the threshold was changed for one channel.

## 0.385, 2017-09-13
 * New function: `df_getFWHMstrongest`, calculates the FWHM for the
   strongest dot for each nuclei for all fields in a calc-folder.
Useful for setting limits on FWHM later on. Found in menu: _dots->Get
fwhm for strongest dots_.

## 0.378, 2017-09-11
 * `D_integralIntensity` now outputs the sum, mean and std for each
   nuclei and channel.
 * `df_dotsPerNucleiMM` (which has to be called manually by typing the
   function name in MATLAB) measures the number of dots per nuclei by the
   following procedure:
   * For each nuclei and non-dapi channel, measure mean and standard deviation
   * Identify pixels stronger than mean+2.5 x std.
   * Each region with 2 or more pixels is counted as a dot.

## 0.375, 2017-09-07
 * Fixed some bugs in `A_cells` introduced on 0.373.

## 0.373, 2017-08-30
 * When running _find nuclei and dots_ the user is now asked to
   select which fields to process. Should be useful to correct
individual fields. These changes are implemented in `A_cells()`

## 0.372, 2017-08-30
 * It is now possible to delete nuclei in the manual segmentation UI
   by right clicking inside them. This feature was asked for.
 * factorization, added `df_dPeriphery.m` for calculation of distance
   to periphery for a mask and some dots.
 * Closed bug B1 and B2.
* Added a warning in the cell-segmentation interface if the
   most-in-focus slice is close to the first or last slize.

## 0.371, 2017-08-30
 * Also converts `czi`-files from the confocal. This was already
   included in the bioformats package so no extra packages needed.
 * Eliminated a warning message from
   `A_generate_segmentation_preview.m` when no nuclei were segmented
for a field of view.
 * Fixed error in `A_cells_generate_dot_curves.m`. Did not save the
   correct window to the `...dpn.png` images.
 * made `df_getNucleiFromNM` less verbosive. 

## 0.370, 2017-08-28
 * New functionality: `df_setNUserDotsDNA` can be used to set a
   certain number of dots for each nuclei. 
 * Spotted and corrected a bug in `twomeans.m`. When only two dots
   were given as input they were sometimes assigned the same starting
  label. The input is now balanced so that there are equal number of
dots in the initial guess.

## 0.365, 2017-08-23
* DNA-FISH/Get basic properties of clusters/alleles
  Calls `DOTTER.m/@userDotsAlleles` to export a table for a set of NM
files containing
  * File name
  * Nuclei number
  * Number of dots for each allele
  * Distance between alleles, measured as centroid distance
  * Distance between each allele and the periphery of the nuclei
  * Volume of each allele
  
* setUserDotsDNA, properly closes the climSlider before opening a new
  one -- not cluttering the screen with windows any more.
* Fixed export to 'base' of DAPI and Area when measuring those
  properties. I.e., when doing 'Get nuclei DAPI intensity and area from NE files', then it is possible to export or visualize from the MATLAB command window

```
scatter(A,D)
xlabel('Area [pixels]')
ylabel('DAPI [au]')
```

* `df_getNucleiFromNM.m`, 
  * added _select NM files(s)_ to the prompt
  * Now also exports the meta data, `M` from each field and each
    nuclei point to a `M` using the field `.metaNo`
  * this function also appends clusters to each N, N.cluster{} which
    is convenient for further processing

Example:
```
[N, M] = df_getNucleiFromNM(); # opens file selector
Loaded 11 files, 238 nuclei, 420 clusters into M and N
185 nuclei has two clusters
```

## 0.355, 2017-08-21

* Improvements in the interface when exporting dots
* Improvements in the interface when measuring DAPI contents and area
* Showing free disk drive space when starting conversion from nd2 tif
* Removed green background colours in some dialogue boxes.
* Late is better than never, introduced this changelog.


