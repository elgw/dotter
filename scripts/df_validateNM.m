function okFiles = df_validateNM(folder, files)
% function okFiles = df_validateNM(folder, files)
%
% Purpose:
%  See that NM files look all right, i.e. detect abnormalities
%
% To do:
%  IF ERRORS, open log
%  - Fix interface
%  - Progressbar

s.folder = folder;



ok = 1;
missingFiles = 0;
missingDots = 0;

okFiles = zeros(numel(files),1);

logFileName = [tempdir() 'df_validateNM.log'];
logFile = fopen(logFileName, 'w');

fprintf(logFile, 'Validating Files with df_validateNM... \n');

for kk = 1:numel(files)
    fileOk = 1;
    maskError = 0;
    filename = [s.folder files(kk).name];
    F = load(filename, '-MAT');
    
    %% See if the TIF files are available, otherwise suggest a
    % relocation
    if ~exist(F.M.dapifile, 'file')
        fprintf(logFile, 'Can not find: %s\n', F.M.dapifile);
        ok = 0;
        missingFiles = 1;
        fileOk = 0;
    end
    
    M = F.M;
    N = F.N;
    
    if numel(N) == 0
        fprintf(logFile, 'No nuclei!\n')
        fileOk = 0;
    end
    
    
    if ~isfield(M, 'dots')
        fprintf(logFile, 'No dots in %s.\n', files(kk).name);
        missingDots =1;
        fileOk = 0;
    else
        
        for nn = 1:numel(N)
            %% See if mask and bbx'es point to the same regions
            bbx = N{nn}.bbx;
            mid = [mean(bbx(1:2)), mean(bbx(3:4))];
            mid = round(mid);
            if numel(size(M.mask))==2
                if M.mask(mid(1), mid(2)) ~= nn
                    fprintf(logFile, '%s Nuclei %d, centre of bbx marked %d\n', filename, nn, M.mask(mid(1), mid(2)));
                    maskError = 1;
                    ok = 1;
                end
            end
            
            %% See if the userDots fall into the bbx
            
        end
        
    end
    
    if maskError
        ok = 0;
        fprintf(logFile, 'Warning, strange mask for %s\n', filename);
    end
    
    okFiles(kk) = fileOk;
end

if ~ok
    warn = fprintf(logFile, 'Validation errors:\n\n');
    if missingFiles
        fprintf(logFile, ' - TIF files could not be found, misc->relocate?\n');
    end
    if missingDots
        fprintf(logFile, ' - Dots missing in NM files, cells->Find nuclei...?\n');
    end
    if maskError
        fprintf(logFile, ' - Problems with the mask, misc->fixMasks?\n');
    end
end

fclose(logFile);

if ~ok
    a = questdlg('There were some errors or warnings, do you want to see then?', 'Problems identified');
    if numel(a)>0
        if strcmp(a, 'Yes')
            web(logFileName);
        end
    end
end

end