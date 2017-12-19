# Patches and small scripts

This folder contains fixes and small scripts that were supposed to be run only once.

## 20171213
 * Export (x,y,z,intensity) per nuclei to Silvano, he will use it as input
   for the topological data analysis.

## 20171201, for Eleni
 * Was TMR missing in a folder? No, but it was not shown in DOTTER, fixed.

## 20171128, patch for Quim
 For some reason the meta data contained double channel names:
       dapifile: '/Volumes/microscopy_data_2/Temporal/GPSeq analysis/Analysis/HAP1/iJC852_20171004_001/dapi…'
      nTrueDots: [2 2 2 2 2 2]
       channels: {'a594'  'a594_____'  'cy5'  'cy5_____'  'tmr'  'tmr_____'}
 Probably dots were detected twice and the image names were changed in
 between.

## 20171124
 * Fixes a problem with bounding boxes not numbered correctly, probably when there were nuclei with no pixels.
