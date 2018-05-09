function cCorrFolder(cCorrFile, refChannel)
%% function cCorrFolder(cCorrFile, refChannel)
% Apply correction for chromatic aberrations in the current folder
% cCorrFile: measurement file created by cCorrMeasure
% refChannel: reference channel, pick a channel in between the extremes
%
%% Example
% cd ~/data/iMB32_002/
% cCorrFolder('~/code/cCorr/cc_200912.mat', 'cy5');

files = dir('*.tif');

if numel(files)>0
    mkdir('cc');
else
    disp('No files');
    return;
end

cc = load(cCorrFile);

%% Figure out a suitable reference channel
figure
for kk = 1:numel(cc.chan)
    hold all
    plot(cc.F{kk}(:,2), cc.F{kk}(:,1), 'x')
end
legend(cc.chan);

% For 200912:
% refChannel = 'cy5'
maxDist = 13;

disp(['Using reference channel ' refChannel])

figure

for kk = 1:numel(cc.chan)
    hold all
    C = cCorrI(cc.F{kk}(:,1:3), cc.chan{kk}, refChannel, cCorrFile, maxDist);
    plot(C(:,2), C(:,1), 'x')
end
legend(cc.chan);


pause


logfile = fopen('log_cCorrFolder.txt', 'w');
fprintf(logfile, 'Date: %s\n', date);
fprintf(logfile, 'cCorrFile: %s\n', cCorrFile);
fprintf(logfile, 'refChannel: %s\n', refChannel);
fprintf(logfile, 'maxDist: %f\n', maxDist);
fclose(logfile);

for kk = 1:numel(files)
    fprintf('%s\n', files(kk).name);
    
    
    channel = strsplit(files(kk).name, '_');
    channel = channel{1};
    
    V = df_readTif(files(kk).name);
    for ss=1:size(V,3)
        V(:,:,ss) = cCorrI(V(:,:,ss), channel, refChannel, cCorrFile, maxDist);
    end
    
    df_writeTif(V, sprintf('cc/%s', files(kk).name));
end


