% Add paths where there are scripts used by DOTTER

disp('Initializing dotter ...');

codedir = fileparts(mfilename('fullpath'));
codedir = [codedir '/'];
setenv('DOTTER_PATH', codedir);

addpath(codedir);
addpath([codedir 'dotter/plugins/clustering'])
addpath([codedir 'dotter/addons/bfmatlab/'])
addpath([codedir 'common/'])
addpath([codedir 'common/mex/'])
addpath([codedir 'localization/'])
addpath([codedir 'deconv/'])
addpath([codedir 'dotter/'])
addpath([codedir 'dotter/scripts/'])
addpath([codedir 'dotter/gui/'])
addpath([codedir 'cluster3e/'])
addpath([codedir 'cCorr/'])
addpath([codedir 'csvScripts/'])
addpath([codedir 'NEditor/'])
addpath([codedir 'piccs/'])
addpath([codedir 'volBucket/'])
