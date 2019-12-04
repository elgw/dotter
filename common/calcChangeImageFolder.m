% Purpose: Load NM files and change the pointers there
% that directs to the folders that contain the original image data

files = dir('*.NM');

if numel(files)==0
    disp('No NM files in this directory')
    return
end

NM = load(files(1).name, '-mat');

disp('Assuming that the image files are called dapi_XTZ.tif')

currDir = NM.M.dapifile;
currDir = currDir(1:end-12);


disp('Do you want to change this for all NM files in the folder?')

ans = questdlg(...
    ['Do you want to change the current image directory: ' currDir '?'], ...
    'Change image folder for NM files', ...
    'Yes', 'No', 'Cancel', 'No');


switch ans
    case 'Yes'
        newDir = uigetdir('', 'Select the folder with the image');
    case 'No'
        disp('Quiting')
        return
    case 'Cancel'
        disp('Quiting')
        return
end


newDir = [newDir '/'];

fprintf('Changing image directory from %s to %s for %d files\n', ...
    currDir, newDir, numel(files));

        
for kk = 1:numel(files)
    NM = load(files(kk).name, '-mat');
    NM.M.dapifile = [newDir NM.M.dapifile(end-11:end)];
    M = NM.M; N = NM.N;    
    save(files(kk).name, 'NM.M', 'NM.N');
end

disp('Done');
