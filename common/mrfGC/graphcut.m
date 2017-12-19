%
% function result=graphcut(trimap,cost);
%
% Computes the optimal boundary separating background and
% foreground, as given by trimap.
%
% trimap: An image where all pixels are labelled as 
%         background (0),
%         foreground (255), or
%         unknown    (128)
%
% cost:   A gray-scale image giving the cost of placing the cut at a
%         certain pixel.
%
% Both input images must be of type uint8, and can be either 2d or
% 3d.
%
% Author: Filip Malmberg, filip@cb.uu.se
