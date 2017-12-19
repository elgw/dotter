function DNA_ChannelOverlapAnalysis(folder, s)
%% function DNA_ChannelOverlapAnalysis(folder)
% For a folder with NM files where userDots are available
% Uses Monto Carlo sampling to determine how big the overlap is between
% the channels
%
% Purpose: 
%  See if the dots in the channels are colocalized
%
% Method: 
%  For each pair of channels and for each nuclei
%  place spheres around all dots
%  At random points, see how many times it is within both channels vs in
%  just one of them
%  mT(a,b) is the number of times the sample point hit spheres from both
%  channels over the number of times the sample point hit at least one of
%  them
%
%
% Settings:
%  s.radius: radius around each dot
%  s.res: x,y,z resolution
%  s.ndots: number of sample points

if ~strcmp(folder(end), '/')
    folder = [folder '/'];
end

files = dir([folder '*.NM']);
fprintf('Found %d NM files\n', numel(files));

if ~exist('s', 'var')
    disp('No settings given, using default')
    s.res = [130,130,200];
    s.radius = 130*5;
    s.ndots = 10^5;    
end

disp('Settings:')
disp(s);

R0 = rand(s.ndots, 3);

nNuclei = 0;
for ff =1:numel(files)
    load([folder '/' files(ff).name], '-mat');
    if numel(N)>0
        if ~isfield(N{1}, 'userDots')
            fprintf('No userDots in %s\n', files(ff).name);
        end
    end
    nNuclei = nNuclei + numel(N);
end

TOL = {};
info = {};
nuclei = 1;
for ff =1:numel(files)
    filename = [folder '/' files(ff).name];
    load(filename, '-mat');
    for nn = 1:numel(N)
        fprintf('Nuclei %d/%d\n', nuclei, nNuclei);
        OL = zeros(numel(M.channels));
        for cc1 = 1:numel(M.channels)
            D1 = N{nn}.userDots{cc1}(:,1:3);
            D1(:,1)=D1(:,1)*s.res(1);
            D1(:,2)=D1(:,2)*s.res(2);
            D1(:,3)=D1(:,3)*s.res(3);
            for cc2 = cc1+1:numel(M.channels)
                D2 = N{nn}.userDots{cc2}(:,1:3);
                D2(:,1)=D2(:,1)*s.res(1);
                D2(:,2)=D2(:,2)*s.res(2);
                D2(:,3)=D2(:,3)*s.res(3);
                if numel(D1)>0 && numel(D2)>0 % if there are dots in both nuclei
                    D = zeros(1,6); % bounds of domain
                    D([1,3,5]) = min([D1;D2]);
                    D([2,4,6]) = max([D1;D2]);
                    R = R0; % The random sample points
                    for kk = 1:3
                        k2 = (kk-1)*2;
                        R(:,kk) = R(:,kk)*(D(k2+2)-D(k2+1)); 
                        R(:,kk) = R(:,kk)+D(k2+1);
                    end
                    %(D([2,4,6])-max(R))
                    %(min(R)-D([1,3,5]))
                    inD1 = zeros(size(R,1),1);
                    for kk = 1:size(D1,1)
                        d = eudist(D1(kk,1:3), R);
                        inD1 = inD1 + (d<s.radius);
                    end
                    inD1 = inD1>0; % 1 if within any of the spheres
                    
                    inD2 = zeros(size(R,1),1);
                    for kk = 1:size(D2,1)
                        d = eudist(D2(kk,1:3), R);
                        inD2 = inD2 + (d<s.radius);
                    end
                    inD1 = inD1>0;
                    total = sum((inD1+inD2)>0);
                    assert(total>0); % At least one dot so this should be > 0
                    OL(cc1,cc2) = sum((inD1+inD2)==2)/total;
                else
                    OL(cc1,cc2)=0;
                end
            end
        end
        TOL{nuclei} = OL;
        info{nuclei}.file = filename;
        info{nuclei}.nuclei = nn;
        nuclei=nuclei+1;
    end
end
whos

% Present the results
filename = [folder 'overlapAnalysis.mat'];
fprintf('Saving TOL and info to %s\n', filename);
drawnow
save(filename, 'TOL', 'info');
fprintf('Done\n');
fprintf('Calculating means and standard deviations\n');
T = zeros([size(TOL{1}), numel(TOL)]);
for kk = 1:numel(TOL)
    T(:,:,kk) = TOL{kk};
end

mT = mean(T,3)
sT = std(T,[], 3)

if 0
pos = 1;
figure
for kk = 1:size(T,1)
    for ll = kk+1:size(T,2)
        plot([pos-.5, pos+.5], [mT(kk,ll) mT(kk,ll)])
        hold on
        pos = pos+1;
    end    
end
end
fprintf('Done\n');
end