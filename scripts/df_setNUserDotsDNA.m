function df_setNUserDotsDNA(varargin)
% function df_setNUserDotsDNA(folder)
%
% Purpose:
%  set a certain number of userDots per allele.
%
% Input:
%  'folder', a _calc folder with NM files
%  'dpn', dots per nuclei. If even number the dots are clustered using
%  2-means clustering
%
% Output:
%  the .NM files in the _calc folder are updated, no new files are produced
%

folder = nan;
dpn = 'dummy'; % expecting sth like [2,4,2]

for kk = 1:numel(varargin)
    if strcmpi(varargin{kk}, 'folder')
        folder = varargin{kk+1};
    end
    if strcmp(varargin{kk}, 'dpn')
        dpn = varargin{kk+1};
    end
end

assert(isstr(folder));
assert(isnumeric(dpn));

files = dir([folder '/*.NM']);
fprintf('%d NM files to process\n', numel(files));

F = load([folder '/' files(1).name], '-MAT');
assert(numel(F.M.channels) == numel(dpn));

fprintf('Will set the following number of dots per channel:\n');
for cc=1:numel(F.M.channels)
    fprintf('%s, %d dots\n', F.M.channels{cc}, dpn(cc));
end
disp('working ...')

assert(numel(files)>0);

for kk = 1:numel(files)
    fName = [folder '/' files(kk).name];
    F = load(fName, '-MAT');
    N = F.N;
    M = F.M;
    
    for nn = 1:numel(N)
        udAll = [];
        for cc = 1:numel(M.channels)
            dots = N{nn}.dots{cc};
            % excludes column >4 for compatiblity with setUserDotsDNA
            ud = dots(1:(min(size(dots,1), dpn(cc))), 1:4);
            N{nn}.userDots{cc} = ud;
            udAll = [udAll; ud];
        end
        % Cluster the userDots from all channels to set their labels
        % Get cluster means
        [~, m] = twomeans(udAll(:,1:3));
        
        % assign back
        for cc = 1:numel(M.channels)
            N{nn}.userDotsLabels{cc} = twomeans_classify(m, N{nn}.userDots{cc}(:,1:3));
        end
        % get cluster centers
        
        % set label corresponding to closest cluster
        
    end
    
    save(fName, 'M', 'N');
end

disp('Done');

end