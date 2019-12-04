function df_unittest(varargin)
% Test some of the components in DOTTER
%
% It grabs all files ending with '_ut.m' in the standard
% directories and runs them.
% A few warnings are expected but no errors.
%
% Run directly from terminal with:
%   matlab -nodesktop -nosplash -r "run('df_unittest.m')"
%
% This can also be applied to any folder, then call by
% df_unittest('/some/folder_a', '/some/folder/b')
%
% i.e., to run unit tests in the current folder, simply type
% df_unittest .

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

if(numel(varargin)==1)
    folders = varargin;
    for kk = 1:numel(folders)
        folder = folders{kk};
        addpath(folder);
        unit_tests = [unit_tests ; dir([folder '/*_ut.m'])];
    end
else
    for kk = 1:numel(folders)
        folder = [DOTTER_PATH folders{kk}];
        addpath(folder);
        unit_tests = [unit_tests ; dir([folder '/*_ut.m'])];
    end
end


% Remove '.m' at the end
for kk = 1:numel(unit_tests)
    unit_tests(kk).name = unit_tests(kk).name(1:end-2);
end

if numel(unit_tests) == 0
    fprintf('Nothing to test\n');
    return;
end

w = waitbar(0, 'Testing');

% Make sure that no extra figures are opened
drawnow(); % Finnish drawing anything
h =  findobj('type','figure');
nFigs = length(h);

for kk = 1:numel(unit_tests)
    fprintf(' >> TESTING: %s\n', unit_tests(kk).name);
    waitbar((kk-1)/numel(unit_tests), w);
    try
        
        if ~isnumeric(nargin(unit_tests(kk).name))
            error('Test code is not a function')
        end
        
        funName = unit_tests(kk).name(1:end-3);       
        
        type = exist(funName);
        if type == 2                       
            help_string = help(funName);
            if(numel(help_string) == 0)
                error('Empty help string')
            end
        end
        run(unit_tests(kk).name)
        
        drawnow();
        h =  findobj('type','figure');
        if length(h) ~= nFigs
            error('Figure created')
        end
        
    catch e
        disp(e)        
        failed{end+1} = [unit_tests(kk).name ' ' e.message];
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