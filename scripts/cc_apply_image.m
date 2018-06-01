function varargout = cc_apply_image(varargin)

s.verbose = 1;

for kk = 1:numel(varargin)
    if strcmpi(varargin{kk}, 'image')
        I = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'to')
        to = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'from')
        from = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'ccFile')
        ccFile = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'ccData')
        cc = varargin{kk+1};
    end
end

if ~exist('cc', 'var')
    cc = load(ccFile, '-mat');
end

ifrom = find(strcmpi(cc.channels, from));
ito = find(strcmpi(cc.channels, to));

if numel(ito) == 0
    varargout{1} = [];
    errordlg(sprintf('Can''t use %s as reference channel. It does not exist in the bead data', to));
    return
end

if s.verbose    
    fprintf('cc from %s (#%d) to %s (#%d) \n', from, ifrom, to, ito);
end

if ifrom == ito
    varargout{1} = I;
    return; % D not changed
end
    

Cx = cc.Cx{ito, ifrom}; % observe oposite direction compared to moving dots
Cy = cc.Cy{ito, ifrom};
dz = cc.dz{ito, ifrom};

% Dense representation
[X,Y] = ndgrid(1:size(I,1),1:size(I,2));

if numel(Cx) == 6
    polyorder = 2;
end

PD = [X(:) Y(:)];
iX = poly2mat(PD, polyorder)*Cx;
iY = poly2mat(PD, polyorder)*Cy;

iX = repmat(iX, [size(I,3),1]);
iY = repmat(iY, [size(I,3),1]);
iZ = zeros(size(iX));

for kk = 1:size(I,3)
    start = (kk-1)*size(I,1)*size(I,2) + 1;
    iZ(start:start+size(I,1)*size(I,2)-1) = kk+dz;
end

if size(I,3) > 1 % 3D
    varargout{1} = interpn(double(I), ...
    reshape(iX(:), size(I)), ...
    reshape(iY(:), size(I)), ...
    reshape(iZ(:), size(I)), 'cubic' );
end

if size(I,3) == 1 % 2D
    warning('not tested')
    varargout{1} = interpn(double(I), ...
    reshape(iX(:), size(I)), ...
    reshape(iY(:), size(I)), 'cubic' );
end
 
end