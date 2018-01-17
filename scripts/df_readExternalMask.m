function [m] = df_readExternalMask(file)
% Read an external 2D/3D mask from a file and projects it down to 2D

fprintf('Reading mask from %s\n', file);
if(strcmpi(file(end-3:end), '.tif'))
    I = df_readTif(file);
else
    I = imread(file);
    m = uint16(I);
end

I = double(I); % uint32 can not be nan
    
if size(I,3)>1
    fprintf('  Projecting 3D mask to 2D\n');    
    I(I(:)==0) = nan;
    m = mode(I, 3); % mode in Z, nans ignored
    m = uint16(m);        
end

% Check that no mask numbers are skipped
assert(sum(m(:)==0) > 0); % Should be background

u = unique(m(:)); % unique elements, is sorted
if(~(max(m(:)) +1 == numel(u)))
    m = interp1(u', 0:numel(u)-1, m, 'nearest');
end

end