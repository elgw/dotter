function N = df_cc_apply_n(M, N, varargin)
% function N = df_cc_apply_n(M, N, varargin)
% Apply cc correction on all userDots
% Supply either a ccFile or ccData
%

for kk = 1:numel(varargin)
    if strcmpi(varargin{kk}, 'ccFile')
        ccData = load(varargin{kk+1}, '-mat');
    end
    if strcmpi(varargin{kk}, 'ccData')
        ccData = varargin{kk+1};
    end
end

if ~exist('ccData', 'var')
    error('No ccData given (or ccFile)')
end

for nn = 1:numel(N)
    if isfield(N{nn}, 'userDots')
        for cc = 1:numel(M.channels)
            s.verbose = 0;
            N{nn}.userDots{cc} = ...
                df_cc_apply_dots('dots', N{nn}.userDots{cc}, ...
                'from', M.channels{cc}, ... % From
                'to', 'dapi', ... % To
                'ccData', ccData, 'settings', s);
        end
    end
end

end