function df_resetUserDots_fromNN(folder)

warning('Highly experimental, press a key to continue')
pause

folder = '/data/current_images/iEG/iEG458_171304_004_calc_nn'

files = dir([folder filesep() '*.NM']);

for ff = 1 % :numel(files)
    file = files(ff).name;
    nmfile = [folder filesep() file];
    fprintf('Loading nm file: %s\n', nmfile)
    [M, N] = df_nm_load(nmfile);
    M = M{1};
    
    fieldString = file(1:3);
    channelString = 'a594';
    
    dotTableName = [fieldString '_' channelString '_metapatches.tsv'];
    
    fprintf('Loading dot table: %s\n', dotTableName)
    
    dots = tdfread(dotTableName, '\t');
    vdots = struct2array(dots);
    vdots = vdots(vdots(:,end)>.5, :);
    
    warning('Assuming that a594 is channel 3')
    M.dots{3} = vdots;
    fprintf('Saving nm file\n')
    df_nm_save(M, N, nmfile);
    
end

end
    