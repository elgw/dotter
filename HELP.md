<link rel="stylesheet" href="style.css">

<!--
<script src='https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.0/MathJax.js?config=TeX-MML-AM_CHTML'>
</script>

<script type="text/x-mathjax-config">
  MathJax.Hub.Config({tex2jax: {inlineMath: [['$','$'], ['\\(','\\)']]}});
</script>
-->

[Changes](README.md)
[Bugs](BUGS.md)
[Requests](REQUESTS.md)

![DOTTER LOGO](logo_758.jpg)

# Help

 * [Getting started](#GettingStarted)
 * [Installation](#Installation)
   * [Dependencies](#Dependencies)
   * [Instructions](#Instructions)
   * [Keeping Updated](#KeepingUpdated) 
 * [Workflow](#Workflow)
 * [Specific Topics](#SpecificTopics)
   * [Shifts and chromatic aberrations](#ShiftsCorrections)
 * [Troubleshooting](#Troubleshooting)

<a name="GettingStarted"/>

## Getting started
The best way to get introduced to the software is to ask someone
already using it!.

<a name="Installation"/>

## Installation

<a name="Dependencies"/>

### Dependencies
* OSX or Ubuntu - will not work on Windows
* GIT
* MATLAB
* The GNU scientific library, GSL
* A Compiler for C99 that works with Matlab

<a name="Instructions"/>

### Instructions
Get the code:
```
git clone git@github.com:elgw/dotter.git
```

Install GSL and pkg-config (requires [brew](https://brew.sh/))
```
brew install gsl
brew install pkg-config
```

Start MATLAB, and run `pathtool`, click 'Add Folder...', navigate to the `dotter` folder. Press 'Save' and then restart MATLAB.

From now on you should now be able to start
DOTTER with the command: `DOTTER` in MATLAB.

Next you need to compile some function written in C. Do so from the
menu: _DOTTER->Maintenanace->Compile C Functions_.

Most likely `mex` is not setup on you computer. How to do this varies
but on a mac you should install `XCode` first. Then run `mex -setup`
in MATLAB. Ask someone for help if you get stuck at this point. If you are on mac you might need to start MATLAB from command line (i.e., not using the icon) in order for the compiler to find all dependencies.

<a name="KeepingUpdated" />

### Keeping updated
Since the files are managed by GIT you can go to a terminal, `cd` to
the directory with the source codes and do a

```
git pull
```

The same thing is accessible from the menubar in DOTTER,
_DOTTER->Maintenance->Update_

#### Downgrading
In case that you want to use an older version, `git` is your friend.
To see all old version use (in terminal)

``
git log --pretty=format:'%h %ad | %s%d [%an]' --graph --date=short 
``

and then to get a specific version, use

```
git checkout <hash>
```

Example:

```
git log --pretty=format:'%h %ad | %s%d [%an]' --graph --date=short
* 57a3363 2017-11-24 | v 0.471 [erikw]
* 8d18c29 2017-11-22 | v 0.462 [erikw]
...
git checkout 8d18c29

```

<a name="Workflow"/>

## Workflow

The general workflow is this:

 * Acquire images
 * Convert native image formats such that `nd2` to `tif` using DOTTER.
 * Correct for chromatic aberrations using calibration images of beads
 * Detect/segment nuclei and dots
 * Select dots
 * Analyze the results, plot and export

<a name="SpecificTopics"/>

## Specific Topics

<a name="DotDetection"/>

### Shifts and chromatic aberrations

Files: `df_cc_*.m`.

This section describes geometric aberrations to microscopy images and what we
can do about them. In short there are two major sources, 

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
3. $\hat{x}_i^A = x_i^A + \delta_i$, $\hat{A} = \\{ \hat{a}_i^A
   \\}$
4. Match $\hat{A}$ vs $\hat{B}$ as in step 1 and 2 above, assume that
   two dots corresponds to the same bead whenever $\delta_i|<T$,
where $T$ is a threshold set so to tolerate the small non-linear
deformations caused by chromatic aberrations.
5. In the end, a set of matched points is returned, $\\{ (x_i^A,
   x_j^B) : |(x^A_i+delta-x^B_j)|<T \\}$

 * _Algorithm 2_ -- find polynomial transformation between channels.

 This is quite straight forward, see
[kozubek,2000](http://dx.doi.org/10.1046/j.1365-2818.2000.00754.x).
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


<a name="Troubleshooting"/>

## Troubleshooting

In general, please report all errors and itches to
<erik.wernersson@scilifelab.se> in order for him to
improve DOTTER.

 * _I set a value somewhere and now I can't change it!_

   DOTTER does save data that is not specific to any experiment in the
   folder `~/.DOTTER/`. Remove the whole folder to reset the
configuration. This includes default directories, window placements
and emission wavelengths for fluorophores.

