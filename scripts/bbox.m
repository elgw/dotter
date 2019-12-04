function [bb] = bbox(I)
%% function [bb] = bbox(I)
% Finds a bounding box around the binary object == 1 in I
% Returns [0,0,0,0] on failure
%

if size(I,3)>1
    I = max(I,[],3);
end

I(:,end+1) = zeros(size(I,1), 1);
I(end+1,:) = zeros(1,size(I,2));

s1 = max(I,[], 2);
xstart = find(s1==1);
if numel(xstart) == 0
    warning('Object not found!')
    bb = [0,0,0,0];
    return    
end
bb(1) = xstart(1);
s1(1:bb(1))=1;
xend = find(s1==0);
bb(2)=xend(1);


s2 = max(I,[], 1);
ystart = find(s2==1);
bb(3) = ystart(1);
s2(1:bb(3))=1;
yend = find(s2==0);
bb(4)=yend(1);

if 0
    I2 = I;
    I2(xstart:xend, ystart:yend)=1;
    figure, imagesc(I+I2);
end

end