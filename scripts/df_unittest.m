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

% Remove '.m' at the end
for kk = 1:numel(unit_tests)
    unit_tests(kk).name = unit_tests(kk).name(1:end-2);
end

w = waitbar(0, 'Testing');

% Make sure that no extra figures are opened
drawnow();
h =  findobj('type','figure');
nFigs = length(h);

for kk = 1:numel(unit_tests)
    fprintf(' >> TESTING: %s\n', unit_tests(kk).name);
    waitbar((kk-1)/numel(unit_tests), w);
    try       
        assert(isnumeric(nargin(unit_tests(kk).name)))
        run(unit_tests(kk).name)
        drawnow();
        h =  findobj('type','figure');
        assert(length(h) == nFigs);
    catch e
        disp(e)
        failed{end+1} = unit_tests(kk).name;
        h =  findobj('type','figure');
        nFigs = length(h);
    end
end
close(w);

tval = toc(tglobal);


if numel(failed)>0
    fprintf('->> %d failed\n', numel(failed));
end
for kk = 1:numel(failed)
    fprintf('%02d: %s\n', kk,failed{kk});
end

fprintf('\n');


disp(' ')
fprintf('->> All tests run in %.1f seconds %d/%d passed\n', tval, numel(unit_tests)-numel(failed), numel(unit_tests));
disp(' ')
end