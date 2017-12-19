function nd2tif(object)
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

if nargin == 0   
    [file, folder] = uigetfile('*.czi');
    object = [folder file];
    
    if file == 0
        disp('No file specified, quiting')
    else
        czifile2tif(folder, file);
    end
    return
end

if exist(object, 'dir')    
    if ~(object(end) == '/')
        object = [object '/'];
    end
    disp([object ' treated as directory'])
    files = dir([object '*.czi']);
    for kk = 1:numel(files)
        czifile2tif(object, files(kk).name);
    end
else
    disp([object ' treated as file'])
    czifile2tif(object);
end
end

function czifile2tif(directory, filename)
reader = bfGetReader([directory filename]);

outFolder = strsplit(filename, '/');
outFolder = outFolder(end);
outFolder = [outFolder{1}(1:end-4) '/'];

if ~exist([directory outFolder], 'dir')
    mkdir([directory outFolder])
end

fprintf('Dimension order: %s\n', char(reader.getDimensionOrder()));
fprintf('Number of series: %d\n', char(reader.getSeriesCount));
fprintf('XYZ: [%d, %d, %d]\n #C %d \n', ...
    reader.getSizeX(), reader.getSizeY(), ...
    reader.getSizeZ(), reader.getSizeC());

% For meta data of the nd2 file format:
% https://www.openmicroscopy.org/site/support/bio-formats5.1/formats/nikon-nis-elements-nd2-metadata.html
% Channel : Name
% Channel : ID

omeMeta = reader.getMetadataStore();
omeMeta.getChannelName(0,0);

for kk = 1:reader.getSeriesCount()
    reader.setSeries(kk-1)
    for cc = 1:reader.getSizeC()
        V = zeros(reader.getSizeX(), reader.getSizeY(), reader.getSizeZ(), 'uint16');

        for ll = 1:reader.getSizeZ()
            % getSeries(z,c,t);
            plane = reader.getIndex(ll-1,cc-1,0)+1;
            
            V(:,:,ll)=bfGetPlane(reader, plane); 
        end
        % getChannelName(imageIndex, channelIndex)
        outFileName = sprintf('%s%s_%03d.tif', [directory outFolder], char(omeMeta.getChannelName(0,cc-1)), kk);
        fprintf('Writing to: %s\n', outFileName);
        write_tif_volume(V, outFileName);        
    end
end

reader.close();

end