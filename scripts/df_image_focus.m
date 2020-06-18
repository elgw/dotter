function varargout = df_image_focus(varargin)
% 'image', 'method' (default, 'gm')
%
% sigma=1 is too small for some deconvolved images.
% 
% Output: 1/ focus values for each slice 2/slice with most focus

s.method = 'gm'; % Gradient magnitude
V = [];

for kk = 1:numel(varargin)
    if strcmpi(varargin{kk}, 'image')
        V = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'method')
        s.method = varargin{kk+1};
    end
end

if numel(V) == 0
    error('No image provided\n');
end

if(numel(size(V)) ~= 3)
    error('Image has to be 3D');
end

if nargout < 1
    error('No output wanted');
end

if nargout > 2
    error('Only two outputs can be provided');
end

if strcmp(s.method, 'gm')
    sigma = 2;
    gm = zeros(1,size(V,3));
    for kk = 1:size(V,3)
        dx = gpartial(V(:,:,kk),1,sigma);
        dy = gpartial(V(:,:,kk),2,sigma);
        gm(kk) = mean(mean((dx.^2+dy.^2).^(1/2)));
    end
    varargout{1} = gm;
    varargout{2} = argmax(gm);
    return;
end

error('No method called %s\n', s.method);

end

function x = argmax(y)
x = find(y == max(y(:)));
if numel(x)>0
    x = x(1);
end
end
