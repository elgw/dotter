function M = df_cc_apply_m(M, varargin)
% function M = df_cc_apply_n(M, varargin)
% Apply cc correction on all dots in M
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


for cc = 1:numel(M.channels)
    s.verbose = 0;
    M.dots{cc} = ...
        df_cc_apply_dots('dots', M.dots{cc}, ...
        'from', M.channels{cc}, ... % From
        'to', 'dapi', ... % To
        'ccData', ccData, 'settings', s);
end


end