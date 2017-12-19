function R = populateClusters(CPoints, dots, dnm, NPerChannel, resolution)

maxPointsPerChannel = 20; %NE.nDotsShow

for cc = 1:numel(dots) % For each channel
P = dots{cc}; % Assumes that the dots are ordered by strength
Q = [];
for kk = 1:min(maxPointsPerChannel, size(P,1)); % For the first dots in that channel
   p = P(kk,1:3);      
   for ll = 1:size(CPoints,1) % Compare to all the cluster points     
       if norm((p-CPoints(ll,1:3)).*resolution)< dnm;           
           Q = [Q;p];
           break % only add a point once
       end       
   end
end 
% To do: Weight dots by distance and value if more than the expected number
% of dots were found.

% Save only the expected number of dots.
fprintf('Found %d dots in channel %d\n', size(Q,1), cc);
R{cc} = Q(1:min(size(Q,1), NPerChannel(cc)), :);
end

end