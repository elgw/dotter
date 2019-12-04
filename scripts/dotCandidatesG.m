function [ P ] = dotCandidatesG(I, s)
%{

dot candidates using correlation to a Gaussian filter, as in DAOPHOT

%}

if nargin == 0 && nargout == 0
    help dotCandidatesG
    return
end

if nargin < 2
    s.sigma = 1.2;
    s.xypadding = 2;
end

if nargin == 0 && nargout == 1
    P = s;
    return
end

s.verbose = 1;

%% Warn about saturation
% Only known about 8- and 16- bit images.


if max(I(:))>256
    % 16 bit
    nSat = sum(I(:)==2^16-1);
    type = 16;
    if nSat>0
        fprintf(2, 'Warning: if the image is 16 bit there are %d saturated pixels\n', nSat);
    end
else
    nSat = sum(I(:)==2^8-1);
    type = 8;
    if nSat>0
        fprintf(2, 'Warning: if the image is 8 bit there are %d saturated pixels\n', nSat);
    end
end


if nSat>0
    fprintf(' Consider removing dots where the intensity is %d by:\n', 2^type-1);
    fprintf(' P = P(P(:,5)<%d,:)\n', 2^type-1);
end

I = double(I);

si = ceil(2*s.sigma+1);
si = si+mod(si,2)-1;
si = 11;

if size(I,3)<=1
    K = fspecial('gaussian', [si, si], s.sigma);
    K = K/max(K(:));
    K = K-mean(K(:));
    K = K/sum(K(:).^2);
    %figure(2), imagesc(K)
else
    disp('Only 2D')
    return
end

K = K-sum(K(:))/numel(K);
sum(K(:));

J = convn(I, K, 'same');

sel = ones(3,3);
sel(2,2)=0;

A = imdilate(J, strel('arbitrary', sel));
A=clearBoarders(A,1,inf);
A=clearBoardersXY(A,s.xypadding,inf);
A(I==2^16-1)=-1; % Don't consider saturated pixels
Pos = find(J>A);

[PX, PY, PZ]=ind2sub(size(I), Pos);

P(:,4)=J(Pos);
P(:,5)=I(Pos);
P(:,1)=PX;
P(:,2)=PY;
P(:,3)=PZ;
[~, IDX]=sort(P(:,4), 'descend');
P = P(IDX, :);

end

