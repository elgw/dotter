function NC = df_nkmeans(varargin)
% function NC = df_nkmeans()
%
% For each nuclei in the NM files, 
% Estimate the number of clusters per Nuclei from UserDots using all
% channels.
%
% This function does not care about the labels that are given to the use dots.
% The number of clusters are estimated using kmeans, where k is 1, ... the
% number of dots.
%
% The optimal number of clusters is set where adding another cluster
% does not reduce the variance of squared distances from cluster centres 
% with more than 10 %.
%
% A figure will be produced for each nuclei, press <enter> to see the next
% one. At the end, a histogram is shown over the number of clusters per
% nuclei.

msgbox(help('df_nkmeans'))

doPlot = 1;

for kk=1:numel(varargin)
    if strcmpi(varargin{kk}, '-plot')
        doPlot = 0;
    end
end

N = df_getNucleiFromNM();
if numel(N) == 0
    return
end

if doPlot
    fig = figure;
    pos = fig.Position; pos(3) = 2*pos(4);
    fig.Position = pos;
end


NC = [];
ND = 0; % count the number of dots
for kk = 1:numel(N)
    D = [];
    %keyboard
    if isfield(N{kk}, 'userDots')
        for cc = 1:numel(N{kk}.userDots)
            dots =N{kk}.userDots{cc};
            if numel(dots)>0
                D = [D; dots(:,1:3)];
            end
        end
        
        ND = ND + size(D,1);
        sumd=zeros(size(D,1),1);
        
        
        if numel(sumd)>0
            for nn = 1:numel(sumd) % Number of clusters
                [idx,C,sd] = kmeans(D(:,1:3), nn);
                sumd(nn) = sum(sd);
            end
            
            
            ve = (sumd(1)-sumd)/sumd(1); % variance explained
            
            subplot(1,2,1)
            hold off
            plot(1:numel(sumd), ve)
            
            %% By curvature
            if 0
                dy = conv(ve, [1, 0,-1], 'same');
                ddy = conv(ve, [1, -2,1], 'same');
                k = -ddy./(1+dy.^2).^(3/2);
                k(1) = 0; k(end) = 0;
                nk = find(k==max(k));
            end
            
            %% When the additional explained variance is < 10%
            dve = ve - [0 ; ve(1:end-1)];
            dve(end)=0;
            
            nk = find(dve>.10); % This CONSTANT is important for the result
            
            if numel(nk)==0
                nk = 0;
            end
            
            nk = nk(end);
            if nk>0
                %keyboard
                if doPlot
                    hold on
                    %plot(k/max(k(:)));
                    plot([nk,nk], [0,1], 'r');
                    xlabel('Number of clusters')
                    ylabel('Sum of square residuals')
                    subplot(1,2,2)
                    hold off
                    [idx,C,sd] = kmeans(D(:,1:3), nk);
                    for cl = 1:max(idx)
                        plot3(D(idx==cl,1), D(idx==cl,2), D(idx==cl,3), 'o')
                        hold all
                    end
                    view(3)
                    axis equal
                    hold off
                    pause
                end
            end
            
            NC = [NC; nk];
        else
            fprintf('No userDots in %s (%d)\n', N{kk}.file, N{kk}.nucleiNr);
        end
    else
        warning(sprintf('No userDots in %s (%d)\n', N{kk}.file, N{kk}.nucleiNr));
    end
end

figure
histogram(NC)
title('Number of clusters')

end
