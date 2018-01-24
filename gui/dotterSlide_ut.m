function dotterSlide_ut()

% Open and close the window, should not crash

disp('-> dotterSlide')
% 2D image, non-square
t = dotterSlide(rand(1000, 2000), [1024*rand(100,1) 2000*rand(100,1), rand(100,1), (1:100)']);
close(t)

% 3D image, no dots
t = dotterSlide(rand(1024,1024,60), []);
close(t)


end