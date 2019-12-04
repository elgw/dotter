function ND = df_m_nucpNdots(varargin)
% number of userDots per nuclei in selected channels

if numel(varargin)==1
    if strcmpi(varargin{1}, 'getSettings')
        t.string = 'Nuclei: Dots per Nuclei';
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
ND = zeros(numel(N), numel(chan));

for kk = 1:numel(N)
    for cc = chan
        ND(kk,cc) = size(N{kk}.userDots{cc},1);
    end
end
ND = sum(ND,2);
end