% 
% Segmentation using a Gaussian Markov Random Field Model described
% in 
%
% Exact Minimim A Posteori Estimation for Binary Images
% D. M: Grieg, B. T. Porteous and A. H. Seheult
%
% Usage:
% In: 
%  vol, a 8 bit volume. All other parameters should be double
%  class1 and 2 defines the two classes
%  beta is the homogeniety parameter. Try with 1 first
%
% seg=mrfGC(vol,[class1.mean,class1.variance], [class2.mean,class2.variance], beta););
% Implementation, erikw
