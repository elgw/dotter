% Nikon elements viewer was used to export all slices from the nd2 file,
% Then this script was used to assemble them into volumetric tifs

infolder = '/Volumes/ext_erikw/EG/iEG11_tif/';
outfolder = [ infolder 'stacks/'];
basename = 'iEG11_040915_001';
res = [1024, 1024, 61];

if(~exist(outfolder, 'dir'))
    mkdir(outfolder)
end

channels = {'dapi', 'tmr', 'a594', 'cy5'};

%for set = 1:14 % xy in filename    
    for channel = 1:numel(channels) % C in filename
        V = zeros(res, 'uint16');
        for slice = 1:res(3)                
            %filename = sprintf('%sZ%02dXY%02dC%d.tif', basename, slice, set, channel);
            filename = sprintf('%sZ%02dC%d.tif', basename, slice, channel);
            I = imread([infolder filename]);
            V(:,:,slice)=I;
        end
                
        %ofname = sprintf('%s%s_%03d.tif', outfolder, channels{channel}, set);
        ofname = sprintf('%s%s.tif', outfolder, channels{channel});
        write_tif_volume(ofname, V);            
        disp(ofname)        
        
    end
%end

