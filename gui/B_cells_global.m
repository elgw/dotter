function B_cells_global(wfolder, varargin)

% Analyze global properties of a dataset/folder.
% To get parameterers for selectDots/NEditor ...

% Reads all files in a data set, uses nTrueDots to figure out
% where the threshold should be for true dots/background.

% Generates a pdf with some characteristics of the images that can be used
% for evaluation.


%% Settings

% Example:
% dapival = .75*10^10; % Will be asked for if not provided
% wfolder = '/Users/erikw/data/iJC63_160915_003_calc/'
% s.nTrueDots = []; % M.nTrueDots will not be overwritten

%dbstop if error

if nargin == 0 || ~ischar(wfolder)
    wfolder = uigetdir(pwd);
    if isa(wfolder, 'double')
        disp('No folder')
        return
    end
    wfolder = [wfolder '/'];
end


% Discard dots where the P(d in BG) < (1-s.thP)
% default value s.thP=0.99

if(~exist('s', 'var'))
    s.thP = 0.995;
    s.calculateFWHM=0;
    s.showSegmentation=1;
    s = B_settings(s);
end

if(~exist('s', 'var'))
    disp('No settings available');
    return
end
s.nTrueDots = [];


%% Initialization
files = dir([wfolder '*NM']);
if numel(files)==0
    fprintf('No files found in : %s\n', wfolder);
    return
end

if ~exist([wfolder 'analysis'], 'dir')
    mkdir([wfolder 'analysis'])
end


if 0
qstring = sprintf('Do you want to change any parameters?');
qans = questdlg(qstring,'Q', 'No (default)', 'Yes', 'No (default)');
if strcmp(qans, 'Yes')
    fprintf('consider s.nTrueDots\n');
    load([wfolder files(1).name], '-mat')
    fprintf('Meta data from first image loaded\n')
    fprintf('type dbcont when done or dbquit to abort execution of this script\n');
    %keyboard
end
end

if s.showSegmentation
    %keyboard
    for kk = 1:numel(files)
        
        load([wfolder files(kk).name], '-mat')
        Idapi = df_readTif(M.dapifile);
        Idapi = double(Idapi);
        Idapi = sum(Idapi, 3);
        V = Idapi-min(Idapi(:));
        V = V/max(Idapi(:));
        H = .2*ones(size(V));
        S = double(M.mask>0);
        imwrite(hsv2rgb(cat(3, H,S,V)), sprintf('%sanalysis/dapiseg_%d.png', wfolder, kk));
    end
end


%% Data set analysis: DAPI in all nuclei
% The goal is to find a threshold for nuclei being G1 or not, dapival

DS = []; DA = [];
for kk = 1:numel(files)
    numOkNuclei = 0;
    F = [];
    load([wfolder files(kk).name], '-mat')
    for ll = 1:numel(N)
        DS = [DS N{ll}.dapisum];
        DA = [DA N{ll}.area];
    end
end

dapifig = figure;
hist(DS, 90);
[kdapi, ddapi] = kdeParzen(DS, [], [], 2*10^8);
kdapi = kdapi/sum(kdapi);
%plot(ddapi, kdapi, 'k', 'LineWidth', 2)
ylabel('#')
xlabel('sum of DAPI')
hold on
ax = axis;

if ~exist('dapival', 'var')
    dapival = inputdlg('Enter dapival')
    dapival = str2num(dapival{1});
end

plot([dapival, dapival], [0, ax(4)], 'k--', 'LineWidth', 2);

print(dapifig, '-dpdf', [wfolder '/analysis/dapiSum.pdf'])
savefig(dapifig, [wfolder '/analysis/dapiSum.fig'])

%% Data set analysis: Signal strength at all signals
% according to DoG. This might not be the best measure since DoG is not
% directly proportional to the number of photons from the signal.

