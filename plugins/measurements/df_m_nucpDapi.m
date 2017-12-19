function D = df_m_nucpDapi(varargin)
% Sum of DAPI for each nuclei
%
% Sum of all pixels (for all Z) in that falls within the mask. This
% property was calculated when the nuclei were segmented and is already in
% the Metadata

if numel(varargin)==1
    if strcmpi(varargin{1}, 'getSettings')
        t.string = 'Dapi sum [AU]';
        t.selChan = 0;
        t.features = 'N';
        D = t;
        return
    end
end

N = varargin{2};

D = nan(numel(N), 1);

for kk = 1:numel(N)
    D(kk) = N{kk}.dapisum;
end
end