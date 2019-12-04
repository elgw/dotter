function D_integralIntensity(folder, csvFileOut)
%% function D_integralIntensity(folder, csvFileOut)
% Purpose: Calculate the integral intensity
% of nuclei in a dataset (_calc folder)
%
% Input: A _calc folder
%
% Output: A CSV file with properties per nuclei
%
% Example 1:
%  >> D_integralIntensity() 
%  % Will ask for a _calc folder (input)
%  % and eventually also ask for an output file
%
% Example 2:
% >> D_integralIntensity('/images/iEW_001_calc', ...
% '~/Desktop/iEW_001_nuclei.csv');
% >> T = readtable('~/Desktop/iEW_001_nuclei.csv')
% T = 
%      Field         Nuclei         Area          DAPI   
%    __________    __________    __________    __________ ... 
%    5.0000e+00    1.0000e+00    1.0104e+04    3.0959e+09 
%   ...

% 2017-08-21
% This function overlaps getDapiFromFolders.m in functionality consider
% joining them

msgbox(help('D_integralIntensity'))

if ~exist('folder', 'var')
    folder = uigetdir();
    fprintf('Picked: %s\n', folder);
end

if folder == 0
    disp('No folder selected')
    return
end

files = dir([folder '/*.NM']);

if numel(files) == 0
    disp(['No .NM files in ' folder])
    return
end
fprintf('Found %d files\n', numel(files));

%% Per nuclei

II = []; % Intensity, Intensity
mm = 1;
offset = 0;
for kk =1:numel(files)
    [meta] = load([folder '/' files(kk).name], '-mat');
    M = meta.M;
    N = meta.N;
    
    % List all image files to load
    vFiles = {M.dapifile};
    for ll = 1:numel(M.channels)
        vFile = strrep(M.dapifile, 'dapi', M.channels{ll});
        vFiles = {vFiles{:} vFile};
    end
    
    % Calculate integral intensity in each channel
    % and for all nuclei
    for nn = 1:numel(N)
        II(nn+offset, 1) = kk;
        II(nn+offset, 2) = nn;
        II(nn+offset, 3) = N{nn}.area;
    end
    
    for cc = 1:numel(vFiles)
        iChan = df_readTif(vFiles{cc});
        iChan = sum(double(iChan), 3);
        
        for nn = 1:numel(N)
            nuc = iChan(M.mask==nn);
            II(nn+offset, 3*(cc-1)+4) = sum(nuc(:));
            II(nn+offset, 3*(cc-1)+5) = mean(nuc(:));
            II(nn+offset, 3*(cc-1)+6) = std(nuc(:));
        end
    end        
    
    offset = offset+nn;
end

channels = {'DAPI', M.channels{:}};
dstrings = {};
for kk = 1:numel(channels)
    dstrings = {dstrings{:}, ['sum_' channels{kk}], ['mean_' channels{kk}], ['std_' channels{kk}]};
end


%% Export to table
varNames = {'Field', 'Nuclei', 'Area', dstrings{:}};
t = array2table(II);
t.Properties.VariableNames = varNames;

if exist('csvFileOut', 'var')
    writetable(t, csvFileOut);
else
    
[fileName, pathName] = uiputfile({'*.csv', 'CSV file'});

if isequal(fileName,0) || isequal(pathName,0)
    disp('No file name');
    return  
else
    writetable(t, [pathName filesep() fileName]);
end
end
return 

%% Per pixel
pInt = {[],[],[],[],[],[],[],[]};
mm = 1;
offset = 0;
for kk =1:numel(files)
    load([folder '/' files(kk).name], '-mat');
    
    vFiles = {M.dapifile, M.channelf{:}};
    for cc = 1:numel(vFiles)
        iChan = df_readTif(vFiles{cc});
        iChan = sum(double(iChan), 3);
        iChan = iChan(M.mask == 1);
        pInt{cc} = [pInt{cc}; iChan(:)];
    end
end

% End of data extraction



%plot(II(:,1), II(:,2), 'o')
hold all

%figure
%[y,x] = kdeParzen(pInt{2}./pInt{1}, [], [0,2], []);
%hold all
%plot(x,y)
%legend({'DMSO', 'ETOP', 'NCS', 'NEG'})
% xlabel('Staining/DAPI'), ylabel('Density')
%figure
%plot(pInt{1}, pInt{2}, 'o')
%title(folder(end-20:end), 'Interpreter', 'none')

% csvwrite('../perNuclei_NEG.csv', II);

pause
%% Per pixel
% Prepared for Reza and Nicola 3 Dec 2015
%pIntHU = pInt;
%pIntPBS = pInt;
figure
plot(pIntPBS{1}, pIntPBS{2}, 'o')
hold all
plot(pIntHU{1}, pIntHU{2}, 'x')
legend({'PBS', 'HU'})
xlabel('DAPI')
ylabel('Al 647')
title('H3')
%save('U2OS.mat')

PBS = pIntPBS{1}./pIntPBS{2};
HU = pIntHU{1}./pIntHU{2};

[y1,x] = kdeParzen(PBS, [], [0,60], 0.15);
[y2,x] = kdeParzen(HU, [], [0,60], 0.15);

figure
plot(x,y1, 'lineWidth', 2)
hold all
plot(x,y2, 'lineWidth', 2)
legend({'PBS', 'HU'})
xlabel('per pixel: Al 647 / DAPI')
ylabel('density')
%save h3.mat

%% Per nuclei
% Prepared for Reza and Nicola 3 Dec 2015
figure
plot(ETOP(:,1), ETOP(:,2), 'o')
hold all
plot(DMSO(:,1), DMSO(:,2), 'x')
legend({'ETOP', 'DMSO'})
xlabel('DAPI')
ylabel('Al 647')
title('U2OS')
%save('U2OS.mat')
DMSO(:,3) = DMSO(:,2)./DMSO(:,1);
ETOP(:,3) = ETOP(:,2)./ETOP(:,1);

[y1,x] = kdeParzen(ETOP(:,3), [], [0,1.5], 0.01);
[y2,x] = kdeParzen(DMSO(:,3), [], [0,1.5], 0.01);

figure
plot(x,y1, 'lineWidth', 2)
hold all
plot(x,y2, 'lineWidth', 2)
legend({'ETOP', 'DMSO'})
xlabel('per cell: Al 647 / DAPI')
ylabel('density')

end