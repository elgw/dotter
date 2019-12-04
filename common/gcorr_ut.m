function gcorr_ut()
disp('  Correct location of maxima')
t1 = zeros(100,100,100);
t1(41,42,43) = 1;
t1c = gcorr(t1, [1,1,1]);
t1c(41,42,43);
assert(t1c(41,42,43)==max(t1c(:)));

disp('  Invariant to constant addition')
t2 = t1+100;
t2c = gcorr(t2, [1,1,1]);
t2c(41,42,43);
assert(abs(t1c(41,42,43)-t2c(41,42,43))<0.0001);

disp('  Linearity')
t3 = t1*100;
t3c = gcorr(t3, [1,1,1]);
t3c(41,42,43);
assert(abs(100*t1c(41,42,43)-t3c(41,42,43))<0.0001);

% On slope? Or remove slopes first?

end