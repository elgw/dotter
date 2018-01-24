function df_unittest()
% Test some of the components in DOTTER
%
% Run directly from terminal with:
%   matlab -nodesktop -nosplash -r "run('df_unittest.m')"

disp('Running Self-tests for DOTTER. A few warnings are expected but no errors.')

tglobal = tic;

failed = {};
unit_tests = [];
DOTTER_PATH = getenv('DOTTER_PATH');
folders = {'/common/', ...
    '/common/mex/',...
    '/common/localization/', ...
    '/plugins/measurements/',...
    '/plugins/clustering/',...
    '/scripts/',...
    '/gui/'};

for kk = 1:numel(folders)
    folder = [DOTTER_PATH folders{kk}];
    addpath(folder);
    unit_tests = [unit_tests ; dir([folder '/*_ut.m'])];
end

w = waitbar(0, 'Testing');
for kk = 1:numel(unit_tests)
    fprintf(' >> TESTING: %s\n', unit_tests(kk).name);
    waitbar((kk-1)/numel(unit_tests), w);
    try
        assert(isnumeric(nargin(unit_tests(kk).name)))
        run(unit_tests(kk).name)
    catch e
        disp(e)
        failed{end+1} = unit_tests(kk).name;
    end
end
close(w);

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