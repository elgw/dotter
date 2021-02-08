function T = df_exportDots(varargin)
%df_exportDots export dots from DOTTER
%
% Export dots from a set of NM files
% The script will ask for NM files to include in the analyis
% and finally ask where to save the data when the extraction is done.
%
%  Output protocol
%  ---------------
%  T has the following columns:
%  'File', 'Channel', 'Nuclei', 'x', 'y', 'z', 'Value','FWHM', 'Label'
%  - File is the full file name of the nm file that contained the dots
%  - Channel is the channel name. This always corresponds to a prefix of the
%    tif file names, i.e., if there is a594_001.tif, a594 could be the
%    channel name
%  - x, y, z: the x, y, and z coordinate, possibly after shift correction
%  towards DAPI
%  - Value, is the strengt of the dot, and could be generated with DoG, or
%  some other filter.
%  - FWHM: the full width half max of the dot, if calculated
%  - Label: If dot is clustered, says which cluster it belongs to.
%  - SNR calculated by df_snr.m and is defined by:
%      SNR = (signal-background)/noise
%    background and noise is estimated from a circle around each point,
%    the radius of the circle is hard coded to 5
% - NSNR is calculated by df_nsnr.m and is defined as:
%    NSNR = intensity/bg
%   where intensity is the value of the image at the dot and bg is
%   the median value of the nuclei. Uses the max projection. Uses the
%   dilated mask (if available).
%
%  Continue with your favorite table processing tool, like awk!
%  See headers
%  awk -F ',' 'BEGIN {print "\033[4m$", "Name\033[0m";} NR==1 {for (kk=1; kk<=NF; kk++) print kk, $kk}' DotsData.csv
%
%  Select dots above 20000
%  awk -F ',' '$7>20000 {print}' DotsData.csv
%  ...
%
%  'UserDots' export user dots, not all dots
%  'fwhm'     calculate fwhm if not already calculated
%
%  Examples
%  --------
%       T = df_exportDots('fwhm');
%       dfwhm = cell2mat(T(:,8));
%       fprintf('fwhm calculated for %d/%d dots.\n', numel(dfwhm)-sum(dfwhm<0), numel(dfwhm));
%       dfwhmf = dfwhm(dfwhm>0); % filter out dots with no fwhm info
%       histogram(dfwhmf)
%
%  Notes
%  -----
%  - Only exports dots from G1 nuclei (dapisum < dapiTh)
%
%   See also DF_EXPORTDOTS_UI

% 2017-08-21
% Asking to calculate FWHM in a dialog.
% Asks for a filename initially and not after the length calculations.
%
% 2017-03-27
% Created
%
% 2017-11-03
% Added support for cc files (corrections for shifts and chromatic
% aberrations)

% The script will either extract UserDots or all dots (M.dots)
s.extractUserDots = 0;
s.calcFWHM = -1;
s.maxDots = -1; % If positive, restrict the number of dots
s.fitting = 'none';
s.centroids = 0; % If 1, replace clusters with their centroid
s.calcSNR = -1;
s.calcNSNR = -1;

T = [];
files = [];
ccFile = '';

for kk = 1:numel(varargin)
    if strcmpi(varargin{kk}, 'exportUserDots')
        s.extractUserDots = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'centroids')
        s.centroids = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'fwhm')
        s.calcFWHM = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'snr')
        s.calcSNR = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'nsnr')
        s.calcNSNR = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'maxDots')
        s.maxDots = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'files')
        files = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'ccFile')
        ccFile = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'outFile')
        outFile = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'nucleiSelection')
        s.nucleiSelection = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'fitting')
        s.fitting = varargin{kk+1};
    end
end

if strcmpi(s.fitting, 'centre of mass')
    s.fitting = 'com3w';
end

if strcmpi(s.fitting, 'ML+gaussian')
    s.fitting = 'dotFitting';
end

disp(s)