fish_dots = {[],[],[],[],[]}; other_dots = {[],[],[],[],[]};
for kk = 1:numel(files)
    numOkNuclei = 0;
    F = [];
    load([wfolder files(kk).name], '-mat')
    %keyboard
    if (numel(s.nTrueDots)>0) % Correct nTrueDots if s.nTrueDots supplied
        M.nTrueDots = s.nTrueDots;
    else
        s.nTrueDots = M.nTrueDots;
    end
    for cc = 1:numel(M.channels)  % For each channel
        c_true = []; c_other = [];
        for ll = 1:numel(N) % For each nuclei
            if N{ll}.dapisum < dapival
                % The order of each dot is appended to the table of dots
                n_true = min(M.nTrueDots(cc), size(N{ll}.dots{cc}, 1));
                c_true = [c_true;  N{ll}.dots{cc}(1:n_true, 1:4) (1:n_true)'];
                if n_true < size(N{ll}.dots{cc},1)
                    n_other = size(N{ll}.dots{cc},1) - n_true;
                    c_other = [c_other; N{ll}.dots{cc}(n_true+1:end, 1:4) (1:n_other)'];
                end
            end
        end
        fish_dots{cc} = [fish_dots{cc} ; c_true];
        other_dots{cc} = [other_dots{cc} ; c_other];
    end
end


%% Distributions for FISH vs background dots
for cc = 1:numel(M.channels)
    if M.nTrueDots(cc)>0
        f = figure;
        DOM = linspace(0,max(fish_dots{cc}(:,4)), 1024);
        [h1, binpos] = hist(fish_dots{cc}(:,4), DOM);
        h1 = h1./sum(h1);
        hold on
        h2 = hist(other_dots{cc}(:,4), DOM, 'Color', 'red');
        h2 = h2./sum(h2);
        bar(binpos, h1, 'EdgeColor', 'none', 'FaceColor', 'red')
        bar(binpos, h2, 'EdgeColor', 'none', 'FaceColor', 'green')
        ax = axis;
        ax(1) = 0; ax(2) = max(DOM);
        ax(4) = max([h1(1:end-1),h2(1:end-1)]);
        axis(ax)
        %set(gca, 'Xscale', 'log')
        %set(gca, 'yscale', 'log')
        legend({'FISH probes', 'background'})
        xlabel('Signal strength')
        %ylabel('Probability')
        title([wfolder ' : ' M.channels{cc}], 'interpreter', 'none');
        
        skde = (max(DOM)-min(DOM))/500;
        k1 = kdeParzen(fish_dots{cc}(:,4), [], DOM, skde, 'boundary', 'hard');
        k2 = kdeParzen(other_dots{cc}(:,4), [], DOM, skde, 'boundary', 'hard');
        plot(DOM, k1/sum(k1), 'red')
        plot(DOM, k2/sum(k2), 'green')
        
        k2nrm  = k2/sum(k2(:));
        k2int = cumsum(k2nrm);
        th = find(k2int>s.thP);
        th = th(1);
        th = interp1(DOM, th);
        thres(cc)= th;
        fprintf('Suggested threshold (99 percent): %f\n', thres(cc));
        
        %val = find(k1./(k1+k2)>.95);
        %val = val(1);
        
        plot([th, th], [0, ax(4)], 'k')
        
        
        print(f, '-dpdf', [wfolder 'analysis/c' num2str(cc) 'dots.pdf'])
        savefig(f, [wfolder 'analysis/c' num2str(cc) 'dots.fig'])
        
        
        f=figure
        plot(DOM, k1/max(k1(:)), 'red', 'LineWidth', 2)
        hold on
        plot(DOM, k2/max(k2(:)), 'green', 'LineWidth', 2)
        axis([0,max(DOM), 0,1])
        
        print(f, '-dpdf', [wfolder 'analysis/c' num2str(cc) 'dots1.pdf'])
        savefig(f, [wfolder 'analysis/c' num2str(cc) 'dots1.fig'])
    end
end

%% FWHM for FISH dots



if s.calculateFWHM
    FWHM = {[],[],[],[],[]};
    disp('Calculating FWHM for thresholded dots')
    disp('This will take som time since all dots are fitted')
    for kk = 1:numel(files)
        load([wfolder files(kk).name], '-mat')
        for cc = 1:numel(M.channels)  % For each channel
            iChannel = double(df_readTif(strrep(M.dapifile, M.dapichannel, M.channels{cc})));
            for ll = 1:numel(N) % For each nuclei
                if N{ll}.dapisum < dapival
                    % The order of each dot is appended to the table of dots
                    n_true = min(M.nTrueDots(cc), size(N{ll}.dots{cc}, 1));
                    c_true = N{ll}.dots{cc}(1:n_true, 1:4);
                    if size(c_true, 1)>0
                        F = dotFitting(iChannel, c_true);
                        FFWHM = df_fwhm(iChannel, F);
                        FFWHM = FFWHM(FFWHM>0);
                        FWHM{cc} = [FWHM{cc} ; FFWHM];
                    end
                end
            end
        end
    end


for cc=1:numel(M.channels)
    figure
    hist(130.08*FWHM{cc}, 100)
    title(['FWHM: ' M.channels{cc}])
    print('-dpng', [wfolder '/analysis/fwhm_' M.channels{cc} '.png']);
end
end

% Global SN, compare distribution of all FISH dots to all non-fish-dots
SN = [];
f = fopen([wfolder 'analysis/SN.txt'], 'w');
fprintff(f, 'SN: (mean(fish)-mean(other))/max(std(fish), std(other))\n\n');
for cc = 1:numel(M.channels)
    fprintff(f,'\n%s\n', strrep(M.channels{cc}, '_', ' '));
    
    dots = fish_dots{cc}; % Take the strongest dots per channel
    %dots = dots(dots(:,end)==kk, :); %?
    mfish = mean(dots(:,4));
    sfish = std(dots(:,4));
    fprintff(f,'m: %f std: %f\n', mfish, sfish);
    
    dots = other_dots{cc};
    dots = dots(dots(:,end)==1, :); %% Only consider the strongest non-fish dot
    nother = size(dots, 1);
    mother = mean(dots(:,4)); sother = std(dots(:,4));
    fprintff(f,'m: %f std: %f\n', mother, sother);
    if nother > 1
        SN(cc) = mfish/mother/max(sother, sfish);
    else
        SN(cc)=-1;
    end
    fprintff(f, 'S/N: %f \n', SN(cc));
end

fclose(f);

if 0
    snline = 1;
    for kk = 1:numel(files)
        load([wfolder files(kk).name], '-mat')
        for ll = 1:numel(N)
            for cc = 1:numel(M.channels)
                if size(N{ll}.dots{cc}, 1)>M.nTrueDots(cc)
                    fdots = N{ll}.dots{cc}(1:2,4);
                    SN(snline,:) = [kk,ll,cc, sn];
                end
            end
        end
    end
end

%% Append thresholds, dapival, etc to all nuclei

disp('Updating .NE files with dapival, thresholds and nTrueDots')
for kk = 1:numel(files)
    load([wfolder files(kk).name], '-mat')
    M.threshold = thres;
    M.dapival = dapival;
    M.thP = s.thP;
    M.nTrueDots = s.nTrueDots;
    % M.channels = {'a594', 'cy5', 'gfp'};
    save([wfolder files(kk).name], 'M', 'N', '-mat')
end

%% 
%% Dots per nuclei with a score higher than threshold
%%

% Histograms and also ouputs data to dotsPerNuclei.txt

dFile = fopen(sprintf('%sanalysis/dotsPerNuclei.txt', wfolder), 'w');
for cc = 1:numel(M.channels)
    fprintf(dFile, 'Channel: %s\nDots, #cells\n', M.channels{cc});
    
    nDots = [];
    for kk = 1:numel(files) % Per file
        load([wfolder files(kk).name], '-mat')
        for nn =  1:numel(N) % Per nuclei
            dots=[]; dotsnm=[];
            if N{nn}.dapisum < dapival
                nDots = [nDots; sum(N{nn}.dots{cc}(:,4)>M.threshold(cc))];
            end
        end
    end  
    
    for kk = 0:M.nTrueDots(cc)*3
        fprintff(dFile, '%3d, %3d\n', kk, sum(nDots==kk));
    end
    fprintf(dFile, '  >, %3d\n', sum(nDots>M.nTrueDots(cc)*3) );
    
    f=figure
    hist(nDots, 0:M.nTrueDots(cc)*3)
    title(sprintf('Channel: %s, mean: %f', M.channels{cc}, mean(nDots)));
    print('-dpdf', sprintf('%s/analysis/dotsPerNuclei%d.pdf', wfolder, cc));
    savefig(f, sprintf('%s/analysis/dotsPerNuclei%d.fig', wfolder, cc))
end
fclose(dFile);

%% Generate a PDF with the measurements

opwd = pwd();
generateROQ(wfolder) % Generate report of quality
cd([wfolder '/analysis'])
if ismac
!/usr/texbin/pdflatex roq.tex
!/usr/texbin/pdflatex roq.tex
!open roq.pdf
end
if isunix
!LD_LIBRARY_PATH=""   && /usr/bin/pdflatex roq.tex
!LD_LIBRARY_PATH=""   && /usr/bin/pdflatex roq.tex
!LD_LIBRARY_PATH=""   && evince roq.pdf
end
cd(opwd)

dbclear if error

end