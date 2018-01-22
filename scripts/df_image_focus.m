function varargout = df_image_focus(varargin)

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

if nargout ~= 1
    error('There is only one output variable');
end

if strcmp(s.method, 'gm')
    dx = gpartial(V,1,1);
    dy = gpartial(V,2,1);
    gm = (dx.^2+dy.^2).^(1/2);
    varargout{1} = squeeze(sum(sum(gm,1),2));
    return;
end

error('No method called %s\n', s.method);

end

