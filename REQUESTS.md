<link rel="stylesheet" href="style.css">

[Changes](CHANGELOG.html)
[Bugs](BUGS.html)
[Help](HELP.html)

![DOTTER LOGO](dotter/logo_758.jpg)

# Requests and things to do

 * Measurements:
   * Volume of dot clouds (i.e. don't care about what cluster). Report
     back to Eleni when done.

 * in `setUserDotsDNA` 
   * Set threshold per nuclei.
   * Apply dot selection to one channel at a time
   * Specify the max number of dots per cluster.
   * Apply max dist before doing the hierarchical clustering.
   * Kick out cells? Set a flag if they are to be used or not.
   * Draw a rectangle to remove all dots.
   * Indicator about non-specific signals, i.e., very bright and
   appearing in multiple channels. (2017-08-29).
   * Add a symbol to indicate overlapping dots

# On a higher level/or for the next version

 * For reproducibility and debugging, be better at logging what has
  happened. Store all settings in all algorithms to text files! Save
time stamps!

 * Go for a more modular approach, i.e., define plugin interfaces for
  everything that can be done in more than one way.

 * Structure the code better to keep to DRY. If it is to hard without
  using OOP, switch to OOP.

 * Move to github
   * First: cleanup the codebase
   * Can it be setup so that pulls are still done through my computer?

