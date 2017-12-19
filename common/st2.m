function [varargout] = st2(I, dsigma, tsigma, parameters)
%% function [varout] = std2(I, dsigma, tsigma)
% Gradient structure tensor of 2D image.
% In:
%  I: image
%  dsigma: sigma for derivatives
%  tsigma: sigma for component smoothing
%  parameters: one or several of 'l1', 'l2', 'det', 'tr' 
%
% Out:
%  l1/l2, first/second eigenvalue
%
% To do:
%   also return eigenvectors

if nargin ~= 4
    disp('Wrong number of input arguments')
    return
end

I = double(I);
padding = 10;
I = padarray(I, [padding, padding], 'replicate');

dx = gpartial(I, 1, dsigma);
dy = gpartial(I, 2, dsigma);
dx = unpadmatrix(dx,padding);
dy = unpadmatrix(dy,padding);


s11 = dx.*dx;
s12 = dx.*dy;
s22 = dy.*dy;

s11=gsmooth(s11, tsigma, 'normalized');
s12=gsmooth(s12, tsigma, 'normalized');
s22=gsmooth(s22, tsigma, 'normalized');

sdet = s11.*s22-s12.^2;
str = s11+s22;
% Eigenvalues
l1 = str/2+(-sdet+str.^2/4).^(1/2);
l2 = str/2-(-sdet+str.^2/4).^(1/2);

for kk=1:numel(parameters)
   measure = parameters{kk};
   
   if strcmp(measure, 'l1')
       varargout{kk} = l1;
   end
   
   if strcmp(measure, 'l2')
       varargout{kk} = l2;
   end
   
   if strcmp(measure, 'det')
       varargout{kk} = sdet;
   end 
   
   if strcmp(measure, 'tr')
       varargout{kk} = str;
   end
   
end