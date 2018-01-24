function dotCandidates_ut()

disp('-> dotCandidates')
s = dotCandidates('getDefaults', 'lambda', 600, 'voxelSize', [130,130,200]);
t = zeros(124,124,60);
t(14,15,16) = 1;
d = dotCandidates('image', t, 'settings', s);
assert(size(d,1)==1);
t(14,15,2) = 1;


end