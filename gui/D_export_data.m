%%
% main.m -> analyzeDataset.m -> selectDots.m -> showResults.m
%                               exportNDots.m
%
% Loads all .NM files within a folder
% each of them contains the structures
% M: meta information
% N: nuclei
%
% Output:
% A single mat file with the structure 
% Nuclei: all ok nuclei and their dots and some meta data 

% Known improvements to do:
% - Apply DRY - write the code for one channel, apply for several
% - Cluster locations in 3D
% - Look out for points that converge to the same location during fitting.
% - Compare the two clusters, if they are dissimilar (in some sense) don't
%   continue.
% - Other ways to do the clustering into homologs besides the Euclidean 
%   distance to the cluster centre?
% - Demand that the clusters have similar intensities, it might be the case
%   that the homologs are at the same place, discard this scenario at this
%   time. Also demand that those clusters are distinct.
%   Also order the cluster locations by intensity, not DOG


close all
clear all

ignoreFitting = 1;
if ignoreFitting
disp('NO FITTING! -- use only for debug')
end

% Cells to exclude, [File, Cell ; ...
excludeList = [-1, -1];

%% Settings
wfolder = '/Users/erikw/data/310715_iMB2_calc/';
outFolder = 'export2/';
interactive = 0;
s.dapival = 2.5*10^9; % From B_cells_global
%selection_130715 % Loads selection which contains
% File, cell, channel, red, green

% Fitting
fittingSettings.sigmafitXY = 1.3;
fittingSettings.sigmafitZ = 2.27;
fittingSettings.useClustering = 1;
fittingSettings.clusterMinDist = fittingSettings.sigmafitXY;
fittingSettings.fitSigma = 0;
fittingSettings.verbose = 1;   

%% Initialization
files = dir([wfolder '*NM']);
addpath('../dotter')
addpath('../deconv/')
Nuclei = [];
numOkNuclei = 0;

try
    mkdir([wfolder outFolder])
end

%% Dot analysis per nuclei
for kk = 1:numel(files) %% Per file
    F = [];
    load([wfolder files(kk).name], '-mat') 
    M.nTrueDots = [3,4,5];
    %[M, N] = c_get_tmr_regions(M, N);
    
   %[M, N] = d_filter_dots(M,N); % not needed any more when normalized
   %convolution is used to calculate the DoG
    
    excludedNuclei = excludeList(excludeList(:,1)==kk, 2);
    idapi = df_readTif(M.dapifile);
    itmr = df_readTif(strrep(M.dapifile, 'dapi', 'tmr'));
    % Correct for shift in TMR. Should be performed earlier next time
    % see alignTMRDAPI.m
    %itmr = shift2d(double(itmr), [13,0]);
    %M.mask_regions = shift2d(M.mask_regions, [13,0]);
   
    
    %% For each nuclei in the channel select dots
    for cc = 1:numel(M.channels)
        ichannel =  df_readTif(M.channelf{cc});
    for ll = 1:numel(N)        
        basename = sprintf('%s%s%04d_%04d_%d', wfolder, outFolder, kk, ll,cc);
        fprintf('Image %d:nuclei %d: channel %d =============================================\n', kk, ll, cc)
        cellExcluded = 0;
        
        if sum(excludedNuclei==ll)>0
            cellExcluded = 1;
        end
                
        dapiok = 0;
        dapisum = N{ll}.dapisum;
        if dapisum < s.dapival
            dapiok = 1;
        end
                
        logfilename = [basename '_log.txt'];
        log = fopen(logfilename, 'w');
           
        tmrok = 1;
        fprintf('dapi: %d, tmr: %d, cellExcluded: %d\n', dapiok, tmrok, cellExcluded);        
        
        if dapiok && ~cellExcluded
            %% All conditions met, using this cell
            disp('Using nuclei ...')
            
           
           if 0 
            figd = figure;
            plot(ddapi, kdapi, 'k', 'LineWidth', 2)
            hold on
            plot([dapisum, dapisum], [min(kdapi), max(kdapi)], '--r', 'LineWidth', 2);
            
            savename = [basename '_dapival.fig'];
            savenamepng = [basename '_dapival.png'];
            
            savefig(savename);
            print('-dpng', savenamepng);
            close(figd)
           end
            
           %% Clustering required - see twocolor
            
            %% Take dots from channel1 to each cluster
            %[dotsA, dotsB, dotStatus] = getDotsInTmrRegions(M,N, ll, cc);            
            %% 
            dotsA = N{ll}.dots{cc};
            if size(dotsA,1)>0
                dotsA = dotsA(min(size(dotsA,1),1:2*M.nTrueDots(cc)),:);
            end
            dotsB = [];
           dotStatus = 1;
            
            dotStatus
            if dotStatus > 0
                
            %% High quality fitting
            if ignoreFitting
                dotsAfit = dotsA; %dotsA(1:min(M.nTrueDots(cc)/2, size(dotsA,1)), :);
                dotsBfit = []; %dotsB(1:min(M.nTrueDots(cc)/2, size(dotsB,1)), :); 
                
            else
                dotsAS = dotsA(1:min(M.nTrueDots(cc)/2, size(dotsA,1)), :);
                dotsBS = dotsB(1:min(M.nTrueDots(cc)/2, size(dotsB,1)), :);                      
                dotsAfit = dotFitting(double(ichannel), dotsAS, fittingSettings);
                dotsBfit = dotFitting(double(ichannel), dotsBS, fittingSettings);                        
                %% To avoid strange behaviour, move back dots that moved more
                % than 1 pixel in z
                dotsAfit = d_stickyz(dotsAfit, dotsAS, 1);
                dotsBfit = d_stickyz(dotsBfit, dotsBS, 1);
            end          
            fprintf(log, 'A: %d, B:%d', size(dotsAfit,1), size(dotsBfit,1));
                                    
            
            %% In selection?
            % Use the selection matrix,
            % see if [kk, ll, cc] is the beginning of any row of selection
            
            if exist('selection', 'var')
            [~, indx]=ismember(selection(:,1:3),[kk,ll,cc],'rows');
            inSelection = 0;
            useA = 1;
            useB = 1;
            if(sum(indx)==1)
                inSelection = 1;
                useA = selection(find(indx), 4);
                useB = selection(find(indx), 5);
            end
            else
            useA = 1;
            useB = 0;
            inSelection = 1;
            end
            
            %% Export 
            % In .mat format
            if 0
            savename = [basename '.mat'];                                              
            %% Set the intensity as p-value (possibly scaled)                            
            save(savename, 'dotsAfit', 'dotsBfit', 'M', 'N')
            % in .txt format        
            
            if useA
                dlmwrite([basename '_A.txt'], [dotsAfit(:,1:3) dotsAS(:,4)])
            end
            if useB
                dlmwrite([basename '_B.txt'], [dotsBfit(:,1:3) dotsBS(:,4)])            
            end            
            end                        
            
            if inSelection
            fig0 = figure(cc);
            hold on
            %imagesc(max(ichannel, [], 3)); colormap gray
            if useA
            plot3(dotsAfit(:,2), dotsAfit(:,1), dotsAfit(:,3), 'o', ...
                'MarkerEdgeColor','k',...
                       'MarkerFaceColor','r');
            end
            if useB
                plot3(dotsBfit(:,2), dotsBfit(:,1), dotsBfit(:,3), 'o', ...
                'MarkerEdgeColor','k',...
                       'MarkerFaceColor', 'yellow');
            end
            
             %view(3)
            view(9, 62)
            grid on
             [faces, vertices]=isosurface(repmat(M.mask==ll, [1,1,3]));
            vertices(:,3) = vertices(:,3)+size(ichannel, 3)/3-1;
            patch('faces', faces, 'vertices', vertices, 'EdgeColor', 'none', 'FaceColor', [.5,.5,.5], 'FaceAlpha', .5);
            axis equal
            axis ij
            %plot3(c1dots(:,2), c1dots(:,1), c1dots(:,3), 'k.')
            %plot3(c2dots(:,2), c2dots(:,1), c2dots(:,3), 'k.')
            savename = [basename '.fig'];
            savenamepng = [basename '.png'];
            
            set(gca,'LooseInset',get(gca,'TightInset'))
            
            savefig(savename);
            print('-dpng', savenamepng);
            
            close(fig0)                    
            
            % Set color limits for the mapping
            cLimDapi = quantile16(idapi, [0.01, 0.99]);
            cLimChannel = quantile16(ichannel, [0.1, 0.99995]);
         
            
            % Dapi
            bbx = N{ll}.bbx;
            savenamepng = [basename '_dapi.png'];
            nuc_dapi = max(idapi(bbx(1):bbx(2), bbx(3):bbx(4), :),[], 3);
            imwrite(linStretch(nuc_dapi, cLimDapi), savenamepng);                       
            
            % Small MIP image of the nuclei/channel           
            bbx = N{ll}.bbx;
            savenamepng = [basename '_mip.png'];
            %nuc_ic1 = sum(ic1(bbx(1):bbx(2), bbx(3):bbx(4), :),3);
            nuc_channel = max(ichannel(bbx(1):bbx(2), bbx(3):bbx(4), :),[], 3);            
            imwrite(linStretch(nuc_channel, cLimChannel), savenamepng);            
            
            % Mask
            bbx = N{ll}.bbx;
            savenamepng = [basename '_mask.png'];
            nuc_mask = M.mask(bbx(1):bbx(2), bbx(3):bbx(4));
            imwrite(normalisera(double(nuc_mask)), savenamepng);
            
            % XZ: Dots + channel
            fig = figure;
            subplot('position', [0,0,1,1])
            hold on
            bbx = N{ll}.bbx;            
            ichannelx = ichannel(bbx(1):bbx(2), :, :);
            ichannelx = max(ichannelx, [], 1);
            ixz = squeeze(ichannelx)';
            imagesc(ixz)
            savenamepng = [basename '_xz.png'];
            ixzbb = ixz(:, bbx(3):bbx(4));
            imwrite(flipud(linStretch(ixzbb, cLimChannel)), savenamepng);            
            colormap gray
            axis image                              
            colormap gray
            set(gca, 'clim', cLimChannel);            
            if useA
            plot(dotsAfit(:,2), dotsAfit(:,3), 'o', ...
                'MarkerEdgeColor','r',...
                       'MarkerFaceColor','none');
            end
            if useB
            plot(dotsBfit(:,2), dotsBfit(:,3), 'o', ...
                'MarkerEdgeColor','g',...
                       'MarkerFaceColor', 'none');
            end
            axis([bbx(3), bbx(4), 1, size(ichannel,3)])  
            axis off
            cdotsim = getframe(gcf);
            savenamepng = [basename '_cdotsxz.png'];
            imwrite(cdotsim.cdata, savenamepng);            
            %pause
            close(fig)
            
            %% YZ: Dots + channel
            fig = figure;
            subplot('position', [0,0,1,1])
            hold on
            bbx = N{ll}.bbx;            
            ichannely = ichannel(:,bbx(3):bbx(4), :);
            ichannely = max(ichannely, [], 2);
            iyz = squeeze(ichannely)';
            imagesc(iyz)            
            savenamepng = [basename '_yz.png'];
            iyzbb = iyz(:, bbx(1):bbx(2));
            imwrite(flipud(normalisera(iyzbb)), savenamepng);            
            colormap gray
            axis image                                
            colormap gray
            set(gca, 'clim', cLimChannel);            
            if useA
            plot(dotsAfit(:,1), dotsAfit(:,3), 'o', ...
                'MarkerEdgeColor','r',...
                       'MarkerFaceColor','none');
            end
            if useB
            plot(dotsBfit(:,1), dotsBfit(:,3), 'o', ...
                'MarkerEdgeColor','g',...
                       'MarkerFaceColor', 'none');
            end
            axis([bbx(1), bbx(2), 1, size(ichannel,3)])           
            axis off
            cdotsim = getframe(gcf);
            savenamepng = [basename '_cdotsyz.png'];
            imwrite(cdotsim.cdata, savenamepng);
            %pause
            close(fig);       
            
           %% Dots + channel
            fig = figure;
            subplot('position', [0,0,1,1])
            hold on
            bbx = N{ll}.bbx;            
            imagesc(max(ichannel, [], 3));      
            if isfield(M, 'mask_regions')
                contour(M.mask_regions>0, [.5,.5], 'y');
            end
            axis image
            colormap gray
            set(gca, 'clim', cLimChannel);                        
            if useA
            plot(dotsAfit(:,2), dotsAfit(:,1), 'o', ...
                'MarkerEdgeColor','r',...
                       'MarkerFaceColor','none');
            end
            if useB
            plot(dotsBfit(:,2), dotsBfit(:,1), 'o', ...
                'MarkerEdgeColor','g',...
                       'MarkerFaceColor', 'none');
            end
            axis(bbx([3,4,1,2]))
            axis ij
            axis off
            cdotsim = getframe(gcf);
            savenamepng = [basename '_cdots.png'];
            imwrite(cdotsim.cdata, savenamepng);
                     
            close(fig);       
            end
            
            end
        end
        fclose(log);
        end
    end
end
   

    
disp(['Done writing to ' wfolder outFolder]);