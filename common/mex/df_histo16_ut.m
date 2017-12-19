disp('--> Testing df_histo16')

disp('  no input')
error = false;
try 
    df_histo16();
catch e    
    %disp('  the expected error generated for no input')
    error = true;
end
assert(error)

disp('  wrong input type')
error = false;
try 
    df_histo16(double(1));
catch e    
    %disp('expected error generated for wrong type of input')
    error = true;
end
assert(error)

disp('  only zeros')
h = df_histo16(uint16([]));
assert(sum(h(:)) == 0);

t = 0:2^16-1;
t = uint16(t);

disp('  right size of output')
h = df_histo16(t);
assert(numel(h) == 2^16);
assert(sum(h(:)) == 2^16);
assert(min(h(:)) == 1);
assert(max(h(:)) == 1);

h = df_histo16(0*t);
assert(numel(h) == 2^16);
assert(sum(h(:)) == 2^16);
assert(h(1) == 2^16);

disp('  timing in a realistic case')
t = (2^16-1)*rand(1024,1024,60);
t = uint16(t);
tic
h = df_histo16(t);
tval = toc;
assert(sum(h(:)) == numel(t));
fprintf('  --> df_histo16 took %.3f s for a %dx%dx%d image\n', tval, size(t))

disp('  -- done');