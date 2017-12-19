function P = getNuclei(IA, IB)
% Segment all nuclei and place them in a structure together with basic 
% features
IA = IA;
level = graythresh(IA);
mask = IA>level*2^16;
mask0 = mask;
mask = imfill(mask, 'holes');
mask(:,1)=1; mask(:,end)=1; mask(1,:)=1; mask(end,:)=1;

% Sort out really tiny things
mask = bwpropfilt(mask, 'Area', [500, 10^9]);

L = bwlabeln(mask);
Lboundary = L(1);
mask(L==Lboundary)=0;
[L, n] = bwlabeln(mask);

% Remove directly cells connected to the edge

%[Area, BoundingBox, Solidity] 
P = regionprops(L, 'Area', 'BoundingBox', 'Solidity', 'MajorAxisLength', 'MinorAxisLength');

for kk=1:size(P)
    P(kk).Aspect = P(kk).MajorAxisLength / P(kk).MinorAxisLength;
end

end
