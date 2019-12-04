folders = uipickfiles;

files = dir([folders{1} '/*.pdf']);

mkdir('beamer')

outfile = fopen('beamer/beamer.tex', 'w');

fprintf(outfile, '\\documentclass{beamer}\n');
fprintf(outfile, '\\usepackage{graphicx}\n');
fprintf(outfile, '\\begin{document}\n');

for kk = 1:numel(files)
    pairs = strsplit(files(kk).name, '_');
    
    fprintf(outfile, '\\begin{frame}[fragile]\n');
    fprintf(outfile, '\\frametitle{%s %s}', pairs{2}, pairs{3});
    fprintf(outfile, '\\begin{columns}\n');
    
    for ff=1:numel(folders)
        fprintf(outfile, '\\begin{column}{.33\\textwidth}\n');
        imfile = [folders{ff} '/' files(kk).name];
        if exist(imfile, 'file')
            fprintf(outfile, '\\includegraphics[width=\\textwidth]');
            fprintf(outfile, '{{%s/%s}.pdf}\n', folders{ff}, files(kk).name(1:end-4));
        end
        sfolder = strsplit(folders{ff}, '/');
        sfolder = sfolder{end};
        fprintf(outfile, '\n\\verb+%s+\n', sfolder);
        fprintf(outfile, '\\end{column}\n\n');
    end
    fprintf(outfile, '\\end{columns}\n');
    fprintf(outfile, '\\end{frame}\n');
end

fprintf(outfile, '\\end{document}\n');
fclose(outfile);
