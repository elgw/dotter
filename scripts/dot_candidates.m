function P = dot_candidates(I, s)
%% function P = dot_candidates(I, s)
% Extracts dots from the stack I as local maximas and orders them according
% to the DoG there
% P: x, y, z, DoG value, intensity
I = double(I);

s.sigmadog = 1.2;
s.maxNpoints = 10000;
s.xypadding = 5;

%% Locate local maximas using 8- (2D) and 26- (3D) connectivity.
J = I; %clearBoarders(I, 3);
if size(J,3)>1
    A = imdilate(J, strel('arbitrary', ones(3,3,3)));
else
    A = imdilate(J, strel('square', 3));
end

A=clearBoarders(A,1,-1);

A=clearBoardersXY(A,s.xypadding,-1);

A(I==2^16-1)=-1; % Don't consider saturated pixels

Pos = find(J==A);
[PX, PY, PZ]=ind2sub(size(I), Pos);

P = zeros(size(PX,1), 5);
P(:,1)=PX;
P(:,2)=PY;
P(:,3)=PZ;

%% DoG Filter to see the DoG response at the maximas
for kk = 1:size(I,3)
    DoG(:,:,kk) = gsmooth(I(:,:,kk), s.sigmadog)-gsmooth(I(:,:,kk), s.sigmadog+0.01);
end
P(:,4)=DoG(Pos);
P(:,5)=I(Pos);
[~, IDX]=sort(P(:,4), 'descend');
P = P(IDX, :);

if size(P,1)>s.maxNpoints
    P = P(1:s.maxNpoints, :);
end
end
