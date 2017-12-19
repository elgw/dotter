%% Verify that some cc_ file can be used to correct for chromatic aberrations

% Finds the optimal reference channel by trying all permutations
%
% Might be better to choose reference channel by taking the row number with
% the smallest max in the full matrix with pariwise distances.
% But that might fail if the distances are above maxDist between the
% channels where the dots are furthest away. On iJC178 the permutation
% method gave lower sum(QMC(:))
%

clear all
close all

ccFile='/data/current_images/iJC178_180116_001/cc_20160119.mat';
ccFile='/data/current_images/iJC210_240116_001/cc_20160202.mat';
ccFile='/data/current_images/iJC312_140416_001/cc_20160419.mat';
ccFile='/data/current_images/iMB37_290416_001/cc_20160502.mat';

res = [131.08, 131.08, 200];

load(ccFile);

whos

% P: non fitted local maximas
% F: fitted P
% N: number of dots used
% folder: folder where the image data was located
% chan: channel names

maxDist = 5; % Don't connect dots with a distance more than this (pixels)
maxFitDist = 1; % In a second step, remove dots that are above this distance and then redo the fitting

mkdir('plots');
makePlots = 1;

%% See how close the sets are
nd = 3; % look in 2 or 3 dimensions, xy or xyz
QM = zeros(numel(chan));

for aa = 1:numel(chan)
    for bb = aa+1:numel(chan)
        A = F{aa};
        B = F{bb};
        
        
        %% Create distance matrices with averages
        sh = zeros(size(A,1),1);
        for kk = 1:size(A,1) % For each point, find closest point from the other channel
            d = (repmat(A(kk,1:nd), [size(B,1),1])-B(:,1:nd)).^2;
            d(:,3) = 0; % Exclude Z, seems appropriate in some cases
            s = sum(d,2);
            s = s.^(1/2);
            sh(kk)=min(s);
        end
        QM(aa,bb)=mean(sh(sh<maxDist));
        QM(bb,aa)=QM(aa,bb);
        
        if isnan(QM(bb,aa))            
            disp('NaN');
            pause
            figure,
            plot3(A(:,1), A(:,2), A(:,3), 'ro'); hold on
            plot3(B(:,1), B(:,2), B(:,3), 'kx');
        end
        
        
        if makePlots
            A = A(:,1:3).*repmat(res, [size(A,1), 1]);
            B = B(:,1:3).*repmat(res, [size(B,1), 1]);
            
            dim = {1, 2, 3, [1, 2], [1,2,3]};
            
            for dd = 1:numel(dim)
                dim{dd}
                sh = zeros(size(A,1),1);
                for kk = 1:size(A,1) % For each point, find closest point from the other channel
                    d = (repmat(A(kk,dim{dd}), [size(B,1),1])-B(:,dim{dd}));
                    dref = (repmat(A(kk,dim{end}), [size(B,1),1])-B(:,dim{end}));
                    dref = dref.^2;
                    dref = sum(dref, 2);
                    
                    if numel(dim{dd})>1
                        d = d.^2;
                        s = sum(d,2);
                        s = s.^(1/2);
                        sh(kk)=min(s);
                    else
                        s = sum(d,2);
                        sh(kk)=s(dref==min(dref));
                    end
                end
                
                sh = sh(sh<maxDist*131.08);
                
                % Plot 3D distance
                sname = '';
                if ismember(1, dim{dd})
                    sname = [sname 'x'];
                end
                if ismember(2, dim{dd})
                    sname = [sname 'y'];
                end
                if ismember(3, dim{dd})
                    sname = [sname 'z'];
                end
                
                if strcmp(sname, 'xyz')
                    figure(1)
                    histogram(sh, linspace(0,300, 21));
                    xlabel(sprintf('%s-%s, mean \\Delta %s %.1f nm', chan{aa}, chan{bb}, sname, mean(sh)))
                    filename = sprintf('plots/%s_%s_%s.pdf', chan{aa}, chan{bb}, sname);
                    disp(filename)
                    dprintpdf(filename);
                end
            end
        end
        
    end
