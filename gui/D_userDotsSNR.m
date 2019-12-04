function D_userDotsSNR(folder, csvFileOut)
%% function D_integralIntensity(folder, csvFileOut)
% Purpose: Calculate the singal to noise ratio for each nuclei
% in each cell over all channels.
%
% Input: A _calc folder with userDots. There has to be userDots
%
% Method:
%  For each nuclei and channel, interpolates the pixel values at 
%  a) all userDots and 
%  b) all other locations.
%  SN is defined as (mean(a)-mean(b))/std(b)
%
%  To avoid the problems having a 2D mask and 3D objects, the image-data is
%  max-projected in Z before extracting the values for b.
%
% Output: 
%  A CSV file with properties per nuclei
%
%  If the channels are dapi, a594, cy5, gfp, tmr, ...
%  The table will look like:
%
%    Field    Nuclei    Area     a594      cy5       gfp       tmr
%    4        13        2472    39.035    24.343    10.053    23.347
%   ...
%

if ~exist('folder', 'var')
    folder = uigetdir();
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
fprintf('-> Found %d NM files\n', numel(files));

fprintf('-> Calculating SNR\n');
disp('')
%% Per nuclei
II = []; % Intensity, Intensity
offset = 0;
for fieldNo =1:numel(files)
    progressbar(fieldNo, numel(files));
    %
    [meta] = load([folder '/' files(fieldNo).name], '-mat');
    M = meta.M; N = meta.N;
    
    % List all image files to load
    vFiles = {};
    for cc = 1:numel(M.channels)
        vFile = strrep(M.dapifile, 'dapi', M.channels{cc});
        vFiles = {vFiles{:} vFile};
    end
    
    
    % Calculate the mean and standard deviation
    % in each nuclei for each channel
    % 1: For all userDots m_d
    % 2: for the image, m_i, s_i
    % 3: SN = (m_d-m_i)/s_i
    abort = 0;
    if numel(N)>0
        if ~isfield(N{1}, 'userDots')
            fprintf('No userDots in %s\n', files(fieldNo).name);
            fprintf('Aborting SN calculations\n');
            abort = 1;
        end
    end
    
    if abort
        break
    end
    
    for nn = 1:numel(N)
        II(nn+offset, 1) = fieldNo;
        II(nn+offset, 2) = nn;
        II(nn+offset, 3) = N{nn}.area;
        II(nn+offset, 4) = N{nn}.dapisum;
    end
    
    for cc = 1:numel(vFiles) % Outer loop over channels to avoid re-loading tif files
        iChan = double(df_readTif(vFiles{cc}));
        for nn = 1:numel(N)
            dots = N{nn}.userDots{cc};
            if numel(dots)>0
                m_d = interpn(iChan, dots(:,1), dots(:,2), dots(:,3)); %% XXX index exceeds matrix dimensions
                m_d = mean(m_d);
                iChan_mp = max(iChan,3);
                
                nmask = M.mask==nn; % TODO: 3D?
                nmask(sub2ind(size(nmask),dots(:,1), dots(:,2))) = 0;
                m_i = mean(iChan_mp(nmask(:)));
                s_i = std(iChan_mp(nmask(:)));
                II(nn+offset, cc+4) = (m_d-m_i)/s_i;
            else
                II(nn+offset, cc+4) = nan;
            end
        end
    end
    offset = offset+nn;
end

if numel(II) == 0
    disp('No userDots in any field')
    return
end

%% Export to table

for kk = 1:numel(M.channels)
    chanDesc{kk} = ['SNR_' M.channels{kk}]; % column descriptions per channel
end

varNames = {'Field', 'Nuclei', 'Area', 'DAPI', chanDesc{:}};
t = array2table(II);
t.Properties.VariableNames = varNames;

disp(t)

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
