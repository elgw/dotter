function A = df_m_nucpArea(varargin)
% Area of each nuclei 
%
% Given as the number of pixels in the segmentation mask

if numel(varargin)==1
    if strcmpi(varargin{1}, 'getSettings')
        t.string = 'Nuclei: Area [pixels]';
        t.selChan = 0;        
        t.features = 'N';
        A = t;
        return
    end
end

% M = varargin{1};
N = varargin{2};
% chan1 = varargin{3};
% chan2 = varargin{4};

A = nan(numel(N), 1);
for kk = 1:numel(N)
    A(kk) = N{kk}.area;
end

end

