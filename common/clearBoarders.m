function I = clearBoarders(I, padding, value)
% Sets the edge pixels to zeros

if ~exist('value', 'var')
    value = 0;
end

if numel(size(I)) == 2
    I(1:padding, :)=value;
    I((end-padding+1):end, :)=value;
    I(:,1:padding)=value;
    I(:,(end-padding+1):end)=value;
end

if numel(size(I)) == 3
    I(1:padding, :, :)=value;
    I((end-padding+1):end, :, :)=value;
    I(:,1:padding, :)=value;
    I(:,(end-padding+1):end, :)=value;
    I(:,:,1:padding) = value;
    I(:,:,(end-padding+1):end)=value;
end

end