if numel(files) == 0
    folder = df_getConfig('df_exportDots', 'folder', pwd);
    files = uipickfiles('FilterSpec', folder, 'Prompt', 'Select NM files', 'REFilter', '.NM$');
    if isnumeric(files)
        disp('No NM files selected')
        return
    end
    
    % Set the default folder to look in next time
    df_setConfig('df_exportDots', 'folder', fileparts(files{1}))
end

%% Get cc-data

if exist('ccFile', 'var')
    if numel(ccFile)>0
        s.ccData = load(ccFile, '-mat');
    end
end

fprintf('%d Files: \n', numel(files));
fprintf('%s ... \n', files{1});

if s.calcFWHM < 0 % if not set;
    a = questdlg('Calculate FWHM from at the dot locations in the images? That will take a lot of time','FWHM', 'Yes', 'No', 'No');
    if strcmpi(a, 'Yes')
        s.calcFWHM = 1;
    else
        s.calcFWHM = 0;
    end
end

if ~exist('outFile', 'var')
    if extractUserDots
        sugFile = 'UserDots.csv';
    else
        sugFile = 'AllDots.csv';
    end
    [A, B] = uiputfile(sugFile);
    if isnumeric(A)
        disp('Aborting')
        return
    end
    outFile = [B, A];
end


% If the input seems ok, show settings
s.logFileName = [tempdir() 'df_exportDots.txt'];
s.logFile = fopen(s.logFileName, 'w');

fprintf(s.logFile, '\n SETTINGS\n');
fprintf(s.logFile, ' calcFWHM: %d\n', s.calcFWHM);
fprintf(s.logFile, ' calcSNR: %d\n', s.calcSNR);
fprintf(s.logFile, ' UserDots: %d\n', s.extractUserDots);
fprintf(s.logFile, ' Centroids: %d\n', s.centroids);
fprintf(s.logFile, ' maxDots: %d\n', s.maxDots);
fprintf(s.logFile, ' nucleiSelection: %d\n', s.nucleiSelection);
fprintf(s.logFile, '\nCC FILE:\n %s\n', ccFile);
fprintf(s.logFile, '\nOUPUT FILE:\n %s\n', outFile);
fprintf(s.logFile, '\nINPUT FILES:\n');
for(kk = 1:numel(files))
    fprintf(s.logFile, ' %d : %s\n', kk, files{kk});
end

fprintf(s.logFile, '\nLOG\n');
T = [];

w = waitbar(0, 'Extracting data');
for kk = 1:numel(files)
    waitbar(kk/(1.1*numel(files)), w);
    fprintf(s.logFile, '\n-> %s\n', files{kk});
    
    file = files{kk};
    
    [M,N] = df_nm_load(file);
    M = M{1};
    
    assert(isfield(M, 'mask'));
                
    % For each channel
    for cc = 1:numel(M.channels)
        cname = M.channels(cc);
        imFileName = strrep(M.dapifile, 'dapi', cname);
        imFileName = imFileName{1};
        
        if s.calcFWHM || ~strcmpi(s.fitting, 'none') || s.calcSNR
            imFile = double(df_readTif(imFileName));
            assert(numel(imFile)>0);
        else
            imFile = [];
        end
        
        if s.extractUserDots
            TFC = extractUserDotsForChannel(s, cc, M, N, imFile);
            if s.centroids
                % Group together the dots in TFC on their cluster label and
                % replace them by their centroids
                TFC = replaceByCentroids(TFC);
            end
        else
            TFC = extractAllDotsForChannel(s, cc, M, N, imFile);            
        end        
        
        % file, cname, nuclei, TFC
        %keyboard
        C = mat2cell(TFC, ones(1, size(TFC,1)), ones(1, size(TFC,2)));
        C = [repmat({file}, size(C,1),1) repmat(cname, size(C,1),1) C];
        
        if numel(T)==0
            T = C;
        else
            T = [T;C];
        end
    end
    
end

disp('data extraction done ...')
whos T

