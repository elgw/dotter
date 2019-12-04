% TMR channel partially missing in

folder = '/mnt/bicroserver2/microscopy_data_2/iFISH/iEG436_171125_003_calc/';

files = dir([folder '*.NM']);

D = load([folder files(1).name], '-mat');
M = D.M
