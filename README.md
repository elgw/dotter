<link rel="stylesheet" href="style.css">

![](logo_758.jpg)

<a name="top"/>

# DOTTER

DOTTER is a MATLAB toolbox/pipeline developed at the
[bienkocrosettolabs](https://bienkocrosettolabs.org/).
The purpose of the pipeline is to extract dots and segment nuclei in wide field
images of [FISH](https://en.wikipedia.org/wiki/Fluorescence_in_situ_hybridization) experiments.

## Caveats
 - The software is developed for internal use only. At this time we can not
   give any support or help.
 - The software is neither polished or bug free, and has a large backlog, due to
   other priorities. Hopefully I'll find time to fresh it up some day.

 * <a href="#Installation">Installation</a>
   * <a href="#compile-max">Compile C functions on MAC</a>
   * <a href="#compile-linux">Compile C functions on Linux</a>
   * <a href="#upgrade">Upgrade</a>
   * <a href="#downgrade">Downgrade</a>

 * <a href="#usage">Usage</a>
   * <a href="#bugs">Bugs and Feature Requests</a>
   * <a href="#workflow">Workflow</a>
   * <a href="#shifts">Shift corrections and Chromatic Aberrations</a>
   * <a href="#exportColumns">Exported dot tables</a>
   * <a href="#QA">Questions and Answers</a>

<a name="installation"/>

## Installation

To use DOTTER the following is required:

 - OSX or Ubuntu - will not work on Windows
 - GIT
 - MATLAB, R2018B or above.
 - The GNU scientific library, GSL
 - A Compiler for C99 that works with Matlab

To install it

 1. Get a local copy of the repository, either by downloading it or using `git clone`
 2. Add DOTTER to paths. In MATLAB, go to 'Environment', 'Set Path', and then press 'Add Folder' and navigate to find the folder with DOTTER.
 3. Restart MATLAB, when you start it, there will be a message like this in the MATLAB terminal:


```
DOTTER version 0.708
BiCroLabs 2015-2021
Session started 2021-10-27 08:59:36
```

 3. Start DOTTER by typing `DOTTER` in MATLAB.
 4. Compile some of the functions that are written in other languages, in DOTTER
    go to 'DOTTER'->'Maintenance'->'Compile C functions'. If this does not work
    right away, see the expanded instructions below.

<a name="compile-mac"/>

### Compile C functions on MAC

 1. Install the package manager brew.
 See the latest [install instructions](https://brew.sh/).
 2. Install GSL and pkg-config from the terminal
 ``` shell
 brew install gsl
 brew install pkg-config
 ```

 3. Compile in MATLAB

To compile in MATLAB you need to have [XCode](https://developer.apple.com/xcode/) installed which you can get from the App Store. Unfortunately this is a rather big package which will take some time to get installed. When XCode is installed, ask MATLAB to look for the C compiler:
``` matlab
>> mex -setup
```

Figure out where MATLAB is installed (it is probably somewhere else on your system)
``` matlab
>> fullfile(matlabroot, 'bin')
 '/home/donald/MATLAB_R2017b/bin'
```

Then in a terminal
``` matlab
cd /home/donald/MATLAB_R2017b/bin
./matlab
```

open DOTTER, by
``` matlab
DOTTER
```
Navigate the menu and select: `DOTTER`->`Maintenanace`->`Compile C Functions`. Please note the output in the MATLAB console, if there are any errors, please try to understand what they are. If you get stuck here, please file a bug report.

<a name="compile-linux"/>

### Compile C functions on Linux
On linux you will need to install:

 * git
 * GSL libraries

<a name="upgrade"/>

### Keeping updated / Upgrade
If DOTTER is installed from a zip file, repeat the installation instructions.

If DOTTER was installed via git GIT you can go to a terminal, `cd` to
the directory with DOTTER and do a

``` shell
git pull
```
Then build it C-functions again.

<a name="downgrade"/>

### Downgrading
In case that you want to use an older version, `git` is your friend.
To see all old version use (in terminal)

``` shell
git log --pretty=format:'%h %ad | %s%d [%an]' --graph --date=short
```

and then to get a specific version, use

``` shell
git checkout <hash>
```

Example:

``` shell
git log --pretty=format:'%h %ad | %s%d [%an]' --graph --date=short
* 57a3363 2017-11-24 | v 0.471 [erikw]
* 8d18c29 2017-11-22 | v 0.462 [erikw]
...
git checkout 8d18c29
```

<a name="usage"/>

## Usage

At this time there is no manual or user guide, hands on knowledge is passed down
from one user to the other.

<a name="bugs"/>

### Bugs and Feature Requests
Please use the [issues](https://github.com/elgw/dotter/issues) page on github.

<a name="workflow"/>

### Workflow

The general workflow is:

 * Acquire images
 * Convert native image formats such that `nd2` to `tif` using [radiantkit](https://github.com/ggirelli/radiantkit).
 * Correct for chromatic aberrations using calibration images of beads
 * Detect/segment nuclei and dots
 * Select dots
 * Analyze the results, plot and export

<a name="shifts"/>

### Shifts and chromatic aberrations

There are two major sources of geometric distortions to the images,

 1. Shifts between channels, caused mainly by incorrectly aligned
    mirrors in the optical path (they might not be mechanically
    stable and wiggle around).
 2. Chromatic aberrations, including a wavelength dependent
    magnifications and some other non-linearities.

#### Detecting them

These disturbances are easiest to see when imaging beads, small
particles which emit light at all wavelengths that we are interested
in. In the ideal case, a field of view with beads captured at any
wavelength should look the same -- but they look different.

Given an image with beads, we detect and localize dots from each
channel, to get $x_1^A, x_2^A, ...$ for channel A and $x_1^B, X_2^B,
...$ for channel B, etc.

First we have to identify which dots corresponds to the same bead.

 * _Algorithm 1_ -- translation detection
 1. For each $x_i^A$, find the closest point in channel B,
    $m_B(x_i^A)$.
 2. Look at the distribution of $\delta_i = (x_i^A-m_B(x_i^A))$. Assumption: in
    most cases the closest point to $x_i$ in channel B corresponds to
the same bead. $\hat{\delta} = \hat{r}
(cos \hat{\theta},\sin \hat{\theta})$.
$\hat{r}=median(\delta_i)$, $\hat{\theta} = atan2(\sum\delta_i)$.
3. $\hat{x}_i^A = x_i^A + \delta_i$, $\hat{A} = { \hat{a}_i^A
   }$
4. Match $\hat{A}$ vs $\hat{B}$ as in step 1 and 2 above, assume that
   two dots corresponds to the same bead whenever $\delta_i|<T$,
where $T$ is a threshold set so to tolerate the small non-linear
deformations caused by chromatic aberrations.
5. In the end, a set of matched points is returned, ${ (x_i^A,
   x_j^B) : |(x^A_i+delta-x^B_j)|<T }$

 * _Algorithm 2_ -- find polynomial transformation between channels.

 This is quite straight forward, see
[kozubek](http://dx.doi.org/10.1046/j.1365-2818.2000.00754.x).
Some notes A) Order 2 is used by default since order 3 does not show
an significant advantage. B) In z, a constant offset is used rather
than a polynomial model.

#### In practice

Whenever an important experiment is about to be image,

 1. Prepare and image beads for all relevant channels.
 2. Create a correction file (.cc) in DOTTER.

 3. Apply the correction, either on A) images directly or B) when dot
    selection/detection is done. (A) is the obvious choice when the
shifts are large, otherwhise it will be hard to determine which dots
that belong to which nuclei. Alternative B) can always be used (just
make sure that A was not applied before).

<a name="exportColumns">

## Exported dot tables
The columns in the csv files produced by 'DOTTER'->'Measure'->'Export Dots' are:

 1. `File` -- The NM file that the dot was stored in.
 2. `Channel` -- The flourophore or channel name of the images file, i.e. in an image called `tmr_001.tif` the value in this column will be `tmr`
 3. `Nuclei` -- The nuclei number in this FOV. The same as the pixel value of `M.mask`
 4. `x,y,z` -- the coordinate of the dot, integers if no fitting was used or if the fitting failed.
 5. `Value` -- Depending on how the dots were ranked, the value of the ranking (for example the DoG value if DoG was used).
 6. `FWHM` -- FWHM in 2D based on 1D lines crossing the dot in x and y.
 7. `SNR` -- Signal To Noise Ratio, defined by `df_snr`
 8. `NSNR` -- Signal To Noise Ratio relative to the nuclei, see `df_nsnr`
 9. `Label` -- The label given to the point, will be set if any clustering was used.
 10. `PixelValue` -- The pixel value, i.e., the value of the image over the dot.
 11. `FWHM_fitting` -- FWHM determined by fitting (if enabled).
 12. `lamin_distance_2d_pixels` -- 2D lamin distance given in pixels.

<a name="QA"/>

## Questions and Answers
 * _I set a value somewhere and now I can't change it!_

   Data that is not specific to any experiment is saved in the
   folder `~/.DOTTER/`. Remove the whole folder to reset the
   configuration. This includes default directories, window placements
   and emission wavelengths for fluorophores.

 * _Equations look funky on this page!_

    This document is converted to HTML by Pandoc and should look better when displayed from 'DOTTER'->'Help'.

<hr/>
Didn't find what you were looking for? Please file a <a href="#bugs">bug report</a>.

## License

DOTTER includes the following libraries / external code:

 - [bfmatlab](https://docs.openmicroscopy.org/bio-formats/6.3.1/users/matlab/index.html)
   [GNU Copyleft](http://www.gnu.org/copyleft/)
 - geom3d from [matGeom](https://github.com/mattools/matGeom/)
   Copyright (c) 2019, David Legland
   [license](https://github.com/mattools/matGeom/blob/master/LICENSE.txt)
 - structdlg
   Copyright (c) 2005, Alon Fishbach
 - [maxflow](http://pub.ist.ac.at/~vnk/software.html)
   Copyright 2001-2006 Vladimir Kolmogorov and Yuri Boykov
   GPL

<a href="#top">top</a>
