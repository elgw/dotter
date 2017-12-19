function nd2tif(object, outputDir, varargin)
%% function nd2tif(object)
% Reads the content of object: an nd2 file or folder with nd2 files
% for each .nd2 file, a sum folder is created 
% where the tif images are stored.
%
% Input:
%   fname.nd2
%
% Output, several files with name:
%   fname/channelName1_series.tif
%
% Notes:
%   - Has to be modified for MS Windows
%   - NIS Elements Viewer can also be used but will create one tif per
%     slice
% 
% Example:
%  > nd2tif(pwd()) will convert all nd2 files in current directory to tif
% Erik Wernersson

FileObj = java.io.File(outputDir);
%free_bytes = FileObj.getFreeSpace;
%total_bytes = FileObj.getTotalSpace;
usable_bytes = FileObj.getUsableSpace;

fprintf('%.1f GB free on the target drive\n', usable_bytes/1024/1024/1024);

onlyFirst = 0;
for kk = 1:numel(varargin)
if strcmp(varargin{kk}, 'onlyFirst')
    onlyFirst = 1;
end
end

if nargin == 0   
    [file, folder] = uigetfile('*.nd2');
    object = [folder file];
    
    if file == 0
        disp('No file specified, quiting')
    else
        BFfile2tif(folder, file, onlyFirst);
    end
    return
end

if ~exist('outputDir', 'var')
    outputDir = './';
end

if exist(object, 'dir')    
    if ~(object(end) == '/')
        object = [object '/'];
    end
    disp([object ' treated as directory'])
    files = dir([object '*.nd2']);
 
    for kk = 1:numel(files)
    
        fprintf('\n(%d/%d) %s\n\n', kk, numel(files), files(kk).name);
        BFfile2tif([object, files(kk).name], outputDir, onlyFirst);
    end
    
else
    disp([object ' treated as file'])
    BFfile2tif(object, outputDir, onlyFirst);
end
end

function BFfile2tif(filename, outputDir, onlyFirst)
reader = bfGetReader(filename);

outFolder = strsplit(filename, '/');
outFolder = outFolder(end);
outFolder = [outputDir outFolder{1}(1:end-4) '/'];

if ~exist(outFolder, 'dir')
    mkdir(outFolder)
end

fprintf('Dimension order: %s\n', char(reader.getDimensionOrder()));
fprintf('Number of series: %d\n', char(reader.getSeriesCount));
fprintf('XYZ: [%d, %d, %d]\nChannels %d \n', ...
    reader.getSizeX(), reader.getSizeY(), ...
    reader.getSizeZ(), reader.getSizeC());

% For meta data of the nd2 file format:
% https://www.openmicroscopy.org/site/support/bio-formats5.1/formats/nikon-nis-elements-nd2-metadata.html
% Channel : Name
% Channel : ID

omeMeta = reader.getMetadataStore();
omeMeta.getChannelName(0,0);

nSeries = reader.getSeriesCount();
if onlyFirst 
    nSeries = min(nSeries,1);
end
fprintf('...\n');
w = waitbar(0, 'Converting');
for kk = 1:nSeries
        waitbar((kk-1)/nSeries, w, sprintf('Position %d / %d', kk, nSeries));
    reader.setSeries(kk-1)
    for cc = 1:reader.getSizeC()
        V = zeros(reader.getSizeX(), reader.getSizeY(), reader.getSizeZ(), 'uint16');

        for ll = 1:reader.getSizeZ()            
            % getSeries(z,c,t);
            plane = reader.getIndex(ll-1,cc-1,0)+1;
            if size(V,3)==1
                V = bfGetPlane(reader, plane); 
            else
                V(:,:,ll)=bfGetPlane(reader, plane); 
            end
        end
        % getChannelName(imageIndex, channelIndex)
        cName = char(omeMeta.getChannelName(0,cc-1));       
        % remove everything that is not a letter or number
        cName = regexprep(cName,'[^a-zA-Z0-9]','');
        outFileName = sprintf('%s%s_%03d.tif', outFolder, cName, kk);
        fprintf('Writing % s to: %s\n', filename, outFileName);
        write_tif_volume(V, outFileName);        
    end
end

reader.close();
fprintf('nd2tif is done\n');
close(w);
end