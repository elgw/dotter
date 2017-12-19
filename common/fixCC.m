% This script tries to do a CC correction on data in csv-files in the
% current folder.
%
% You have to put a cc_ file in the current folder. The ref-channel
% is set manually below.
%

fprintf('Trying to apply CC-correction for .csv files %s\n', pwd)

ccfile = dir('cc_*.mat');

if numel(ccfile)==1
    sprintf('Using %s for cc', ccfile(1).name);
else
    error('Please make sure that there is only one cc_*.mat file in the directory');
end

refChannel = 'cy5';

fprintf('Using %s as reference channel %s\n\n', refChannel);

%load(ccfile(1).name);

nmfiles = dir('*.NM');


csvfiles = dir('*.csv');

fprintf('Found %d csv files\n', numel(csvfiles));

for ncsv = 1:numel(csvfiles)
    fprintf('  Loading %s \n', csvfiles(ncsv).name);
    
    T =  readtable(csvfiles(ncsv).name, 'Delimiter', ',');
    T0 = T;
    T = table2cell(T);
    
    if(T{1,5}==-1)
            
    for kk = 1:size(T,1)
        fromChan = T{kk,4};
        if isnumeric(fromChan)
            fromChan = M.channels{fromChan};
            T{kk,4} = fromChan;
        end
        
        C=cCorrI(cell2mat(T(kk,8:10)), fromChan, refChannel, ccfile(1).name);
        T(kk,5) = {C(1)}; T(kk,6) = {C(2)};  T(kk,7) = {C(3)};
    end
    
    T=cell2table(T);
    T.Properties.VariableNames = T0.Properties.VariableNames;
    
    writetable(T, csvfiles(ncsv).name, 'Delimiter', ',');
    else
        disp('Already CCed, not doing anyting for this file')
    end
end

fprintf('Done, corrected dots in %d files\n', numel(csvfiles));