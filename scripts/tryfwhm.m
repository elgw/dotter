function dfwhm = tryfwhm(varargin)
% Script to measure and visualize also the fwhm of dots

close all
maxDots = 5000;

for kk = 1:numel(varargin)
    if strcmp(varargin(kk), 'maxDots')
        maxDots = varargin(kk+1);
    end
end

fprintf('maxDots: %d\n', maxDots);

% Load an already existing NM file
[A,B] = uigetfile('*.NM');
nmfile = [B, A];

% Calculate fwhm
D = load(nmfile, '-mat');

[channelName, channelNo] = selectChannel(D);

dots = D.M.dots{channelNo};
dots = dots(1:maxDots, :);

imageFile = strrep(D.M.dapifile, 'dapi', channelName);

disp('Reading image');
V = df_readTif(imageFile);
V = double(V);

disp('Calulating fwhm');
dfwhm = df_fwhm(V, dots);


fwhmTh = [2.7, max(dfwhm)]; % large fraction
%fwhmTh = [0, 2.7]; %small fraction
inteTh = [0, max(dots(:,4))];

fig = figure;
scatter(dots(:,4), dfwhm);
hold on
xlabel('Intensity');
ylabel('FWHM (pixels)');


viewPort = axis();
fwhmLow =  plot(viewPort(1:2), [fwhmTh(1), fwhmTh(1)], 'g');
fwhmHigh = plot(viewPort(1:2), [fwhmTh(2), fwhmTh(2)], 'r');
inteLow =  plot([inteTh(1), inteTh(1)], viewPort(3:4), 'g');
inteHigh = plot([inteTh(2), inteTh(2)], viewPort(3:4), 'r');

updateLimits()

% Make the selection, DS
DS = dots;
DS = DS(DS(:,4)>inteTh(1) & DS(:,4)<inteTh(2) &...
    dfwhm>fwhmTh(1) & dfwhm<fwhmTh(2), ...
    :);

dfwhmS = dfwhm(fwhmTh(1) & dfwhm<fwhmTh(2));


% Visualize features
dotterSlide(V, DS(:,1:4));
% dotterSlide(V, DS(:,1:4), [],[], 'fwhm', dfwhmS); TODO


% Visualize image and have one slider for intensity and one for fwhm


function [channel, channelNo] = selectChannel(NE)
% Select a channel among those listed in NE.M.channels
if numel(NE.M.channels)>1
    disp('Select a channel')
    channelNo = listdlg('PromptString', 'Select a channel', 'ListString', NE.M.channels);
    channel = NE.M.channels{channelNo};
else
    channelNo = 1;
    channel = NE.M.channels{1};
end
end

    function updateLimits()
        fwhmLow.YData  = [fwhmTh(1), fwhmTh(1)];
        fwhmHigh.YData = [fwhmTh(2), fwhmTh(2)];
        inteLow.XData  = [inteTh(1), inteTh(1)];
        inteHigh.XData = [inteTh(2), inteTh(2)];
    end

end