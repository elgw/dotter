function dotFitting_ut()

disp('-> dotFitting')
tic
F = dotFitting(t, [14,15,16]);
assert(eudist(F(1,1:3), [14,15,16])<.5);
t = toc;
fprintf('  Took %f s\n', t);

end