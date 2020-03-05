function a = array(varargin)
% A = array(a, b, c, ...) is equivalent to 
% A = [a(:) ; b(:) ; c(:) ... ]

N = 0;
for kk = 1:numel(varargin)
    N = N + numel(varargin{kk});
end

a = zeros(N,1);

pos = 1;
for kk = 1:numel(varargin)
    n = numel(varargin{kk});
    a(pos:(pos+n-1)) = varargin{kk}(:);
    pos = pos+n;
end

end