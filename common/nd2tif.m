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
    s.focus_distance = 20;
    s.focus_check = 0;
    s.focus_skip = 0;
    s.onlyFirst = 0;
    s.asMAT = 0;
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
fprintf(s.logFile, 'XYZT: [%d, %d, %d %d]\nChannels %d \n', ...
    reader.getSizeX(), reader.getSizeY(), ...
    reader.getSizeZ(), reader.getSizeT(), ...
    reader.getSizeC());

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

waitMSG = 'Converting to tif';
if(s.asMAT)
    waitMSG = 'Converting to mat';
end
w = waitbar(0, waitMSG);
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

    % iPlane = reader.getIndex(iZ - 1, iC -1, iT - 1) + 1;
    
    save_fov = 1;
    for cc = 1:channelOrder
        if save_fov == 1
            assert(min(reader.getSizeZ(), reader.getSizeT()) == 1);
            
            if reader.getSizeT()==1                
                nSlices = reader.getSizeZ();
                slice_mode = 1;
            else
                nSlices = reader.getSizeT();
                slice_mode = 2;
            end
            
            V = zeros(reader.getSizeY(), reader.getSizeX(), nSlices, 'uint16');
                            
            for ll = 1:nSlices
                % getSeries(z,c,t);
                if slice_mode == 1
                    plane = reader.getIndex(ll-1,cc-1,0)+1;
                end
                if slice_mode == 2
                    plane = reader.getIndex(0,cc-1,ll-1)+1;
                end                    
                
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
            if(strcmpi(cName, 'dapi') == 1)
                cName = 'dapi';
            end
                
            outFileName = sprintf('%s%s_%03d.tif', outFolder, cName, kk);
            
            % TODO: put meta data in tif files
            metaOutFileName = sprintf('%s%s_%03d.txt', outFolder, cName, kk);
            metaFile = fopen(metaOutFileName, 'w');
            
            fprintf(metaFile, '%s\n', omeMeta.getPixelsPhysicalSizeX(0).toString());           
            fprintf(metaFile, '%s\n', omeMeta.getPixelsPhysicalSizeY(0).toString());
            fprintf(metaFile, '%s\n', omeMeta.getPixelsPhysicalSizeZ(0).toString());
            
            fclose(metaFile);

            
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
                if s.asMAT == 1
                    save([outFileName '.mat'], 'V', '-v7.3', '-nocompression');
                else
                df_writeTif(V, outFileName);
                end
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
