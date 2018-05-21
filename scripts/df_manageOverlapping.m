function df_manageOverlapping()
%% Find dots that overlap from different channels


%% TODO: apply cc-correction, either by
% - df_getNucleiFromNM.m, or
% - extending df_nm_load.m (yes!)
% - adding it here (not DRY!)

%% TODO: have a way to see what dots were removed
% - export to separate calc folder?

%% Options

s.radius = 200; % nm
s.apply_UserDots = 1;
s.apply_MetaDots = 1;
s.save = 0;
s.showReport = 1;
s.ccFile = '';
s.hasCCfile = 0;
s.plot = 0;

%% Read NM files

folder = df_getConfig('manageOverlap', 'folder', '~/');
s.folder = uigetdir(folder);
if isnumeric(s.folder)
    error('No folder given');
    return
end
df_setConfig('manageOverlap', 'folder', s.folder);


files = dir([folder filesep() '*.NM']);
fprintf('Found %d files\n', numel(files));

ccFile = dir([folder filesep() '*.cc']);
if numel(ccFile) == 0
    s.ccFile = 'NOT FOUND';
else
    s.ccFile = [folder filesep() ccFile(1).name];
    s.hasCCfile = 1;
end


%% Open GUI
s = StructDlg(s);
if isequal(s, [])
    error('Don''t know how to proceed');
    return
end

apply(folder, files, s);

end

function apply(folder, files, s)
if s.showReport
    tic;
    s.logFileName = [tempdir() 'df_manageOverlapping.txt'];
    s.logFile = fopen(s.logFileName, 'w');
    
    fprintf(s.logFile, 'Log from df_manageOverlap, %s\n\n', datestr(date(), 'YYYY-mm-DD'));
    
    fprintf(s.logFile, 'Folder: %s\n', folder);
    fprintf(s.logFile, 'Radius: %d nm\n\n', s.radius);
    fprintf(s.logFile, 'cc-file: %s\n', s.ccFile);
end

for kk = 1:numel(files)
    fprintf(s.logFile, '\n ----> File: %d/%d: %s\n', kk, numel(files), files(kk).name);
    applyToFile([folder filesep() files(kk).name], s);
end

if s.showReport
    fprintf(s.logFile, '\n\nTook %d s\n', toc);
    fclose(s.logFile);
    web(s.logFileName, '-browser');
end

end

function applyToFile(file, s)

style = {'ro', 'bv', 'gx', 'cs', 'm+', 'k<'};

if s.apply_MetaDots
    if s.showReport
        fprintf(s.logFile, '\n--> Applying to all dots in meta data\n');
    end
    
    if s.hasCCfile
        [M, N] = df_nm_load(file, 'cc', s.ccFile);
    else
        [M, N] = df_nm_load(file);
    end
    
    M = M{1};
    % Grab all dots
    D = [];
    for kk = 1:numel(M.channels)
        D = [D; M.dots{kk} kk*ones(size(M.dots{kk}))];
    end
    % Rescale them
    if isfield(M, 'pixelSize')
        pixelSize = M.pixelSize;
    else
        fprintf(s.logFile, 'WARNING: No pixel size set in the metadata, assuming [130,130,300]\n');
        pixelSize = [130,130,300];
    end
    D = df_rescale_dots(D, pixelSize);
    
    
    
    if s.plot
        
        figure,
        s1 = subplot(1,2,1);
        hold on
        for kk = 1:numel(M.channels)
            plot3(D(D(:,end)==kk,2), ...
                D(D(:,end)==kk,1), ...
                D(D(:,end)==kk,3), style{kk});
        end
        title('All dots, before removal')
        view(2)
        axis image
        grid on
        legend
    end
    
    % Find close ones
    X = df_nn(D', s.radius);
    
    % Put them back
    for kk = 1:numel(M.channels)
        XC = X(D(:,end) == kk);
        M.dots{kk} = M.dots{kk}(XC==0, :);
        if s.showReport
            fprintf(s.logFile, '  %s removed %d/%d dots\n', M.channels{kk}, sum(XC), numel(XC));
        end
    end
    
    if s.plot
        
        D=D(X==0, :);
        
        s2 = subplot(1,2,2);
        hold on
        for kk = 1:numel(M.channels)
            plot3(D(D(:,end)==kk,2), ...
                D(D(:,end)==kk,1), ...
                D(D(:,end)==kk,3), style{kk});
        end
        title('All dots, after removal')
        view(2)
        axis image
        grid on
        legend
        linkaxes([s1, s2]);
    end
    
    % And save
    if s.save
        df_nm_save(M, NN, file);
    end
end

if s.apply_UserDots
    if s.showReport
        fprintf(s.logFile, '\n--> Applying to all UserDots\n');
    end
    
    if s.hasCCfile
        [M, NN] = df_nm_load(file, 'ccFile', s.ccFile);
    else
        [M, NN] = df_nm_load(file);
    end
    
    if s.showReport
        fprintf(s.logFile, 'File: %s\n', file);
    end
    
    if isfield(M, 'pixelSize')
        pixelSize = M.pixelSize;
    else
        fprintf(s.logFile, 'WARNING: No pixel size set in the metadata, assuming [130,130,300]\n');
        pixelSize = [130,130,300];
    end
    
    M = M{1};
    % Only compare against the other user dots and not all the possible
    % dots
    
    % More to take care of, i.e., userDotsLabels
    
    if s.plot
        
        figure,
        s1 = subplot(1,2,1);
        hold on
        for nn = 1:numel(NN)
            D = NN{nn}.userDots;
            for kk = 1:numel(M.channels)
                plot3(D{kk}(:,2), ...
                    D{kk}(:,1), ...
                    D{kk}(:,3), style{kk});
            end
        end
        title('All dots, before removal')
        view(2)
        axis image
        grid on
        contour(M.mask, [.5,.5], 'Color', 'black')
        
    end
    
    
    for nn = 1:numel(NN)
        if s.showReport
            fprintf(s.logFile, ' Nuclei %d\n', nn);
        end
        % Take out nuclei
        N = NN{nn};
        
        % Take out dots
        D = [];
        for kk = 1:numel(N.userDots)
            D = [D; N.userDots{kk} kk*ones(size(N.userDots{kk},1), 1)];
        end
        
        D = df_rescale_dots(D, pixelSize);
        
        X = df_nn(D', s.radius);
        for kk = 1:numel(N.userDots)
            XC = X(D(:,end)==kk);
            
            N.userDots{kk} = N.userDots{kk}(XC==0, :);
            N.userDotsLabels{kk} = N.userDotsLabels{kk}(XC==0, :);
            
            if s.showReport
                fprintf(s.logFile, '  %s, removed %d/%d dots\n', M.channels{kk}, sum(XC), numel(XC));
            end
            
        end
        
        % Put it back
        NN{nn} = N;
    end
    
    if s.plot        
        s2 = subplot(1,2,2);
        hold on
        for nn = 1:numel(NN)
            D = NN{nn}.userDots;
            for kk = 1:numel(M.channels)
                plot3(D{kk}(:,2), ...
                    D{kk}(:,1), ...
                    D{kk}(:,3), style{kk});
            end
        end
        title('All dots, after removal')
        view(2)
        axis image
        grid on
        contour(M.mask, [.5,.5], 'Color', 'black')
        linkaxes([s1,s2], 'xy');
    end
    
    % Save to disk
    if s.save
        df_nm_save(M, NN, file);
    end
end

end