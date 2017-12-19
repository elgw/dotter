function D_dots_per_nuclei(folder)
% Get and write the number of dots per nuclei for a _calc folder with
% userDots
%
% To do:
% - Restrictive coding
%
% 2017-02-01
%
% Also calculates the area of the alleles
%

files = dir([folder '/*.NM']);
fprintf('Found %d files\n', numel(files));

xres = 130;
yres = 130;
zres = 300;
radius = 2*390; % nm 

x = inputdlg({'x-resolution', 'z-resolution', 'dilation radius'}, ...
    'Settings for allele volume calculations', 1, ...
    {num2str(xres), num2str(zres),num2str(radius)});

if numel(x)==0
    return
end

xres = str2num(x{1});
yres = xres;
zres = str2num(x{2});
radius = str2num(x{3});

fprintf('xres: %f\n', xres);
fprintf('yres: %f\n', yres);
fprintf('zres: %f\n', zres);
fprintf('radius: %f\n', radius);


%% Create new list of files, keep only those with userDots

N = []; % Store all nuclei
errlog = '';
proceed = 1;
for kk = 1:numel(files)
    errlog = [errlog sprintf('Opening %s\n', files(kk).name)];
    T = load([folder filesep() files(kk).name], '-MAT');
    if kk == 1
        channels = T.M.channels;
    else
        if ~isequal(channels, T.M.channels)
            errlog = [errlog sprintf(' - Different channels compared to the first field\n')];
            proceed = 0;
        end
    end
    if ~proceed
        errlog = [errlog '!!! Aborting\n'];
        msgbox(errlog);
        return
    end
    
    if numel(T.N)>0
        for kk = 1:numel(T.N)
            if isfield(T.N{kk}, 'userDots')
                N = [N T.N{kk}];
            else
                errlog = [errlog sprintf('- No userDots in nuceli %d\n', kk)];
            end
        end
        errlog = [errlog sprintf('- %d processed\n', kk)];
    else
        errlog = [errlog sprintf(' - Warning: no nuclei\n')];
    end
end

m = msgbox(errlog);
uiwait(m)

fprintf('Proceeding with the analysis\n')
channels = T.M.channels;

% All Nuclei in N
for cc = 1:numel(channels)
    fprintf('Channel %s\n', channels{cc});
    ND = [];
    NDC = [];
    
    for nn = 1:numel(N)
        ndots = size(N(nn).userDots{cc},1);
        ND = [ND ndots];
        
        for kk = 1:2
            ncdots = sum(N(nn).userDotsLabels{cc}==kk);
            NDC = [NDC ncdots];
        end
    end
    
    
    if numel(ND)>0
        figure
        ehistogram('data', ND, 'xlabel', '# dots', ...
            'ylabel', sprintf('#nuclei (%d)', numel(ND)), ...
            'title', ...
            sprintf('Per nuclei, Channel: %s', channels{cc}), ...
            'legend', sprintf('Mean %.2f, std: %.2f', mean(ND), std(ND)) ...
            );
    else
        disp('No dots to show in ND');
    end
    
    if numel(NDC)>0
        figure
        h =ehistogram('data', NDC, 'xlabel', '# dots', ...
            'ylabel', sprintf('#nuclei (%d)', numel(ND)), ...
            'title', ...
            sprintf('Per cluster, Channel: %s', channels{cc}), ...
            'legend', sprintf('Mean %.2f, std: %.2f', mean(NDC), std(NDC)) ...
            );
    else
        disp('No dots to show in NDC');
    end
end

AlleleAreas = [];
for nn = 1:numel(N)
    for allele = 1:2
        Dots = [];
        for cc = 1:numel(channels)
            tDots = N(nn).userDots{cc};
            tDots = tDots(N(nn).userDotsLabels{cc} == allele, :);
            Dots = [Dots ; tDots];
        end
        
        if size(Dots,1)>0
            
            Dots(:,1) = Dots(:,1)*xres;
            Dots(:,2) = Dots(:,2)*yres;
            Dots(:,3) = Dots(:,3)*zres;
            
            Dots = [Dots(:,1:3) radius*ones(size(Dots,1),1)];
            
            %AlleleAreas = [AlleleAreas; [AreaOfSpheres(Dots, 'verbose'), size(Dots,1)]];
            AlleleAreas = [AlleleAreas; [df_volumeSpheres(Dots), size(Dots,1)]];
                        
        end
    end
end


% Fix visualization of AlleleAreas
% Group by number of dots, i.e. sort by second column

ndotsrange = 1:max(AlleleAreas(:,2));
for kk = ndotsrange
   alleleVolMean(kk) = mean(AlleleAreas(AlleleAreas(:,2)==kk, 1)); 
   alleleVolStd(kk)  = std(AlleleAreas(AlleleAreas(:,2)==kk, 1)); 
end

figure
plot(ndotsrange, alleleVolMean, 'k', 'lineWidth', 2)
hold on
plot(ndotsrange, alleleVolMean+alleleVolStd, 'b', 'lineWidth', 1)
scatter(AlleleAreas(:,2), AlleleAreas(:,1))
plot(ndotsrange, ndotsrange*4/3*pi*radius^3, 'g--')
legend({'Mean', 'Mean+/-Std', 'Individual', 'T.Max'}, 'location', 'NorthWest')
plot(ndotsrange, alleleVolMean-alleleVolStd, 'b', 'lineWidth', 1)

xlabel('Number of dots')
ylabel(sprintf('Volume (dilation radius=%.0f nm)', radius));
title('Volume of alleles')
grid on
a = axis;
a(1) = .5;
a(3) = 0;
axis(a);


%% Dots per nuclei and per cluster for all channels
ND = [];
NA = [];

for nn = 1:numel(N)
    
    nd = 0;
    na1 = 0;
    na2 = 0;
    
    for cc = 1:numel(channels)
        nd = nd+size(N(nn).userDots{cc},1);
        na1 = na1 + sum(N(nn).userDotsLabels{cc} == 1);
        na2 = na2 + sum(N(nn).userDotsLabels{cc} == 2);
    end
    
    ND = [nd ND];
    NA = [na1 na2 NA];
end

if numel(ND)>0
    figure
    h =ehistogram('data', ND, 'xlabel', '# dots', ...
        'ylabel', sprintf('#nuclei (%d)', numel(ND)), ...
        'title', ...
        sprintf('Per Nuclei -- All Channels'), ...
        'legend', sprintf('Mean %.2f, std: %.2f', mean(ND), std(ND)) ...
        );
else
    disp('No dots to show in ND');
end

if numel(NA)>0
    figure
    h =ehistogram('data', NA, 'xlabel', '# dots', ...
        'ylabel', sprintf('#alleles (%d)', numel(NA)), ...
        'title', ...
        sprintf('Per Allele -- All Channels'), ...
        'legend', sprintf('Mean %.2f, std: %.2f', mean(NA), std(NA)) ...
        );
else
    disp('No dots to show in NA');
end

end