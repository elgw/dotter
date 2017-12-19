folder = '/data/current_images/iEG/iEG364_20170524_004/';

files = dir([folder '*.tif']);

nNames = 0;
names = {};
for kk = 1:numel(files)
    fName = files(kk).name;
    pos = strfind(fName, '_');
    if numel(pos)>0
        nNames = nNames + 1;
        names{nNames} = fName(1:pos-1);
    end
end

names = unique(names);
newNames = inputdlg(names, ...% Prompt
    'New names', ... % title
    1); % number of lines

if numel(newNames) == numel(names)
    for kk = 1:numel(files)
        fName = files(kk).name;
        fNameNew = fName;
        for nn = 1:numel(names)
            fNameNew = strrep(fNameNew, names{nn}, newNames{nn});
        end
        fprintf('movefile(''%s'', ''%s'')\n', [folder fName], [folder, fNameNew]);
        movefile([folder fName], [folder, fNameNew]);
    end
else
    disp('No new names given');
end
