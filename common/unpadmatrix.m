function [ut]=unpadmatrix(in,n)
%%function [ut]=unpadmatrix(in,n)
% Remove the outer n layers (default n=1) from in

if~exist('n')
  n=1;
end

if size(in,3)>2
     ut = in(n+1:end-n, n+1:end-n, n+1:end-n);
else
    ut = in(n+1:end-n, n+1:end-n);
end

