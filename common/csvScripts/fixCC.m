% This script tries to 

fprintf('Trying to apply CC-correction for .csv files %s\n', pwd)

ccfile = dir('cc_*.mat');

if numel(ccfile)==1
    sprintf('Using %s for cc', ccfile(1).name);
else
    error('Please make sure that there is only one cc_*.mat file in the directory');
end

refChannel = 'cy5';

fprintf('Using %s as reference channel %s\n', refChannel);

%load(ccfile(1).name);

nmfiles = dir('*.NM');

for nmf = 1:numel(nmfiles)
    fprintf('Loading %s\n', nmfiles(nmf).name);
    
    load(nmfiles(nmf).name, '-mat');
    
    csvfiles = dir( ['File_' nmfiles(nmf).name(1:3) '*.csv'] );
    
    fprintf('Found %d csv files\n', numel(csvfiles));
    
    for ncsv = 1:numel(csvfiles)
        fprintf('  Loading %s \n', csvfiles(ncsv).name);
    
    T =  readtable(csvfiles(ncsv).name);
    T = table2cell(T);
    
    for kk = 1:size(T,1)
        fromChan = T{kk,4};
        if isnumeric(fromChan)
            fromChan = M.channels(fromChan);
            T{kk,4} = fromChan;
        end
        
        C=cCorrI(cell2mat(T(kk,8:10)), fromChan, refChannel, ccfile(1).name);
        T(kk,5) = {C(1)}; T(kk,6) = {C(2)};  T(kk,7) = {C(3)};
    end
    writetable(T, csvfiles(ncsv).name);
    
    end
end
