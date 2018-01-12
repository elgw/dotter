function IAD = df_m_nucpDallelesInter(varargin)
% Distance between cluster 1 and 2 in each nuclei
%
% Geometric means are used to define the location of the clusters,
% hence the distance between these are returned

if numel(varargin)==1
    if strcmpi(varargin{1}, 'getSettings')
        t.string = 'Cluster distance';
        t.selChan = 2;        
        t.features = '2N';        
        IAD = t;
        return
    end
end

M = varargin{1};
N = varargin{2};
chan1 = varargin{3};
chan2 = varargin{4};

d.resolution = M{1}.pixelSize;

disp(M{1}.channels(chan1))
disp('vs')
disp(M{1}.channels(chan2))


% Strings for the channels
channels1S = '';
channels2S = '';
for kk = 1:numel(chan1)
    channels1S = [channels1S '-' M{1}.channels{chan1(kk)}];
end
for kk = 1:numel(chan2)
    channels2S = [channels2S '-' M{1}.channels{chan2(kk)}];
end

IAD = zeros(numel(N), 2);

for kk = 1:numel(N)
        
    for ll = 1:2
        A1 = [];
        A2 = [];
        
        for cc = chan1
            d1 = N{kk}.clusters{ll}.dots{cc};
            A1 = [A1; d1];
        end
        for cc = chan2
            d2 = N{kk}.clusters{ll}.dots{cc};
            A2 = [A2; d2];
        end
        
        if size(A1,1) == 0 || size(A2,1) == 0
            if(size(A1,1) ==0)
                fprintf('No dots in %s\n', channels1S)
            end
            if(size(A2,1) ==0)
                fprintf('No dots in %s\n', channels2S)
            end
            IAD(kk,ll) = nan;
        else
            %keyboard
            mA1 = mean(A1(:,1:3),1);
            mA2 = mean(A2(:,1:3),1);
            IAD(kk,ll) = norm(d.resolution.*(mA1-mA2));
        end
    end
end

IAD = IAD';
IAD = IAD(:);

end