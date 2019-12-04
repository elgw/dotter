function [] = UDA_Q1(folder)

% UDA: userDots analysis
% Q1: One dot per channel and cluster
% One channel is reference.
% Get: Distance to reference channel


%% Create an array with all the Nuclei in the folder
[N, channels] = UDA_get_nuclei(folder);

fprintf('Proceeding with the analysis\n')

%% Set reference channel


refChannel = listdlg('PromptString', 'Select a reference channel', ...
    'SelectionMode', 'single', ...
    'ListString', channels);

prompt = {'x/y-resolution', 'z-resolution'};
res = inputdlg(prompt, 'Image resolution', 1, {'130','200'});
if numel(res) == 0
    disp('No resolution given')
    return
end

res = [str2num(res{1}), str2num(res{1}), str2num(res{2})];

if numel(refChannel)==0
    disp('No reference channel selected')
    return
end

% All Nuclei in N

otherChannels = 1:numel(channels);
otherChannels = setdiff(otherChannels, refChannel);
D = {[],[],[],[],[],[]};

for nn = 1:numel(N) % For each nuclei
    for kk = 1:2 % For each allele
        rdot = N(nn).userDots{refChannel}(N(nn).userDotsLabels{refChannel}==kk, :);
        if numel(rdot)>0 && size(rdot,1)==1
            for oo = otherChannels
                odot = N(nn).userDots{oo}(N(nn).userDotsLabels{oo}==kk, :);
                if numel(odot)>0
                    if size(odot,1)==1
                        D{oo} = [D{oo}, eudist(res.*rdot(1,1:3), res.*odot(1,1:3))];
                    else
                        disp('More than one dot')
                    end
                end
            end
        end
    end
end

dmax = 0;
for kk =1:numel(D)
    if numel(D{kk})>0
        dmax = max(dmax, max(D{kk}));
    end
end

for cc = otherChannels
    figure
    ehistogram('data', D{cc}, 'xlabel', 'distance', ...
        'ylabel', sprintf('# (%d)', numel(D{cc})), ...
        'title', ...
        sprintf('Channel: %s to %s', channels{refChannel}, channels{cc}), ...
        'legend', sprintf('Mean %.2f, std: %.2f', mean(D{cc}), std(D{cc})), ...
        'domain', linspace(0, dmax, 15) ...
        );
end

end %function