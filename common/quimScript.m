


clear channel

%% Select folders
fprintf('Please select which folders to use\n');
fi = uipickfiles('Prompt', 'Select _calc folders');

files = [];
for kk =1:numel(fi)
    files(kk).name = fi{kk};
end

for ff = 1:numel(files)
    folder = files(ff).name;
    nmfiles = dir([folder '/*.NM']);
    for nn = 1:numel(nmfiles)        
        nmFile = nmfiles(nn).name;
        load([folder '/' nmFile], '-mat');
        for cc = 1:numel(N)
            DA = [DA N{cc}.dapisum];
        end
    end
end

[ldapi, rdapi] = select_dapi(DA);
clear DA


D = []; % Dots per nuclei

%% For each folder
for ff = 1:numel(files)
    disp(['Reading ' files(kk).name])
    
    folder = files(ff).name;
    nmfiles = dir([folder '/*.NM']);
    
    if numel(nmfiles)==0
        fprintf('No NM files %s\n', folder);
        fprintf('Press Ctrl+C to abort\n');
        pause
    end

        
    
    %% for each NM file
    for nn = 1:numel(nmfiles)
        
        nmFile = nmfiles(nn).name;
        load([folder '/' nmFile], '-mat');
        
        if ~isfield(M, 'dots')
            disp('No dots to load!')
            % See code in rnaSlide to put them there, or run it for this data
            % set
        end
        
        if ~exist('channel', 'var')
            if numel(M.channels)>1
                channelNo = listdlg('PromptString', 'Select a channel', 'ListString', M.channels);
            else
                channelNo = 1;
            end
            channel = M.channels{channelNo};
            fprintf('Using channel #%d : %s\n', channelNo, channel);
        end
        
        P = M.dots{channelNo};
        d = P(:,4);
        [th, subs, lambda] = dotThreshold(d);
        
        for mm = 1:numel(N)
            if(N{mm}.area>100)
                D = [D sum(N{mm}.dots{1}(:,4)>th)];
            end
        end
        
    end
end

H = double(histo16(uint16(D)));
location = find(H>0);
location = location(end);

figure,
bar(H(1:location(end)+1))
title(sprintf('%s : %d cells, avg#dots %.2f', channel, numel(D), mean(D)))
xlabel('Dots')
ylabel('#cells')

fprintf('Total number of cells: %d\n', numel(D));
fprintf('Mean number of dots per cell: %f\n', mean(D))


