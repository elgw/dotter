function [ PFIT ] = dotFitting(V, P, s)
%dotFitting(V, P, s) ML localization of points P in image I
%   Settings:
% s.useClustering {0,1}
%   Find points close to each other and try to fit them simultaneously
% s.sigmafitXY
% s.sigmafitZ
%   size of Gaussian profile to be fitted
%
% PFIT:
% 1 x coordinate
% 2 y coordinate
% 3 z coordinate
% 4 Number of photons
% 5 Fitting error
% 6 xy-sigma (-1 mo convergence), constant if s.sigmafitXY=0
%   fwhm of Gaussians are sigma*2*sqrt(2*log(2))
% 7 status, 0 = normal, 1 = no sigma, 2 = cluster
%
%
% Note that the fitting algorithm isn't scale invariant, i.e.
% in general dotFitting(V,P) != dotFitting(k*V, P), where k is a scalar
% works best when the peak intensity is between 10000 and 2^16 (I hope)
%
% Example:
%  V = df_readTif('a594_001.tif');
%  D = dotCandidates(V);
%  tic, F = dotFitting(V, D(1:1000,1:3)); toc % 20.8 sec
%
% To do:
% - Handle dots that are close to each other. Alternatives: Simultaneous
% fitting (slow). Iterative simultaneous fitting where the effects of close
% by dots are cancelled.
% - Handle "blobs", dots that don't look like dots, i.e., big things.


codedir = getenv('DOTTER_PATH');
if strcmp(codedir, '')
    codedir = '~/code/';
end

if ~exist('s', 'var')
    s = [];
    s.useClustering = 1;
    s.sigmafitXY = 1.5;
    s.sigmafitZ = 3;
    s.fitSigma = 1;
    s.verbose = 0;
    s.clusterMinDist = 5;    
end

if(nargin == 0)
    %disp('Nothing to do, returning default values');
    PFIT = s;
    return
end

if ~isfield('s', 'verbose')
    s.verbose = 0;
end

%% Clustering
if s.useClustering
    %save beforeClustering.mat
    if s.verbose
        fprintf('Clustering, ')
    end
    
    C = df_bcluster(double(P(:,1:3)), s.clusterMinDist);
    
    if 0
        % Plot cluster pairs
        figure, imagesc(sum(I,3)), colormap gray, axis image
        hold on
        for kk = 1:numel(C)-3
            if C(kk)==0 && C(kk+3) == 0
                %C(kk:kk+3);
                pa = C(kk+1); pb = C(kk+2);
                plot([P(pa, 2),  P(pb, 2)],[P(pa, 1),  P(pb, 1)], 'r');
            end
        end
    end
    
    % Set up a list of all points that are in a cluster
    incluster = zeros(size(P,1),1);
    for kk=1:size(C)
        if(C(kk)>0)
            incluster(C(kk))=1;
        end
    end
    
    if s.verbose
        fprintf('%d/%d points in clusters\n', sum(incluster), size(P,1));
    end
    
else
    incluster = zeros(size(P,1),1);
end

fittedxy = 0*incluster;
fittedz = 0*incluster;

V = double(V);

%% Sub pixel precision localization.
PFIT = double(P); % Stores location of fitted points
S = NaN(size(P,1),1);

%% XY-FITTING
if s.verbose
    tic
    fprintf('Fitting, XY, estimated time %d s\n', round(size(P,1)*9.2/125));
end

