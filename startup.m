% Add paths where there are scripts used by DOTTER

fprintf('DOTTER ');

codedir = fileparts(mfilename('fullpath'));
codedir = [codedir '/'];
setenv('DOTTER_PATH', codedir);

addpath(codedir);
addpath([codedir 'plugins/clustering'])
addpath([codedir 'addons/bfmatlab/'])
addpath([codedir 'addons/structdlg/'])
addpath([codedir 'common/'])
addpath([codedir 'common/mex/'])
addpath([codedir 'common/localization/'])
addpath([codedir 'scripts/'])
addpath([codedir 'gui/'])
addpath([codedir 'common/cluster3e/'])
addpath([codedir 'common/cCorr/'])
%addpath([codedir 'csvScripts/'])
addpath([codedir 'common/piccs/'])
addpath([codedir 'common/volBucket/'])

fprintf('version %s initialized.\n', df_version());