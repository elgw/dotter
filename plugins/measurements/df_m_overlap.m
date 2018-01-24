function U = df_m_overlap(varargin)
% Based on the previous DNA_ChannelOverlapAnalysis.m
%
% Uses Monto Carlo sampling to determine how big the overlap is between
% the channels.
%
% The value is (A cap B)/(A union B) or the ratio between 
% (samples in both) / (samples in at least one)
% i.e., in the rangle [0,1]
%
% Uses:
%  See if the dots in the channels are colocalized (when small radius is
%  used)
%  To measure intermingling (when larger radius is used)
%
% Method:
%  For nuclei
%   Grab dots from the two sets of channels
%   Place spheres around all dots
%   At random points, see how many times it is within both channels vs in
%   just one of them
%
% Settings:
%  s.radius: radius around each dot
%  s.ndots: number of sample points

if numel(varargin)==1
    if strcmpi(varargin{1}, 'getSettings')
        t.string = 'Clusters: Volumetric Intermingling';
        t.selChan = 2;
        t.features = 'N';
        s.radius = 130*5;
        s.ndots = 10^5;        
        s.usePaths = 0;
        s.plot = 0;
        t.s = s;
        U = t;
        return
    end
end

M = varargin{1};
N = varargin{2};
chan1 = varargin{3};
chan2 = varargin{4};
s = varargin{5};

disp('Settings:')
disp(s);

addpath([getenv('DOTTER_PATH') '/addons/geom3d/geom3d/'])


s.res = M{1}.pixelSize;

R0 = rand(s.ndots, 3);

nNuclei = numel(N);

w = waitbar(0, 'Processing');
U = nan(numel(N),1);
for nn = 1:numel(N)
    waitbar(nn/nNuclei,w);
    
    % Dots from the sets of channels
    D1 = [];
    for kk = 1:numel(chan1)
        D1 = [D1; N{nn}.userDots{chan1(kk)}(:,1:3)];
    end
    
    D1(:,1)=D1(:,1)*s.res(1);
    D1(:,2)=D1(:,2)*s.res(2);
    D1(:,3)=D1(:,3)*s.res(3);
    
    D2 = [];
    for kk = 1:numel(chan2)
        D2 = [D2; N{nn}.userDots{chan2(kk)}(:,1:3)];
    end
    
    D2(:,1)=D2(:,1)*s.res(1);
    D2(:,2)=D2(:,2)*s.res(2);
    D2(:,3)=D2(:,3)*s.res(3);
    
    if numel(D1)>0 && numel(D2)>0 % if there are dots in both nuclei
        
        % Get bounds of domain to know where to sample
        D = zeros(1,6);
        
        D([1,3,5]) = min([D1;D2]) - s.radius;
        D([2,4,6]) = max([D1;D2]) + s.radius;
        
        R = R0; % The random sample points
        for kk = 1:3
            k2 = (kk-1)*2;
            R(:,kk) = R(:,kk)*(D(k2+2)-D(k2+1));
            R(:,kk) = R(:,kk)+D(k2+1);
        end
        
        % See if the random samples falls close to the dots
        inD1 = zeros(size(R,1),1);
        if s.usePaths
            L = getMST(D1);
            if s.plot
                figure(99)
                clf
                plot3DLine(L, s.radius, [0,1,1]);
            end
            for kk = 1:size(L,1)
                d = dPointsToLines(L(kk,1:6), R); % mark locations that are close to the dots
                inD1 = inD1 + (d<s.radius);
            end
            %keyboard
        else
            for kk = 1:size(D1,1)
                d = eudist(D1(kk,1:3), R);
                inD1 = inD1 + (d<s.radius);
            end
        end
        
        inD1 = inD1>0; % 1 if within any of the spheres
        
        inD2 = zeros(size(R,1),1);
        
        if s.usePaths
            L = getMST(D2);
            if s.plot              
                figure(99)               
                plot3DLine(L, s.radius, [1,0,1]);
            end
            for kk = 1:size(L,1)
                d = dPointsToLines(L(kk,1:6), R);
                inD2 = inD2 + (d<s.radius);
            end
            
        else
            for kk = 1:size(D2,1)
                d = eudist(D2(kk,1:3), R);
                inD2 = inD2 + (d<s.radius);
            end
        end
        
        inD2 = inD2>0;
        
        total = sum((inD1+inD2)>0);
        
        U(nn) = sum((inD1+inD2)==2)/total;
        
        if s.plot
            title(sprintf('Overlap: %d', U(nn)));
            light
            pause
        end
            
    else
        U(nn) = 0;
    end
end
close(w);


end




