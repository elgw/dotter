function cCorrFolder2(folder, ccFile)
%% function cCorrFolder(folder, ccFile)
% Apply correction for chromatic aberrations in the specified folder
% using coefficients specified in ccFile
%
%% Example
% cCorrFolder('/data/current_images/iMB31_004/', '~/code/cCorr/cc2_200912.mat');

if folder(end) ~= '/'
    folder = [folder '/'];
end

files = dir([folder '*.tif']);
outDir = [folder 'cc/'];

if numel(files)>0
    if ~exist(outDir, 'dir')
        mkdir(outDir);
    end
else
    disp('No files');
    return;
end

cc = load(ccFile);

for kk = 1:numel(files)    
    fprintf('(%d/%d) %s\n', kk, numel(files), files(kk).name);
    tic
    I = df_readTif([folder files(kk).name]);
    channel = im2chan_name(files(kk).name);
    cn = find(strcmp(cc.chan, channel));
    Cx = cc.Cx{cn};
    Cy = cc.Cy{cn};
    dz = cc.dz(cn);
    
    C = cCorrI2(I, Cx, Cy, dz);
    df_writeTif(uint16(C), [outDir files(kk).name]);
    toc
end
fprintf('done\n');

end