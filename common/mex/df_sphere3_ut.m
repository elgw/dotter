function df_sphere3_ut()

disp('--> Testing df_sphere3')
% mex df_sphere3.c COPTIMFLAGS="-O3 -flto"

disp(' Symmetric output')
T = inf(3,3,3);
S = df_sphere3(T, [2,2,2]);
assert(isequal(squeeze(S(:,:,2)), squeeze(S(:,2,:))));
assert(isequal(squeeze(S(:,:,2)), squeeze(S(2,:,:))));

disp(' Correct cutoff')
T = inf(5,5,5);
S = df_sphere3(T, [3,3,3],1);
assert(isequal(squeeze(S(:,:,3)), squeeze(S(:,3,:))));
assert(isequal(squeeze(S(:,:,3)), squeeze(S(3,:,:))));
assert(isinf(S(1,1,1)));

disp('  Larger cutoff than image size')
T = inf(5,5,5);
S = df_sphere3(T, [3,3,3],10);
assert(isequal(squeeze(S(:,:,3)), squeeze(S(:,3,:))));
assert(isequal(squeeze(S(:,:,3)), squeeze(S(3,:,:))));

disp(' Location outside image')
T = inf(5,5,5);
S = df_sphere3(T, -[3,3,3],10);
assert(min(S(:))>=(3*4^2)^(1/2))

disp(' Correct location')
for kk = 1:100
    p = 10+randi(10, [3,1]);
    S = df_sphere3(inf(30,30,30), p);
    assert(S(p(1), p(2), p(3)) == 0);
end

disp('  Multiple points')
N = 11;
d = 10 + randi(50, [N, 3]);
T = inf([70,70,70]);
S = df_sphere3(T, d');
for kk = 1:size(d,1)
    assert(S(d(kk,1), d(kk,2), d(kk,3)) == 0)
end

% And since no radius limit, this should be finite everywhere
assert(sum(isfinite(S(:))) == numel(S))

end