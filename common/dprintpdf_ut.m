function dprintpdf_ut()

disp(' basic usage')
tempfile = sprintf('%sdprintpdf.pdf', tempdir());
f = figure;
dprintpdf(tempfile)
close(f)

end