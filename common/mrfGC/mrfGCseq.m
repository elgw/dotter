function [S]=mrfGCseq(V, C1, C2, beta, thickness, overlap)
% Performs segmentation of V -> S using mrfGC with the parameters
% from C1, C2 and beta.
%
% In this version, the volume is processed in many steps,
% It divides dimension 3 into subinteervals with a certain
% thickness so that they have a specific overlap
%
%
% Possible improvements: process cubes instead.

assert(isa(V, 'uint8')); %mrfGC is a little picky
assert(isa(beta, 'double'));
% Avoid out of memory crashes
whos
assert(size(V,1)*size(V,2)*(thickness + 2*overlap) < 800*300*150);
                                                                   
disp('Allocating memory for output');
S=uint8(zeros(size(V)));

froms=1:thickness:size(V,3)-round(thickness/2); % Start points

tos=froms+thickness; % End points are thickness away from start points
tos=min(tos, size(V,3)); % Do not continue outside the volume

disp('Starting main loop');
for k=1:numel(froms) % For each of the starting positions
  
  from=max(1, froms(k)-overlap); % First slice in V
  startOverlap=froms(k)-from; % Overlap before first slice of interest                              
  to=min(tos(k)+overlap, size(V,3)); % last slice in V
  endOverlap=to-tos(k); % Amount of overlap after the last slice of interest
  
  v=V(:,:,from:to); % Take out a portion of V  
  s=mrfGC(v,C1,C2,beta); % Segment
  
  % Insert into the volume to be returned
  S(:,:,froms(k):tos(k))=s(:,:,startOverlap+1:end-endOverlap);   
end % End of main loop

disp('Done segmenting')
end % end of function


function []=test(~)

V=uint8(20*randn(3,4,79));
S=mrfGCseq(V, [0,10], [20,10], 1, 3, 10);

end
