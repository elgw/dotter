function df_thresholds(varargin)

M = [];

for kk = 1:numel(varargin)
    if strcmpi(varargin{kk}, 'M')
        M = varargin{kk+1};
    end
end

%load test.mat

if numel(M) == 0
    disp('No data')
    return
end


end