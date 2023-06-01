function V = df_m_dotIntensities(varargin)
% Returns the dot intensities for all dots with label 1 and 2

if numel(varargin)==1
    if strcmpi(varargin{1}, 'getSettings')
        t.string = 'Dot: intensities [AU]';
        t.selChan = 1;
        t.features = 'D';
        V = t;
        return
    end
end

M = varargin{1};
N = varargin{2};
chan = varargin{3};


if ~isfield(M{1}, 'voxelSize')
    warning('Pixel size not specified!')
    res = [130,130,300]
else
    res = M{1}.voxelSize;
end

V = [];
for nn = 1:numel(N)
    for aa = 1:2
        dots = [];
        for cc = chan
            dots = [dots ; N{nn}.clusters{aa}.dots{cc}];
        end
        if numel(dots)>0
            V = [V; dots(:,4)];
        end
    end
end


end
