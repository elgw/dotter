function varargout = df_cc_apply_dots(varargin)
% Apply correction for chromatic aberration
% dots in D are in channel 'from' and they are
% transformed to match channel 'to'
%
% Example:
% CD = df_cc_apply_dots('dots', D, 'from', 'a594', 'to', 'dapi', 'ccFile',
% 'cc_20160722.mat');

s.verbose = 0;

for kk = 1:numel(varargin)
    if strcmpi(varargin{kk}, 'dots')
        D = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'from')
        from = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'to')
        to = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'ccFile')
        ccFile = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'ccData')
        cc = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'settings')
        s = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'getDefaults')
        varargout{1} = s;
    end
end

if ~exist('cc', 'var')
    if strcmp(ccFile(end-1:end), 'cc') == 0
        warning('The correction file does not end with .cc')
    end
    cc = load(ccFile, '-mat');
end

% Figure out the index of the provided channels

ifrom = find(strcmpi(cc.channels, from));
ito = find(strcmpi(cc.channels, to));
if(numel(ifrom)~=1)
    warning('Could not find channel %s in cc file. Not doing anything!\n', from);
    disp('Available channels:')
    disp(cc.channels)
    varargout{1} = D;
    return;
end
if(numel(ito)~=1)
    warning('Could not find channel %s in cc file. Not doing anything!\n', from);
    disp('Available channels:')
    disp(cc.channels)
    varargout{1} = D;
    return;
end

if s.verbose
    fprintf('cc from %s to %s\n', from, to);
end

if ifrom == ito
    varargout{1} = D;
    return; % D not changed
end

% Coefficients
Cx = cc.Cx{ifrom, ito};
Cy = cc.Cy{ifrom, ito};

if numel(Cx) == 6
    polyorder = 2;
    D(:,1) = poly2mat(D(:,1:2), polyorder)*Cx; % 2nd order correction
    D(:,2) = poly2mat(D(:,1:2), polyorder)*Cy;
    D(:,3) = D(:,3) + cc.dz{ifrom, ito}; % Just a constant offset
else
    warning('Wrong number of coefficients, not doing anything!')
end

varargout{1} = D;

end