if numel(T) == 0
    close(w);
    warndlg('Nothing to export! No userDots?')
    return
end

Table = cell2table(T);
Table.Properties.VariableNames = {'File', 'Channel', 'Nuclei', 'x', 'y', 'z', 'Value','FWHM', 'SNR', 'NSNR', 'Label'};

%keyboard

if ischar(outFile)
    fprintf('Writing to disk: %s\n', outFile);
    % Expect that writetable as a whimsical behaviour and sometimes rounds all values
    % in certain columns.
    % writetable(Table, outFile);
    df_writeTable(Table, outFile);
    disp('Done writing data.');
    disp('Time to awk?')
else
    disp('No file name give, not writing to disk.')
    return
end


fprintf(s.logFile, '\nEXTRACTION DONE\n\n');

fprintf(s.logFile, 'Output table: %d x %d\n\n', size(T,1), size(T,2));

fprintf(s.logFile, 'Columns:\n');
for kk = 1:numel(Table.Properties.VariableNames)
    fprintf(s.logFile, ' %d : %s\n', kk, Table.Properties.VariableNames{kk});
end

close(w);

fclose(s.logFile);
web(s.logFileName);
end

function TFC = replaceByCentroids(T)
% dots(x,y,z,intensity), dfwhm, label

TFC = [];
if numel(T) ==0
    return
end

nuclei = unique(T(:,1));

for nn = 1:numel(nuclei)
    nuc = nuclei(nn);
    TN = T(T(:,1) == nuc, :);
    
    
    labels = unique(TN(:, end));
    
    for ll = 1:numel(labels)
        L = labels(ll);
        if(L>0) % Only label 1, 2, ...
            TL = TN(TN(:,end) == L, :);
            
            for dd = 2:6
                TL(1,dd) = mean(TL(:,dd));
            end
            
            TFC = [TFC; TL(1,:)];
        end
    end
end
end

function TFC = extractUserDotsForChannel(s, cc, M, N, imFile)
% Take the dots from N{nn}.userDots{cc}
TFC = [];
nucNum = [];

