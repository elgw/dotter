% Nikon elements viewer was used to export all slices from the nd2 file,
% Then this script was used to assemble them into volumetric tifs

infolder = '/Users/erikw/data/310715_iMB2/';

outfolder = '/Users/erikw/data/310715_iMB2/stacks/';

try 
    mkdir(outfolder)
end
channels = {'dapi', 'tmr', 'a594', 'cy5'};

for set = 1:14 % xy in filename    
    for channel = 1:4 % C in filename
        V = zeros(1895,1895,51, 'uint16');
        for slice = 1:51                
            filename = sprintf('iMB2_310715_003Z%02dXY%02dC%d.tif', slice, set, channel);
            I = imread([infolder filename]);
            V(:,:,slice)=I;
        end
                
        ofname = sprintf('%s%s_%03d.tif', outfolder, channels{channel}, set);
        write_tif_volume(ofname, V);            
        disp(ofname)        
        
    end
end

