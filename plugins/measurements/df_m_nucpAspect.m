function A = df_m_nucpAspect(varargin)
% Aspect ratio of each nuclei, calculate from the mask

if numel(varargin)==1
    if strcmpi(varargin{1}, 'getSettings')
        t.string = 'Nuclei: Aspect ratio [-]';
        t.selChan = 0;        
        t.features = 'N';
        A = t;
        return
    end
end

MM = varargin{1};
N = varargin{2};
% chan1 = varargin{3};
% chan2 = varargin{4}; 

A = nan(numel(N), 1);
for kk = 1:numel(N)   
    M = MM{N{kk}.metaNo};
    mask = (M.mask == N{kk}.nucleiNr);
    [ar] = regionprops(mask, 'MajorAxisLength', 'MinorAxisLength');
    A(kk) = ar(1).MajorAxisLength/ar(1).MinorAxisLength;
end

end

