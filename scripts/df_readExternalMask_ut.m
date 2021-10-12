function df_readExternalMask_ut()

tests = {@wrong_input, @TwoDInput, @zeroMask, @oneMissing, @oneMask};
nFail = 0;

for kk = 1:numel(tests)    
    try
        tests{kk}()
    catch e
        fprintf('Failed test: %s\n', func2str(tests{kk}));
        nFail = nFail + 1;
    end
    
end

if nFail>0
    error(sprintf('%d tests failed\n', nFail));
end

end


function wrong_input()
% should only read files

X = zeros(1024,1024,1);
try
    m = df_readExternalMask(X);
catch e
    return
end
error('Accepted a non-file as input');

end

function TwoDInput()
% should not accept 2d input
X = 2*2^16*rand(1024,1024,1)-1;
X = uint16(X);
fileName = [tempdir() '/temp.tif'];
df_writeTif(X, fileName);
try
    m = df_readExternalMask(fileName);
catch e
    error('Failed to read 2D mask')
end
return

end

function zeroMask()
% should produce empty output from zero-mask

X = zeros(1024,1024,11);
fileName = [tempdir() '/temp.tif'];
df_writeTif(uint16(X), fileName);
m = df_readExternalMask(fileName);
assert(max(m(:))==0);

end

function oneMask()
% should produce empty output from zero-mask

X = ones(1024,1024,11);
fileName = [tempdir() '/temp.tif'];
df_writeTif(uint16(X), fileName);
m = df_readExternalMask(fileName);
assert(max(m(:))==0);

end


function oneMissing()
% Set two nuclei with label 3 and 5
% should return label 1 and 2
X = zeros(1024,1024,11);
X(100:110, 100:110, :)  = 3;
X(200:210, 100:110, :)  = 5;
fileName = [tempdir() '/temp.tif'];
df_writeTif(uint16(X), fileName);
m = df_readExternalMask(fileName);
assert(max(m(:))==2);
assert(min(m(:))==0);
end
