function [m] = df_readExternalMask(file)
% Read an external 2D/3D mask from a file and projects it down to 2D

if ~exist('file', 'var')
    error('No file specified')
end

if ~ischar(file)
    error('File name has to be provided as a string');
end

fprintf('Reading mask from %s\n', file);

if ~exist(file, 'file')
    error('Can not read file')
end

if(strcmpi(file(end-3:end), '.tif'))
    I = df_readTif(file);
else
    I = imread(file);
    m = uint16(I);
end

I = double(I); % uint32 can not be nan

if(size(I,3)==1)
    warning('The external mask is not 3D');
end

% If the nuclei are not labelled, label them
if numel(unique(I(:))) == 2
    fprintf('Labelling the mask\n');
    I = bwlabeln(I);
end

if size(I,3)>1
    fprintf('  Projecting 3D mask to 2D\n');    
    I(I(:)==0) = nan;
    m = mode(I, 3); % mode in Z, nans ignored
    m = uint16(m);        
else
    m = uint16(I);
end

% No nuclei
if(sum(m(:)) == 0)    
    return
end

% Check that no mask numbers are skipped
if(sum(m(:)==0) == 0)
 warning('Strange mask! There are no background pixels');
 m = 0*m;
 return
end


u = unique(m(:)); % unique elements, is sorted
if(~(max(m(:)) +1 == numel(u))) % If one or more labels are skipped
    m = uint16(...
        interp1(double(u'), double(0:numel(u)-1), double(m), 'nearest')...
        );
end

assert( (max(m(:)) +1 == numel(unique(m(:)))));

end
