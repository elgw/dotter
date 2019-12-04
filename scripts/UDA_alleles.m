function [] = UDA_alleles(folder)
%% function [] = UDA_alleles(folder)
%  export alleles from nuclei that has userDots
%
%  Optionally the dots are corrected for chromatic aberrations
%  by displacing the dots based on a callibration measurement based on
%  beads.
%
%  The dots can also be fitted with sub pixel precision.
%
%  Explanation of columns in the output file:
%
%    File    XYZ for input file to XYZ.NM
%    Nuclei  number of the nuclei in the nuclei mask, M.mask
%    Allele  1 or 2, from setUserDotsDNA
%    Channel 1, 2, ..., k, ... where k corresponds to M.channels{k}
%    x       pixel locations
%    y       ...
%    z       ...
%    Fx      Fitted pixel locations (=x if no fitting)
%    Fy      ...
%    Fz      ...
%    FCx     Fx corrected for chromatic aberrations (=Fx if not used)
%    FCy
%    FCz
%
%   Last updated 2016-01-24

[N, channels] = UDA_get_nuclei(folder);

if numel(N) == 0
    disp('No nuclei')
    return
else
    fprintf('%d channels, %d nuclei\n', numel(channels), numel(N));
end

% Read only parameters
p.channels = channels;
p.nNuclei = numel(N);
p.inputFolder = folder;

% Settings
s.fitting = 1; % settings
s.ccFile = ''; % chromatic aberrations
s.outFile = '~/Desktop/out.csv'; % where to write the output data
s.nDPA = ones(1, numel(channels)); % number of dpts per allele
s.delta = 0;

% Open the GUI to read settings
s = UDA_get_alleles_gui(s, p);

if numel(s) == 0
    disp('Got no settings, leaving');
    return
end


%% Extract
disp('Extracting data');

% Per Field/File
%   See if any nuclei match the search
%     Per Channel
%       Fitting
%       CC
%     Per nuclei
%       Extract data

%% Calculate

fittingSettings = dotFitting(); % get the default dot fitting settings
files = dir([folder filesep() '*.NM']);
fout = fopen(s.outFile, 'w');
fprintf(fout, '%s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s, %s\n', ...
    'File', ...
    'Nuclei', ...
    'Allele', ...
    'Channel', ...,
    'x', ...
    'y', ...
    'z', ...
    'Fx', ...
    'Fy', ...
    'Fz', ...
    'FCx', ...
    'FCy', ...
    'FCz');
nAlleles = 0;
for ff = 1:numel(files) % File
    T = load([folder filesep() files(ff).name], '-mat');
    
    for cc = 1:numel(T.M.channels) % Channel
        if s.fitting
            IC = df_readTif(strrep(T.M.dapifile, 'dapi', T.M.channels{cc}));
        end
        
        for kk = 1:numel(T.N)
            % Nuclei
            if isfield(T.N{kk}, 'userDots')
                P = T.N{kk}.userDots{cc};
            else
                P = [];
            end
            if numel(P)>0
                P = P(:,1:3);
                if s.fitting
                    PF = dotFitting(IC, P, fittingSettings);
                else
                    PF = P;
                end
                if s.cc
                    PFCC = cCorrP(PF, T.M.channels{1}, T.M.channels{2}, s.ccFile);
                else
                    PFCC = PF;
                end
                T.N{kk}.userDotsFitted{cc} = PF;
                T.N{kk}.userDotsFittedCC{cc} = PFCC;
            else
                T.N{kk}.userDotsFitted{cc} = [];
                T.N{kk}.userDotsFittedCC{cc} = [];
            end
        end                        
    end
    nAlleles = nAlleles + exportToFile(s, T, fout, kk);    
end

fclose(fout);

fprintf('Done, exported %d alleles\n', nAlleles);

end

function nok = exportToFile(s, T, fout, fileNo)
% Export (For field and channel)
% 
% Input:
%  T: A structure with all the nuclei to export stored in T.N
%  s: some settings, s.delta, max difference in number of dots vs s.nDPA
%  fout desriptor of open text file where output is directed
%  fileNo: the value of "file" in the output table
%
% Output:
%  nok: number of exported alleles
%

nok = 0;

for nn=1:numel(T.N) % each nuclei
    N = T.N{nn};
    
    if isfield(N, 'userDots')
       
        for aa = 1:2 % allele
            
            delta = 0*s.nDPA;
            
            for cc = 1:numel(T.M.channels)
                A = N.userDots{cc};
                P = A(N.userDotsLabels{cc}==aa, :);
                delta(cc) = delta(cc) + abs(s.nDPA(cc) - size(P,1));
            end
            
            delta = sum(delta);
            
            fprintf('Nuclei %d, Allele %d,  delta: %d\n', nn, aa, delta);
            
            if delta <= s.delta
                nok = nok+1;
                % something to export
                for cc = 1:numel(T.M.channels)
                    if isfield(N, 'userDots')
                        A = N.userDots{cc};
                        P = A(N.userDotsLabels{cc}==aa, :);
                    else
                        P = [];
                    end
                    
                    %keyboard
                    if isfield(N, 'userDotsFitted')
                        PF = N.userDotsFitted{cc};
                        PF = PF(N.userDotsLabels{cc}==aa, :);
                    else
                        PF = nan*P;
                    end
                    
                    if isfield(N, 'userDotsFittedCC')
                        PFC = N.userDotsFittedCC{cc};
                        PFC = PFC(N.userDotsLabels{cc}==aa, :);
                    else
                        PFC = nan*P;
                    end
                    
                    dbstop if error
                    
                    for pp = 1:size(P,1)
                        fprintf(fout, '%d, %d, %d, %d, %f, %f, %f, %f, %f, %f, %f, %f, %f\n', ...
                            fileNo, ...
                            nn, ...
                            aa, ...
                            cc, ...,
                            P(pp,1), ...
                            P(pp,2), ...
                            P(pp,3), ...
                            PF(pp,1), ...
                            PF(pp,2), ...
                            PF(pp,3), ...
                            PFC(pp,1), ...
                            PFC(pp,2), ...
                            PFC(pp,3));
                    end
                    
                    dbclear all
                    
                end
            end
        end
    end
end
end