end

disp('QM: average squared distances between the dots in the channels (pixels)')
disp(QM)
fprintf('Mean error %f, median error: %f\n', mean(QM(QM>0)), median(QM(QM>0)));



figure, hist(sh, linspace(0,2));

%% Try all possible paths to decide which channel is best as reference channel
P = perms(1:numel(chan));
pl = zeros(size(P,1), 1);
for kk = 1:size(P,1) % Select permutation
    for ll = 2:size(P,2)
        pl(kk) = pl(kk)+QM(min(P(kk,ll), P(kk,ll-1)), max(P(kk,ll), P(kk,ll-1)));
    end
end

minperm = P(find(pl==min(pl),1),:);

refchan = minperm(ceil((numel(minperm)+1)/2));

fprintf('Suggesting to use channel %d:  %s as reference\n', refchan, chan{refchan});


R = F{refchan};

% Do a first round of corrections and remove dots from F that does not fit
% the model well, i.e.,
F
pause
for kk = 1:numel(chan)    
    QC=cCorrI(F{kk}(:,1:3), chan{kk}, chan{refchan}, ccFile, maxDist);    
    fittingError = shortestEuclideanDistSets(QC(:,1:3), F{refchan}(:,1:3));    
    % Keep only dots which has a close by match
    F{kk} =F{kk}(fittingError<maxFitDist, :);
end
F

ccFileF = [ccFile, '_f'];
save(ccFileF, 'F', 'N', 'P', 'chan', 'folder')
pause
% refchan = find(max(QM) == min(max(QM)),1);

disp('Showing dots after correction')
for kk = 1:numel(chan)    
    QC=cCorrI(F{kk}(:,1:3), chan{kk}, chan{refchan}, ccFileF, maxDist);
    FC{kk} = QC;
    figure,
    plot3(QC(:,1), QC(:,2), QC(:,3), 'ro');
    hold on
    plot3(R(:,1), R(:,2), R(:,3), 'kx');
    legend({chan{kk}, chan{refchan}});
end

figure

%% See how close the sets are after correction
QMC = zeros(numel(chan));
for aa = 1:numel(chan)
    for bb = aa+1:numel(chan)
        
        A = FC{aa};        
        B = FC{bb};        
                        
        sh = shortestEuclideanDistSets(A,B);        
        QMC(aa,bb)=mean(sh(sh<maxFitDist));
        
        if makePlots
            
            dim = {1, 2, 3, [1, 2], [1,2,3]};
            
            for dd = 1:numel(dim)                
                Anm = A.*repmat(res, [size(A,1), 1]);
                Bnm = B.*repmat(res, [size(B,1), 1]);
                
                sh = shortestEuclideanDistSets(Anm(:,dim{dd}), Bnm(:,dim{dd}));
                
                sh = sh(sh<maxDist*131.08);
                
                % Plot 3D distance
                sname = '';
                if ismember(1, dim{dd})
                    sname = [sname 'x'];
                end
                if ismember(2, dim{dd})
                    sname = [sname 'y'];
                end
                if ismember(3, dim{dd})
                    sname = [sname 'z'];
                end
                
                if strcmp(sname, 'xyz')
                    figure(1)
                    histogram(sh, linspace(0,300, 21));
                    xlabel(sprintf('%s-%s, mean \\Delta %s %.1f nm', chan{aa}, chan{bb}, sname, mean(sh)))
                    filename = sprintf('plots/%s_%s_%s_cc.pdf', chan{aa}, chan{bb}, sname);
                    disp(filename)
                    dprintpdf(filename);
                end
            end
        end
        
    end
end

disp('QMC: Mean of pairwise distances after correction (pixels)')
QMC
fprintf('Mean error %f, median error: %f\n', mean(QMC(QMC>0)), median(QMC(QMC>0)));


figure, histogram(sh, linspace(0,2));

fprintf('If the results look fine, replace %s by %s\n', ccFile, ccFileF);
