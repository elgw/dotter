function D = df_m_homolVolume(varargin)
% Returns all pairwise distances from all alleles

if numel(varargin)==1
    if strcmpi(varargin{1}, 'getSettings')
        t.string = 'Homolog Volumes';
        t.selChan = 1;
        t.features = 'alone';
        s.radius = 130*5;
        t.s = s;
        D = t;
        return
    end
end

M = varargin{1};
N = varargin{2};
chan = varargin{3};
s = varargin{5};

if ~isfield(M{1}, 'pixelSize')
    warning('Pixel size not specified!')
    res = [130,130,300];
else
    res = M{1}.pixelSize;
end

D = [];
MM = []; % Number of dots, Volume ; ...
for nn = 1:numel(N)
    
    for aa = 1:2
        dots = [];
        
        for cc = chan
            cdots = N{nn}.clusters{aa}.dots{cc};
            dots = [dots ; cdots];
            
        end
        
        if size(dots,1)>1
            for kk = 1:3
                dots(:,kk) = dots(:,kk)*res(kk);
            end
            MM = [MM; size(dots,1), df_volumeSpheres([dots(:,1:3) s.radius*ones(size(dots,1),1)])];
        end
    end
    
end

D = D(:);
whos
figure
scatter(MM(:,1), MM(:,2))
xlabel('Number of dots')
ylabel('Volume, nm^3');
tString = sprintf('r=%d nm', s.radius);
if numel(chan) == 1
    tString = [M{1}.channels(chan(1)) tString];
end
grid on
title(tString);
end