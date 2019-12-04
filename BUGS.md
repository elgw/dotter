<link rel="stylesheet" href="style.css">

[Changes](README.md)
[Requests](REQUESTS.md)
[Help](HELP.md)

![DOTTER LOGO](logo_758.jpg)

# Bugs

B7 `df_fwhm1d` crashes matlab when the input contains nan values

B6 In `setUserDotsDNA` when dots have the same x,y, different z. It
is impossible to select/deselect one of them. Possible solution: when
in non-projected mode only show dots at current plane. Or show a list
of nearby dots when there is an ambiguity.


# Closed
B5 20170927, `df_com3` not compiling on Eleni's computer. (solution:
install pkg-config using brew)

B4 2017-09-27.` ~/matlab/startup.m` not run on Eleni's computer by
default. (solution: start matlab from terminal)

B3 2017-09-27. Closed, Could not be recreated. Possibly fixed. AM: I am having a problem with Dotter while selecting the dots in the nuclei for DNA FISH. In some channels I selected the dots and when I moved to the next channel or nuclei, the previous dots selected were "forgotten". This doesn't happen everytime but in random images. Did this happen any other time before? 
  Source of the problem `setUserDotsDNA.m`, most likely in `gui_dotClick`. 

B2 2017-09-04, could not be recreated. Bug: When exporting userDots, multiple values for fwhm and value. Reported 2017-08-30.

B1 2017-09-04, fix in `get_nuclei_dapi_ui()/setZauto()` Bug: The upper z-limit in the cell-segmentation seems to be stuck, i.e.,
   not changing intelligently. Reported 2017-08-29.
 
