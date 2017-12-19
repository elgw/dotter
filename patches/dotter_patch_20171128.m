% patch for Quim 2017-11-28
% For some reason the meta data contained double channel names:
%       dapifile: '/Volumes/microscopy_data_2/Temporal/GPSeq analysis/Analysis/HAP1/iJC852_20171004_001/dapi…'
%      nTrueDots: [2 2 2 2 2 2]
%       channels: {'a594'  'a594_____'  'cy5'  'cy5_____'  'tmr'  'tmr_____'}
% Probably dots were detected twice and the image names were changed in
% between.

folder = '/mnt/bicroserver2/microscopy_data_2/Temporal/GPSeq analysis/Analysis/HAP1/iJC852_20171004_001_calc/';
ls(folder)
files = dir([folder '*.NM']);

    file = [folder files(1).name];
    D = load(file, '-mat');
    pause

for kk = 1:numel(files)
    file = [folder files(kk).name];
    D = load(file, '-mat');
    disp(D.M.channels)
    disp(D.M.dapifile);
    D.M.dapifile = strrep(D.M.dapifile, '______', '_');
    disp(D.M.dapifile);
    
    M = D.M;
    N = D.N;
    %save(file, 'M','N'); % second match
    
end

if 0
    % The patch
    file = [folder files(1).name];
    M.channels = {'a594', 'cy5', 'tmr'};
    save(file, 'M', M, 'N', N);
end