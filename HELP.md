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
 * [Installation Instructions](#Installation)
   * [Keeping Updated](#KeepingUpdated)
 * [Workflow](#Workflow)
 * [Specific Topics](#SpecificTopics)
   * [Shifts and chromatic aberrations](#ShiftsCorrections)
 * [Troubleshooting](#Troubleshooting)
 * [Dependencies](#Dependencies)

<a name="GettingStarted"/>

## Getting started
DOTTER is still full of surprises and could for sure be more intuitive. The best way to get introduced to the software is to ask someone
already using it!

As user you are expected to report bugs and come with [suggestions for improvements](https://github.com/elgw/dotter/issues)! Help is also wanted in extending the documentation.

<a name="Installation"/>

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


## Dependencies
* OSX or Ubuntu - will not work on Windows
* GIT
* MATLAB, R2018B or above.
* The GNU scientific library, GSL
* A Compiler for C99 that works with Matlab
