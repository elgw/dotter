% Nikon elements viewer was used to export all slices from the nd2 file,
% Then this script was used to assemble them into volumetric tifs

infolder = '/Volumes/ext_erikw/iMB4_tif/';

outfolder = '/Users/erikw/data/310715/';

try 
    mkdir(outfolder)
end
channels = {'dapi', 'tmr', 'a594', 'cy5'};

for set = 1:11    
    for channel = 1:4
        V = zeros(2038,2038,51, 'uint16');
        for slice = 1:51                
        filename = sprintf('iMB4_310715_001Z%02dXY%02dC%d.tif', slice, set, channel);
        I = imread([infolder filename]);
        V(:,:,slice)=I;
        end
        
        
        % For each quadrant
        
        w = 1019;
        
        ofname = sprintf('%s%s_%03d.tif', outfolder, channels{channel}, (set-1)*4+1);
        write_tif_volume(ofname, V(1:w, 1:w, :));            
        disp(ofname)
        
        ofname = sprintf('%s%s_%03d.tif', outfolder, channels{channel}, (set-1)*4+2);
        write_tif_volume(ofname, V(w:end, 1:w, :));            
        disp(ofname)
        
        ofname = sprintf('%s%s_%03d.tif', outfolder, channels{channel}, (set-1)*4+3);
        write_tif_volume(ofname, V(1:w, w:end, :));            
        disp(ofname)        
        
        ofname = sprintf('%s%s_%03d.tif', outfolder, channels{channel}, (set-1)*4+4);
        write_tif_volume(ofname, V(w:end, w:end,:));            
        disp(ofname)
        
    end
end

