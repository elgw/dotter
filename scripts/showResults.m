folder = '/Users/erikw/data/290113/290113_samplesOF280113/4/';
files = dir([folder '*twocolor']);
addpath('../dotter')

%% Get statistics on the number of dots etc
% Dots per nuclei for each channel.
dots_c1 = zeros(50,1);
dots_c2 = zeros(50,1);
for kk = 1:numel(files)    
    load([folder files(kk).name], '-mat')    
    for ll = 1:numel(F)
        if numel(F{ll})>0
            nc1 = size(F{ll}.c1fit,1)+1;
            dots_c1(nc1) = dots_c1(nc1)+1;
            
            nc2 = size(F{ll}.c2fit,1)+1;
            dots_c2(nc2) = dots_c2(nc2)+1;            
        end
    end
end

fig_n_selected_dots = figure;
subplot(1,2,1)
bar(0:numel(dots_c1)-1, dots_c1)
title(M.channel1);
subplot(1,2,2)
bar(0:numel(dots_c2)-1, dots_c2)
title(M.channel2);
xlabel('Number of dots')
ylabel('#')

print(fig_n_selected_dots, '-dpng', [folder 'analysis/n_selected_dots.pdf']);
savefig(fig_n_selected_dots, [folder 'analysis/n_selected_dots.fig']);

break 
%% Visualizations

Dots = [];
NN = 0;

for kk = 1:numel(files)
    
    
    load([folder files(kk).name], '-mat')
    mask = M.mask;
    idapi = df_readTif(M.dapifile);
    ic1 = df_readTif(M.c1file);
    ic2 = df_readTif(M.c2file);
  
    
    for ll = 1:numel(F)
        if numel(F{ll})>0
            F{ll}
            
            NN = NN+1;
            Dots{NN}= F{ll};

    c1fit = F{ll}.c1fit;
    c2fit = F{ll}.c2fit;
    
    d1 = c1fit(1:14,1:3);
    d2 = c2fit(1:14,1:3);
    md = mean([d1;d2])
    % remove mean
    d1(:,1) = d1(:,1)-md(1);
    d1(:,2) = d1(:,2)-md(2);
    d1(:,3) = d1(:,3)-md(3);
    d2(:,1) = d2(:,1)-md(1);
    d2(:,2) = d2(:,2)-md(2);
    d2(:,3) = d2(:,3)-md(3);
    % scale x and y
    d1(:,1:2) = d1(:,1:2)*125;
    d1(:,3) = d1(:,3)*200;
    d2(:,1:2) = d2(:,1:2)*125;
    d2(:,3) = d2(:,3)*200;
    
    if 1
    fig = figure
    plot3(d1(:,1), d1(:,2), d1(:,3), 'ro');
    hold on
    plot3(d2(:,1), d2(:,2), d2(:,3), 'go');
    axis vis3d
    view(3)
    savefig(sprintf('%d_%d.fig', kk, ll));
    print('-dpng', sprintf('%d_%d.png', kk, ll));
    close(fig)
    end
        end
    end
end

save('Dots.mat', 'Dots')