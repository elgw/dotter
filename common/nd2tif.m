function nd2tif(object, outputDir, s)
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

if nargin<3
    warning('No settings provided, using defaults');
    s.logFile = 1; % standard out
    s.focus_check = 1;
    s.focus_skip = 0;
    s.onlyFirst = 0;
end

fprintf(s.logFile, '%.1f GB free on the target drive\n', usable_bytes/1024/1024/1024);


if nargin == 0
    [file, folder] = uigetfile('*.nd2');
    object = [folder file];
    
    if file == 0
        fprintf(s.logFile, 'No file specified, quiting\n');
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
    fprintf(s.logFile, '%s treated as directory\n', object);
    files = dir([object '*.nd2']);
    
    for kk = 1:numel(files)
        
        fprintf(s.logFile, '\n(%d/%d) %s\n\n', kk, numel(files), files(kk).name);
        BFfile2tif([object, files(kk).name], outputDir, s);
    end
    
else
    fprintf(s.logFile, '%s treated as file\n', object);
    BFfile2tif(object, outputDir, s);
end
end

function BFfile2tif(filename, outputDir, s)
reader = bfGetReader(filename);

outFolder = strsplit(filename, '/');
outFolder = outFolder(end);
outFolder = [outputDir outFolder{1}(1:end-4) '/'];

if ~exist(outFolder, 'dir')
    mkdir(outFolder)
end

fprintf(s.logFile, 'Dimension order: %s\n', char(reader.getDimensionOrder()));
fprintf(s.logFile, 'Number of series: %d\n', char(reader.getSeriesCount));
fprintf(s.logFile, 'XYZ: [%d, %d, %d]\nChannels %d \n', ...
    reader.getSizeX(), reader.getSizeY(), ...
    reader.getSizeZ(), reader.getSizeC());

% For meta data of the nd2 file format:
% https://www.openmicroscopy.org/site/support/bio-formats5.1/formats/nikon-nis-elements-nd2-metadata.html
% Channel : Name
% Channel : ID

omeMeta = reader.getMetadataStore();
omeMeta.getChannelName(0,0);

nSeries = reader.getSeriesCount();
if s.onlyFirst == 1
    nSeries = min(nSeries,1);
end

w = waitbar(0, 'Converting to tif');
for kk = 1:nSeries
    waitbar((kk-1)/nSeries, w);
    
    reader.setSeries(kk-1);
    
    %% Figure out which channel is DAPI
    % Make sure to load that one first
    
    dapiFound = 0;
    channelOrder = reader.getSizeC();
    for cc = 1:reader.getSizeC()
        channels{cc} = upper(char(omeMeta.getChannelName(0,cc-1)));
        if numel(strfind(channels{cc}, 'DAPI'))>0
            channelOrder = circshift(channelOrder, [0, 1-cc]);
            cc = inf;
            dapiFound = 1;
        end
    end
    
    if dapiFound ~= 1
        fprintf(s.logFile, 'WARNING: No dapi channel found\n');
    end
    
    save_fov = 1;
    for cc = 1:channelOrder
        if save_fov == 1
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
            
            if cc==1 % DAPI
                if s.focus_check
                    F = df_image_focus('image', V, 'method', 'gm');
                    if 0 % Plot out of focus curves
                        figure(11)
                        hold on
                        plot(F)
                        drawnow
                    end
                    
                    fmax = find(F==max(F));
                    fmax = mean(fmax);
                    fprintf(s.logFile, 'Focus at %f\n', fmax);
                    if fmax<s.focus_distance
                        fprintf(s.logFile, 'WARNING: Focus at %.1f is too close to the first slice!\n', fmax);
                        if s.focus_skip == 1
                            save_fov = 0;
                        end
                    end
                    if fmax+s.focus_distance > size(V,3)
                        fprintf(s.logFile, 'WARNING: Focus at %.1f is too close to the last slice!\n', fmax);
                        if s.focus_skip == 1
                            save_fov = 0;
                        end
                    end
                end
            end
            
            if save_fov
                fprintf(s.logFile, 'Writing % s to: %s\n', filename, outFileName);
                write_tif_volume(V, outFileName);
            else
                fprintf(s.logFile, 'Not writing this field\n');
            end
        end
    end
end
close(w);
reader.close();
fprintf(s.logFile, 'nd2tif is done\n');

end