function [N, nucNum]= associate_dots_to_nuclei(N, mask, dots, cnum, varargin)
% function [N]= associate_dots_to_nuclei(N, mask, dots, cnum)
% Appends dots to nuclei
% N: structure with nuclei
% mask: mask of nuclei
% dots: dots in the image
% cnum: channel number

dilation = 0;

for kk=1:numel(varargin)
    if strcmp(varargin{kk}, 'dilation')
        dilation = varargin{kk+1};
    end
end

if dilation ==0
    if numel(size(mask)) == 2
        nucNum = interpn(mask, dots(:,1), dots(:,2), 'nearest');
    end
    if numel(size(mask)) == 3
        nucNum = interpn(mask, dots(:,1), dots(:,2), dots(:,3), 'nearest');
    end
else
    fprintf('Dilating the DAPI-mask by %d pixels\n', dilation);
    mask = imdilate(mask, strel('disk', dilation));
    nucNum = interpn(mask, dots(:,1), dots(:,2), 'nearest');
end

for kk=1:numel(N)
    N{kk}.dots{cnum} = dots(nucNum == kk, :);
end
end