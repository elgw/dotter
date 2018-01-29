function NDA = df_m_nucpNdotsAlleles(varargin)
% Number of dots per allele

if numel(varargin)==1
    if strcmpi(varargin{1}, 'getSettings')
        t.string = 'Cluster: Number of dots';
        t.selChan = 1;
        t.features = 'C';
        NDA = t;
        return
    end
end


%M = varargin{1};
N = varargin{2};
chan = varargin{3};
%chan2 = varargin{4};

% Number of dots per allele
NDA = [];
for kk = 1:numel(N)
    for aa = 1:numel(N{kk}.clusters) % allele
        for cc = chan
            %keyboard
            dots = N{kk}.clusters{aa}.dots{cc};
            NDA = [NDA;  size(dots, 1)];
        end
    end
end
end
