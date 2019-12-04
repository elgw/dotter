fprintf(['This is an interactive script for registration of several\n', ...
    'small images (sub images) onto a large image (domain)\n']);

s = [];

%% Select target image
disp('Press <enter> to select a target image')
pause
[file, folder] = uigetfile('*.*', 'Select a target image');
s.targetImage = [folder file];


%% Pixel size
disp('Press <enter> to set the pixel size of the target image. The unit is arbitrary but you need to be consistent later on. nm is suggested.');
pause
s.targetResolution = inputdlg('What is the pixel size of the target image?');
s.targetResolution = str2double(s.targetResolution);

%% Select subimages
disp('Press enter to pick file(s) to register into the target image');
pause
s.subImages = uipickfiles('FilterSpec', folder);
fprintf('%d files selected\n', numel(s.subImages));

disp('Press <enter> to set the pixel size of the sub image(s).');
pause
s.subimageResolution = inputdlg('What is the pixel size of the target image?');
s.subimageResolution = str2double(s.subimageResolution);

s.flipVert = questdlg('Flip the images vertically?', '', 'Yes', 'No', 'Yes');
if strcmp(s.flipVert, 'Yes')==1
    s.flipVert = 1;
else
    s.flipVert = 0;
end

s.invertTarget = questdlg('Invert target image?', '', 'Yes', 'No', 'Yes');
if strcmp(s.invertTarget, 'Yes')==1
    s.invertTarget = 1;
else
    s.invertTarget = 0;
end


disp('Often the images are larger than necessary.')
disp('Set a scale factor to work with');
s.scaling = inputdlg('Set scale factor (1==none, .5 = half, ...)');
s.scaling = str2double(s.scaling);

%% Where to save the result?
disp('Here is what we have got:')
disp(s)
disp('Press <enter> to specify where to store the results.')
pause
s.outputFolder = uigetdir();

s.matFile = [s.outputFolder filesep() 'msRegistration.mat'];
save(s.matFile, 's');

fprintf('Settings stored to %s\n', s.matFile);
disp('You can edit that file (use load and save) if you want.');

disp('');
disp('Running the registration, i.e.,');
fprintf('msRegistrationRun(''%s'')\n', s.matFile);

%% Do the stuff
msRegistrationRun(s.matFile);