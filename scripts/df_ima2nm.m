function df_ima2nm()

imadir = uigetdir('~/', 'Select folder with IMA files');

nmdir = uigetdir(imadir, 'Select a folder with NM files');
outFolder = uigetdir(nmdir, 'Select EMPTY output dir');

nmdir = [nmdir filesep()];
imadir = [imadir filesep()];
outFolder = [outFolder filesep()];

files = dir(outFolder);
if numel(files)>2
    error('Output folder not empty!')
end

imafiles = dir([imadir '*.ima']);
nmfiles = dir([nmdir '*.NM']);

if numel(imafiles) ~= numel(nmfiles)
    error('The number of NM files does not match the number of IMA files')
end

for kk = 1:numel(imafiles)
    imafile = [imadir imafiles(kk).name];
    nmfile = [nmdir nmfiles(kk).name];
    fprintf('%s, %s -> %s\n', imafile, nmfile, outFolder);
    df_ima2nm_file(imafile, nmfile, outFolder);
end

end