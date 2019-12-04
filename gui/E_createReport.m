%% Prepares a .tex file with a "report" of all nuclei and dots from a folder


folder = '/Users/erikw/data/310715_iMB2_calc/export2/';
outfolder = [folder 'report/'];
disp(['Creating a summary.tex in ' outfolder])

nrows = 2;
ncols = 4;

try
    mkdir(outfolder)
end

texfilename = [outfolder 'summary.tex'];
texfile = fopen(texfilename, 'w+');

fprintf(texfile, '\\documentclass[landscape, a4paper]{article}\n \\usepackage{graphicx} \n \\usepackage[margin=.5cm]{geometry}\n \\usepackage{subfig} \n \\begin{document}');

files = dir([folder '*_mip.png']);
fileEndings = {'_dapi.png', '_mip.png',  '_xz.png', '_yz.png', ...
               '_dapi.png', '_cdots.png', '_cdotsxz.png', '_cdotsyz.png'};

for kk=1:numel(files)
basename = files(kk).name(1:end-8);
fileNumber = str2num(basename(1:4));
cellNumber = str2num(basename(6:9));
channel = str2num(basename(11));

fprintf(texfile, '\\begin{figure}\n');
fprintf(texfile, '\\centering\n');
for ll = 1:numel(fileEndings)
    imname = [basename fileEndings{ll}];
    fprintf(texfile, ...
        '\\subfloat[]{\\includegraphics[width=%f\\textwidth, height=%f\\textheight, keepaspectratio]{../%s}}\n', ...
        .95/ncols, .75/nrows, imname);
    if mod(ll,ncols)~=0 && ll<numel(fileEndings)
        fprintf(texfile, '\\hfill');
    end
    if mod(ll,ncols)==0 && ll<numel(fileEndings)
        fprintf(texfile, '\\\\');
    end
end
logname = [basename '_log.txt'];
switch channel
    case 1
        cname = 'a594';
    case 2
        cname = 'tmr';
    case 3
        cname = 'cy5';
    otherwise
        cname = 'unknown';
end

        
fprintf(texfile, '\\caption{File: %d, cell: %d: channel: %d %s a) DAPI (MIP), e) DAPI (MIP), b/f) XZ, c/g) XZ, d/h) YZ. \\protect\\input{../%s}}\n', ...
    fileNumber, cellNumber, channel, cname, logname);

fprintf(texfile, '\\end{figure}\n\n');
fprintf(texfile, '\\clearpage');
end
    
fprintf(texfile, '\\end{document}');
fclose(texfile);