function B_cells_view_rna(filename)
% Purpose: present data colleced with B_analyze for DNA fish

load(filename);
[outFolder, ~, ~] = fileparts(filename);
outFolder = [outFolder filesep];

fig = figure('Name', 'Dots per region');
P = get(fig, 'Position');
P(3:4) = [1000, 600];
set(fig, 'Position', P);

log_fd = fopen([outFolder 'summary.txt'], 'w');

for kk = 1:size(Hall,1) % channel 
    for ll = 1:size(Hall,2) % mask
        subplot(size(Hall,1), size(Hall,2), (kk-1)*size(Hall, 2) + ll);        
        H = Hall{kk,ll};
        bar(0:numel(H)-1, H)        
        title(sprintf('%s mask: %s', channelNames{kk}, maskNames{ll}), 'interpreter', 'none');
        nDots = sum( H(:)'.*(0:numel(H)-1));
        nObj = sum(H(:));
        avg = nDots/nObj;        
        last = find(H>0);
        last= last(end);
        ax = axis();
        ax(1) = -.5;
        ax(2) = last-.5;
        axis(ax)
        hold on
        plot([avg, avg], [ax(3) ax(4)], 'r')
        legend({sprintf('%d dots', nDots), ...
            sprintf('avg: %.1f dpo', avg)});        
        fprintff(log_fd, 'Channel: %s, mask: %s\n', channelNames{kk}, maskNames{ll});
        fprintff(log_fd, ' # objects: %d\n', nObj);
        fprintff(log_fd, ' # dots: %d\n', nDots);
        fprintff(log_fd, ' dots/object: %f\n', nDots/nObj);
    end
end

fclose(log_fd);

dprintpdf([outFolder 'summary.pdf'], 'fig', fig, 'w', 29.7, 'h', 21)

fprintf('Exporting dots\n');
for kk = 1:size(Tall,1) % channel 
    for ll = 1:size(Tall,2) % mask
        channel = channelNames{kk};
        mask = maskNames{ll};
        T = Tall{kk,ll};
        T_table = array2table(T);
        T_table.Properties.VariableNames = {'x', 'y', 'z', 'DoG', 'Pixel_value', 'Object_no', 'File'};
        writetable(T_table, [outFolder 'dots_' channel '_' mask '.csv']);
    end
end

end