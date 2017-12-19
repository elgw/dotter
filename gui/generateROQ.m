function generateROQ(folder)
%% function generateROQ(folder)
% Prepares a .tex file with a "report" of all nuclei and dots from a folder
% Input
%  folder, folder with NE files

% To do:
% Use a table for the info on the first page,

if nargin<1
    folder = uigetdir();
end

if(~strcmp(folder(end), '/'))
    folder = [folder '/'];
end
    
files = dir([folder '*.NM']);
nfiles = numel(files);

Meta = load([folder files(1).name], '-mat');

nnuclei = 0;
for kk = 1:numel(files)
    load([folder files(kk).name], '-mat');
    nnuclei = nnuclei + numel(N);
end

texfilename = [folder 'analysis/roq.tex'];
fprintf('Creating %s\n', texfilename);

texfile = fopen(texfilename, 'w+');

% Headers
fprintf(texfile, '\\documentclass[landscape, a4paper]{article}\n');
% Packages
fprintf(texfile, '\\usepackage[section]{placeins}\n\\usepackage{graphicx} \n \\usepackage[margin=.5cm]{geometry}\n \\usepackage{subfig} \n \\usepackage{verbatim}\n \\usepackage{hyperref}\n\n');

fprintf(texfile, '\\begin{document}');

% Title
fprintf(texfile, '\\title{%s}\\maketitle\n', strrep(folder, '_', '\_'));

fprintf(texfile, '\\tableofcontents\n\n');

% Info
fprintf(texfile, '\\newpage\n');
fprintf(texfile, '\\section{General info}\n');
fprintf(texfile, '\\begin{tabular}{rl}\n');
fprintf(texfile, '\\hline\n');
fprintf(texfile, 'Number of files: & %d\\\\', nfiles);
fprintf(texfile, 'Image Size: & %dx%dx%d\\\\', Meta.M.imageSize);
fprintf(texfile, 'Number of nuclei: & %d\\\\', nnuclei);
fprintf(texfile, 'Dapi threshold: & %f\\\\', Meta.M.dapival);
fprintf(texfile, '\\end{tabular}\n');

fprintf(texfile, '\\begin{tabular}{clcc}\n');
fprintf(texfile, 'Channel: & Name: & nDots: & Threshold: \\\\');
fprintf(texfile, '\\hline\n');
for kk=1:numel(Meta.M.channels)
    fprintf(texfile, ' %d: & %s & %d & %f\\\\', kk, latexString(Meta.M.channels{kk}), Meta.M.nTrueDots(kk), Meta.M.threshold(kk));
end
fprintf(texfile, '\\end{tabular}\n');

fprintf(texfile, '\\verbatiminput{SN.txt}\n');


%% Segmentation
fprintf(texfile, '\\section{DAPI segmentation}\n');
files = dir([folder 'analysis/dapiseg*.png']);
for kk = 1:numel(files)
fprintf(texfile, '\\begin{figure}\n');
fprintf(texfile, '\\centering\n');
fprintf(texfile, '\\includegraphics[width=%f\\textwidth, height=%f\\textheight, keepaspectratio]{%s}\n', ...
        .99, .99, files(kk).name);
    fprintf(texfile, '\\caption{dapi\\_%03d}\n', kk);
fprintf(texfile, '\\end{figure}\n');
end


%% DAPI threshold
fprintf(texfile, '\\section{DAPI threshold}\n');
fprintf(texfile, '\\begin{figure}\n');
fprintf(texfile, '\\centering\n');
fprintf(texfile, '\\includegraphics[width=%f\\textwidth, height=%f\\textheight, keepaspectratio]{dapiSum.pdf}\n', ...
        .99, .99);
fprintf(texfile, '\\end{figure}\n');

%% FISH dots vs background dots
fprintf(texfile, '\\section{Dots}\n');
% C1
for kk = 1:numel(Meta.M.channels)
fprintf(texfile, '\\begin{figure}\n');
fprintf(texfile, '\\centering\n');
fprintf(texfile, '\\includegraphics[width=%f\\textwidth, height=%f\\textheight, keepaspectratio]{c%ddots.pdf}\n', ...
        .99, .99, kk);
fprintf(texfile, '\\end{figure}\n');
end

%% FISH dots vs background dots - normalized
% C1
for kk = 1:numel(Meta.M.channels)
fprintf(texfile, '\\begin{figure}\n');
fprintf(texfile, '\\centering\n');
fprintf(texfile, '\\includegraphics[width=%f\\textwidth, height=%f\\textheight, keepaspectratio]{c%ddots1.pdf}\n', ...
        .99, .99, kk);
fprintf(texfile, '\\end{figure}\n');
end

%% Dots per Nuclei
fprintf(texfile, '\\section{Dots per nucleus}\n');
for kk = 1:numel(Meta.M.channels)
fprintf(texfile, '\\begin{figure}\n');
fprintf(texfile, '\\centering\n');
fprintf(texfile, '\\includegraphics[width=%f\\textwidth, height=%f\\textheight, keepaspectratio]{dotsPerNuclei%d.pdf}\n', ...
        .99, .99, kk);
fprintf(texfile, '\\end{figure}\n');
fprintf(texfile, '\\verbatiminput{dotsPerNuclei.txt}\n');
end

%% FWHM
fprintf(texfile, '\\section{FWHM}\n');
files = dir([folder 'analysis/fwhm*.png']);
for kk = 1:numel(files)
fprintf(texfile, '\\begin{figure}\n');
fprintf(texfile, '\\centering\n');
fprintf(texfile, '\\includegraphics[width=%f\\textwidth, height=%f\\textheight, keepaspectratio]{%s}\n', ...
        .99, .99, files(kk).name);
fprintf(texfile, '\\end{figure}\n');
end

fprintf(texfile, '\\end{document}');
fclose(texfile);
end

function s= latexString(t)
    s = strrep(t, '_', '\_');
end
