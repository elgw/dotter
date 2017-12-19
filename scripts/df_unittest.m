function df_unittest()
% Test some of the components in DOTTER
%
% Run directly from terminal with:
%   matlab -nodesktop -nosplash -r "run('df_unittest.m')"

hasJava = usejava('jvm');

if ~hasJava
    disp('! Java is not available, will not use any graphical components')
    disp('')
end

disp('Running Self-tests for DOTTER. A few warnings are expected but no errors.')

tglobal = tic;

if hasJava
    disp('-> Open and close DOTTER main GUI')
    % should produce no errors
    DOTTER();
    h = findall(0,'tag','DOTTER');
    close(h);
end

disp('-> Write and read tif file');
I = zeros(1024, 1024+1, 41, 'uint16');
I(1:end) = mod(1:numel(I), (2^16-1)-3);
I(4,5,6) = 2^16;

filename = [tempdir() 'test.tif'];
tic
write_tif_volume(I, filename);
fprintf('Took %.2f s to write a normal sized tif file\n', toc);
tic
I2 = df_readTif(filename);
fprintf('Took %.2f s to load the tif file\n', toc);
assert(sum(I(:) == I2(:)) == numel(I));
assert(sum(size(I)==size(I2)) == 3);

clear filename I I2

disp('-> df_volumeSpheres')

disp('Float input')
S = [1, 1.1, 1.2, 1.4];
V = df_volumeSpheres(S);
assert(abs(V-1.4^3*4/3*pi)<0.1);

disp('One sphere');
S = [1,1,1,1];
V = df_volumeSpheres(S);
assert(abs(V-4/3*pi)<0.01);

S = [1,1,1,2];
V = df_volumeSpheres(S);
assert(abs(V-8*4/3*pi)<0.1);

disp('Two spheres');
S = [1,1,1,1; 1, 1, 1, 1];
V = df_volumeSpheres(S);
assert(abs(V-4/3*pi)<0.01);

S = [1,1,1,1; 1.5, 1.5, 1.5, 1];
V = df_volumeSpheres(S);
assert(V> 4/3*pi);
assert(V<8/3*pi);

disp('-> dotThreshold');

% Should not crash
th = dotThreshold(zeros(100,1));
th = dotThreshold(ones(100,1));
th = dotThreshold(rand(100,1));

%D = [randn(10000,1) ;4+randn(1000,1)];
%th = dotThreshold(D);
%assert(th>1)
%assert(th<4)

if hasJava
    disp('-> dotterSlide')
    % 2D image, non-square
    t = dotterSlide(rand(1000, 2000), [1024*rand(100,1) 2000*rand(100,1), rand(100,1), (1:100)']);
    close(t)
end

if hasJava
    % 3D image, no dots
    t = dotterSlide(rand(1024,1024,60), []);
    close(t)
end

disp('localization')
test = [getenv('DOTTER_PATH') 'localization/unitTests.m'];
disp(['-> Running: ' test]);
run(test)

disp('-> rnaSlide')

disp('-> dotCandidates')
s = dotCandidates('getDefaults', 'lambda', 600, 'voxelSize', [130,130,200]);
t = zeros(124,124,60);
t(14,15,16) = 1;
d = dotCandidates('image', t, 'settings', s);
assert(size(d,1)==1);
t(14,15,2) = 1;

disp('-> dotFitting')
tic
F = dotFitting(t, [14,15,16]);
assert(eudist(F(1,1:3), [14,15,16])<.5);
t = toc;
fprintf('  Took %f s\n', t);

failed = {};
unit_tests = [];
DOTTER_PATH = getenv('DOTTER_PATH');
folders = {'/common/', '/common/mex/', '/dotter/plugins/measurements/', '/dotter/scripts/', '/dotter/gui/'};
for kk = 1:numel(folders)
    folder = [DOTTER_PATH folders{kk}];
    addpath(folder);
    unit_tests = [unit_tests ; dir([folder '/*_ut.m'])];
end

for kk = 1:numel(unit_tests)
    fprintf(' >> TESTING: %s\n', unit_tests(kk).name);
    try
        run(unit_tests(kk).name)
    catch e
        failed{end+1} = unit_tests(kk).name;
    end
end

tval = toc(tglobal);

disp(' ')
fprintf('->> All tests run in %.1f seconds\n', tval);
disp(' ')

if numel(failed)>0
    fprintf('->> %d failed\n', numel(failed));
end
for kk = 1:numel(failed)
    fprintf('%02d: %s\n', kk,failed{kk});
end

fprintf('\n');

end