for nn = 1:numel(N)
    fprintf(s.logFile, 'Nuclei %d, channel %d\n',nn, cc);
    hasDots = 0;
    dapiOk = 1;
    if isfield(N{nn}, 'userDots')
        if numel(N{nn}.userDots{cc})>3
            hasDots = 1;
        else
            fprintf(s.logFile, ' - No dots.\n');
        end
    else
        fprintf(s.logFile, ' - userDots not selected\n');
    end
    
    if s.nucleiSelection == 1 % All
        dapiOk = 1;
    end
    
    if s.nucleiSelection == 2 % G1
        if isfield(M, 'dapiTh')
            if N{nn}.dapisum > M.dapiTh
                fprintf(s.logFile, 'Nuclei %d excluded based on DAPI\n', nn);
                dapiOk = 0;
            end
        else
            warning('No DAPI threshold for this field');
        end
    end
    
    if s.nucleiSelection == 3 % > G1
        if isfield(M, 'dapiTh')
            if N{nn}.dapisum < M.dapiTh
                fprintf(s.logFile, 'Nuclei %d excluded based on DAPI\n', nn);
                dapiOk = 0;
            end
        else
            warning('No DAPI threshold for this field');
        end
    end
    
    if hasDots && dapiOk
        dots = N{nn}.userDots{cc};
        if size(dots, 2)>4
            dots = dots(:,1:4);
        end
        % Handle missing intensity values by setting to zero
        if size(dots,2)==3
            dots = [dots, zeros(size(dots,1),1)];
        end
        
        if s.calcFWHM
            %if nn == 47 
            %    if cc == 6
            %        keyboard
            %    end
            %end  
            fprintf(s.logFile, ' + Calculating FWHM\n');
            dfwhm = df_fwhm(imFile, dots(:,1:3));
        else
            dfwhm = -2*ones(size(dots,1), 1);
        end
        
        if s.calcSNR            
            fprintf(s.logFile, ' + Calculating SNR\n');
            dsnr = df_snr(imFile, dots(:,1:3));            
        else
            dsnr = -2*ones(size(dots,1), 1);
        end
        
        if s.calcNSNR            
            fprintf(s.logFile, ' + Calculating NSNR\n');            
            dnsnr = df_nsnr(M, N, imFile, dots(:,1:3), cc);
        else
            dnsnr = -2*ones(size(dots,1), 1);
        end
        
        if strcmpi(s.fitting, 'com3w')
            fprintf(s.logFile, ' + Fitting with com3w\n');
            dots(:,1:3) = df_com3(imFile, dots(:,1:3)', 1)';
        end
        
        if strcmpi(s.fitting, 'dotFitting')
            fprintf(s.logFile, ' + Fitting with dotFitting\n');
            dotFittingSettings = dotFitting();
            lambda = df_getEmission(M.channels{cc});
            dotFittingSettings.sigmaXY = 1.2*lambda/M.voxelSize(1);
            dotFittingSettings.sigmaZ = 1.2*lambda/M.voxelSize(3);
            dotFittingSettings.sigmaXY = df_getEmission(M.channels{cc});
            F=dotFitting(imFile, dots(:,1:3), dotFittingSettings);
            dots(:,1:3) = F(:,1:3);
        end
        
        %% Apply cc-correction
        if isfield(s, 'ccData')
            fprintf(s.logFile, ' + Applying cc\n');
            dots(:,1:3) = ...
                df_cc_apply_dots('dots', dots(:,1:3), ...
                'from', M.channels{cc}, ... % From
                'to', 'dapi', ... % To
                'ccData', s.ccData);
        end
        
        TFC = [TFC; dots, dfwhm, dsnr, dnsnr, N{nn}.userDotsLabels{cc}(:)];
        nucNum = [nucNum; nn*ones(size(dots,1),1)];
    end
end
% At last, combine
TFC = [nucNum, TFC];
end


function TFC = extractAllDotsForChannel(s, cc, M, N, imFile)
% Take the dots from M.dots{cc}
TFC = M.dots{cc}(:, 1:4);

if s.maxDots > 0
    TFC = TFC(1:min(s.maxDots, size(TFC,1)), :);
end

if s.calcFWHM
    dfwhm = df_fwhm(imFile, TFC(:,1:3));
else
    dfwhm = -2*ones(size(TFC,1),1);
end

if s.calcSNR    
    dsnr = df_snr(imFile, TFC(:,1:3));
else
    dsnr = -2*ones(size(TFC,1), 1);
end

if s.calcNSNR    
    fprintf(s.logFile, ' + Calculating NSNR\n');
    dnsnr = df_nsnr(M, N, imFile, TFC(:,1:3), cc);
else
    dnsnr = -2*ones(size(TFC,1), 1);
end

if strcmpi(s.fitting, 'com3w')
    fprintf(s.logFile, ' + Fitting with com3\n');
    TFC(:,1:3) = df_com3(imFile, TFC(:,1:3)', 1)';
end

if strcmpi(s.fitting, 'dotFitting')
    fprintf(s.logFile, ' + Fitting with dotFitting\n');
    dotFittingSettings = dotFitting();
    lambda = df_getEmission(M.channels{cc});
    dotFittingSettings.sigmaXY = 1.2*lambda/M.voxelSize(1);
    dotFittingSettings.sigmaZ = 1.2*lambda/M.voxelSize(3);
    dotFittingSettings.sigmaXY = df_getEmission(M.channels{cc});
    F=dotFitting(imFile, TFC(:,1:3), dotFittingSettings);
    TFC(:,1:3) = F(:,1:3);
end

TFC = [TFC, dfwhm, dsnr, dnsnr, zeros(size(TFC,1),1)];
[~, nucNum] = associate_dots_to_nuclei(N, M.mask, TFC, cc);
TFC = [nucNum, TFC];
end