for kk=1:size(P,1)
    if(fittedxy(kk) == 0)
        if(incluster(kk))
            % Move this part into a separate file
            % I.e. the points in the same cluster should be fitted
            % simultaneously
            % Resolve localization of points in clusters from sum projection
            % images until PSF available.
            
            % Find the points of the cluster
            CP = getClusterPoints(C, kk);
            
            if numel(CP)==2
                if s.verbose
                    fprintf('C: %d -- %d \n', CP(1), CP(2))
                end
                % determine the region to cut out, i.e. patch
                padding = 4;
                rmuu = round([P(CP(1), 1:2), P(CP(2), 1:2)]);
                xmin = min(rmuu(1), rmuu(3))-4;
                xmax = max(rmuu(1), rmuu(3))+4;
                ymin = min(rmuu(2), rmuu(4))-4;
                ymax = max(rmuu(2), rmuu(4))+4;
                width = max(xmax-xmin, ymax-ymin);
                minZ = min([P(CP(1), 3), P(CP(2), 3)]);
                maxZ = max([P(CP(1), 3), P(CP(2), 3)]);
                
                % Observe that not all of the sample is summed in z
                
                if(xmin>0 && ymin>0 && xmin+width <= size(V,1) && ymin+width <= size(V,2))
                    patch = sum( V( xmin:xmin+width, ymin:ymin+width ,minZ:maxZ), 3);
                    
                    % muup: muu for the patch
                    muup = rmuu;
                    muup(1)=muup(1)-xmin+1;
                    muup(2)=muup(2)-ymin+1;
                    muup(3)=muup(3)-xmin+1;
                    muup(4)=muup(4)-ymin+1;
                    
                    if 0
                        f2=figure, imagesc(patch), colormap gray, axis image
                        hold on
                        plot(muup(2), muup(1), 'rx')
                        plot(muup(4), muup(3), 'rx')
                    end
                    
                    muup = muup-(size(patch,1)+1)/2;
                    
                    % Call the optimization routine
                    x2=gaussFit2multi(patch, s.sigmafitXY, muup);
                    
                    % Put back the results
                    if 0
                        figure,
                        imagesc(sumV), axis image, colormap gray
                        hold on
                        plot(x2(2)+ymin+width/2, x2(1)+xmin+width/2, 'ro')
                        plot(x2(4)+ymin+width/2, x2(3)+xmin+width/2, 'ro')
                    end
                    PFIT(CP(1), 1:2) = [x2(1)+xmin+width/2, x2(2)+ymin+width/2];
                    PFIT(CP(2), 1:2) = [x2(3)+xmin+width/2, x2(4)+ymin+width/2];
                    PFIT(CP(1), 7) = 2;
                    PFIT(CP(2), 7) = 2;
                    
                    
                    fittedxy(CP)=1;
                end
            else
                if s.verbose
                    fprintf('E: ')
                end
                for aa = 1:numel(CP)
                    fprintf('%d-', CP(aa))
                end
                fprintf('\n')
            end
        else % If not in cluster
            side = 4;
            px = round(P(kk,1));
            py = round(P(kk,2));
            pz = round(P(kk,3));
            
            
            if(px-side>0 && py-side>0 && px+side<=size(V,1) && py+side<=size(V,2))
                
                patch = V(px-side:px+side, py-side:py+side, pz);
                %[x,fval] = gaussFit2(patch, s.sigmafit);
                [x,fval, exitflag, sigmafitted] = LH2G(patch, s.sigmafitXY, s.fitSigma);
      %          keyboard
                S(kk)=sigmafitted;
                PFIT(kk,7) = 0;
                if exitflag ~= 1
                    sigmafitted = -1;
                    [x,fval, exitflag] = LH2G(patch, s.sigmafitXY, 0);
                    if s.verbose
                        if exitflag == 0
                            fprintf('F:%d\n', kk);
                        else
                            fprintf('R:%d\n', kk);
                        end
                    end
                    PFIT(kk,7) = 1;
                end
                
                
                PFIT(kk,1)=px+x(1)-(side+1); % x coordinate
                PFIT(kk,2)=py+x(2)-(side+1); % y coordinate
                % PFIT(ll,3) will be set below
                PFIT(kk,4)=x(3); % Number of photons
                PFIT(kk,5)=fval; % Fitting error
                PFIT(kk,6)=sigmafitted;
                fittedxy(kk) = 1;
            else
                disp('Dot To Close to boundary');
            end
            
        end
    end
end
if s.verbose
    fprintf('\n');
end

% plot order vs order
% figure, plot(1:s.NPFIT, sort(...PFIT(1:s.NPFIT, 5), 'x')

% Are there a few preferred distinct number of bins when counting the
% number of fitted photons?
% figure, hist(PFIT(1:s.NPFIT, 4),400)

%% Z-FITTING
if(size(V,3)>3)
    if s.verbose
        fprintf('Fitting, Z, estimated time %d s\n', round(size(P,1)*2/125));
        tic
    end
    for kk=1:size(P,1)
        if fittedz(kk)==0
            vz = 1:size(V,3);
            vx = PFIT(kk,1)*ones(size(vz));
            vy = PFIT(kk,2)*ones(size(vz));
            y = trilinear(V, vy, vx, vz);
            [fit, fitError] = gaussFit1(y, PFIT(kk,3), s.sigmafitZ);
            
            if kk<0
                figure(7), clf, subplot(1,2,1),
                %plot(vz, y), hold on, plot(PDOG(kk,3)*[1,1], [min(y), max(y)])
                imagesc(y), axis image, colormap gray, hold on,
                plot(PFIG(kk,3)*[1 1], [.6, 1.4], 'g');
                plot([fit(1), fit(1)], [.5, 1.5], 'r');
                subplot(1,2,2)
                imagesc(V(:,:,round(PFIT(kk,3))))
                axis image, colormap gray
                hold on
                plot(P(kk,2), P(kk,1), 'go')
                plot(PFIT(kk,2), PFIT(kk,1), 'rx')
                set(gca, 'XLim', [PFIT(kk,2)-10, PFIT(kk,2)+10])
                set(gca, 'YLim', [PFIT(kk,1)-10, PFIT(kk,1)+10])
                pause
            end
            
            PFIT(kk,3)=fit(1);
            fittedz(kk)=1;
            
        end
    end
    
    if s.verbose
        toc
    end
    
end

%% Move back dots that moved more than one pixel in z-direction
% In some situations the z-fitting fails quite much, then to fallback on
% the original location:

PFIT = d_stickyz(PFIT, P, 1);


end

