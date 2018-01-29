function dP = df_m_nucpDallelesPeriphery(varargin)
% 2D Distance from the geometic centre of each allele to the periphery
%
% The distance is calculate by doing a distance transform on the nuclei
% mask and then interpolating the value at the centre of the allele.

if numel(varargin)==1
    if strcmpi(varargin{1}, 'getSettings')
        t.string = 'Cluster: Distance centroid to periphery [NM]';
        t.selChan = 1;
        t.features = 'C';
        dP = t;
        return
    end
end

M = varargin{1};
N = varargin{2};
chan1 = varargin{3};
%chan2 = varargin{4};

disp('Creating distance masks')
M = createDistanceMasks(M);
dP = [];
for kk = 1:numel(N)
    for ll = 1:numel(N{kk}.clusters)
        
        p = []; % means of dots in chan
        
        for cc = chan1
            d1 = N{kk}.clusters{ll}.dots{cc};
            p = [p; d1];
        end
        
        if numel(p)>0
            p = mean(p(:,1:3),1);
            dP = [dP; interpn(M{N{kk}.metaNo}.distanceMask, p(1), p(2), 'linear')];
        else
            dP = [dP; NaN];
        end
    end
end

dP = dP*M{1}.pixelSize(1);
end
