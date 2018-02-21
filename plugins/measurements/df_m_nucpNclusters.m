function ND = df_m_nucpNclusters(varargin)
% number of clusters in userDots per nuclei in selected channels

if numel(varargin)==1
    if strcmpi(varargin{1}, 'getSettings')
        t.string = 'Nuclei: Number of clusters';
        t.selChan = 1;
        t.features = 'N';
        ND = t;
        return
    end
end

%M = varargin{1};
N = varargin{2};
chan = varargin{3};
%chan2 = varargin{4};

% Number of dots per nuclei
ND = zeros(numel(N), 1);

for kk = 1:numel(N)
    L = [];
    for cc = chan
        L = [L; N{kk}.userDotsLabels{cc}];        
    end
    
    nL = unique(L);
    nL = nL(nL>0);
    ND(kk) = numel(nL);
end

end