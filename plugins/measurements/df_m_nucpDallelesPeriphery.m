function dP = df_m_nucpDallelesPeriphery(varargin)
% Distance from the geometic centre of each allele to the periphery
%
% The distance is calculate by doing a distance transform on the nuclei
% mask and then interpolating the value at the centre of the allele.

if numel(varargin)==1
    if strcmpi(varargin{1}, 'getSettings')
        t.string = 'Distances from allele to periphery';
        t.selChan = 1;
        t.features = '2N';
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

for kk = 1:numel(N)
    for ll = 1:2
        
        p = []; % means of dots in chan
        
        for cc = chan1
            d1 = N{kk}.clusters{ll}.dots{cc};
            p = [p; d1];
        end
        
        if numel(p)>0
            p = mean(p(:,1:3),1);
            dP(kk,ll) = interpn(M{N{kk}.metaNo}.distanceMask, p(1), p(2), 'linear');
        else
            dP(kk,ll) = NaN;
        end
    end
end

dP = dP*M{1}.pixelSize(1);
dP = dP';
dP = dP(:);
end
