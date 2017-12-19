function A_cells_generate_dot_curves(folder)
%% function A_cells_generate_segmentation_preview(folder)
%
% For .NM file in <folder>, show dots per nuclei over the range of possible
% thresholds save plots in <folder>
%
% 2017-05-04

if ~exist('folder', 'var')
    disp('No folder specified, using current folder');
    folder = pwd();
end

if folder(end)~='/'
    folder = [folder '/'];
end

if ~exist(folder, 'dir')
    warning('Folder does not exist, doing nothing.');
    return
end

fprintf('Loading nuclei from %s\n', folder);
nuclei = df_getNucleiFromNM('folder', folder);

files = dir([folder '*.NM']);
t = load([folder files(1).name], '-mat');
channels = t.M.channels;
clear t;


if numel(nuclei) == 0
    warning('No nuclei found!');
    return
end

nchannels = numel(nuclei{1}.dots);
nnuclei = numel(nuclei);

fprintf('%d nuclei in %d channels\n', nnuclei, nchannels);
for cc = 1:nchannels
    dots = [];
    for kk = 1:numel(nuclei)
        dots = [dots; nuclei{kk}.dots{cc}];
    end
    plotDotCurve(folder, dots, nnuclei, channels{cc});
end


fprintf('Done!\n');

end

function plotDotCurve(folder, dots, nnuclei, channel)
f = figure();
value = dots(:,4);
value = sort(value);
p=semilogy(value, (numel(value):-1:1)/nnuclei);
grid on
xlabel('Threshold');
ylabel('Dots per nuclei');
legend({['Cha: ' channel 10 '# nuc: ' num2str(nnuclei)]});
outImName = [folder channel '_dpn.png'];
outFigName = [folder channel '_dpn.fig'];
savefig(f, outFigName);
print(f, outImName, '-dpng');
close(f);
end