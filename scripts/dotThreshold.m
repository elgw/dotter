function th = dotThreshold(D, varargin)
% Based on some observations in D of dot 'intensities' (DoG response or
% pixels values, ...), suggests a threshold for separation between
% background and foreground.
%
% Uses what is called Arjun's method, used in imageM
%
% Example:
% V = df_readTif('cy5.tif');
% s.sigmadog = 1.2;
% s.xypadding = 5;
% s.localization = 'DoG'; % or 'intensity'
% s.maxNpoints = 10000000; % set high to include all dots
% D = dotCandidates(V, s);
% th = dotThreshold_imageM(D(:,4)) % For DoG values
% D = D( D(:,4)>th, :);
% volumeSlide(D)
%
% Optional arguments, with their default values taken from imageM
% 'width' = 5 % number of thresholds
% 'thresholds' = 100 % number of thresholds to try
% 'offset' = 10; % ?
%
% While this seems to work well with 'DoG' values, it does not work very
% well with other features such as the number of photons.

% ImageM, see auto_thresholding.m
% In that function, the variable thresholdfn is nout from
% BW_multithresstack: the number of pixels above the threshold in the LoG
% filtered image.

% Add another condition to rule out obviously bad thresholds?

if nargin==0
    disp('DEMO')
    t = load('/home/erikw/Desktop/eleni_segmentation/dw_calc/001.NM', '-mat');
    
    D = t.M.dots{1}(:,4);
    dotThreshold(D)
    return
end

if numel(D) == 0
    return;
end

% The domain is defined as the lowest to largest value
% hence, it is sensitive to the largest (spurious value)
% It is hard to see how this can be made invariant to the
% type of dots/features used.

width = 25;
%width = round(10/(maxd-mind)*1000);
n_thresholds = 200;
offset = 1;

figTitle = '';

for kk = 1:numel(varargin)
    if strcmp(varargin{kk}, 'width')
        width = varargin{kk+1};
    end
    if strcmp(varargin{kk}, 'offset')
        offset = varargin{kk+1};
    end
    if strcmp(varargin{kk}, 'thresholds')
        n_thresholds = varargin{kk+1};
    end
    if strcmp(varargin{kk}, 'title')
        figTitle = varargin{kk+1};
    end
end

interactive = 0;

if nargout == 0
    interactive = 1;
end

if mod(width, 2) == 0
    disp('width has to be an odd integer')
    return
end

if ~(size(D,1) == 1 || size(D,2)==1)
    disp('D has to be 1 x N or N x 1')
    return
end

% Define domain, Dom from [0 to largest]
mind = min(D(:));
maxd = max(D(:));
Dom = linspace(mind, maxd, n_thresholds);

if interactive
    mind
    maxd
    n_thresholds
    width
end

% Stretch D to D2 for histogram calculations
D2 = D-mind; D2 = D2/( maxd-mind); % in [0,1]
D2 = D2*n_thresholds;
D2 = uint16(D2);

% Construct the histogram
H = df_histo16( D2 );

H = H(2:n_thresholds+1); % result is 32 bit
H = double(H);
%H = cumsum(H);

% Calculate the inverse coefficient of variation
meanS = zeros(size(H));
stdS  = zeros(size(H));

for kk = 1:numel(H)-width
    win = H(kk:kk+width-1);
    meanS(kk+(width-1)/2) = mean(win);
    stdS(kk+(width-1)/2) = std(win);
end

iCv = meanS./(stdS+offset);

% Extract the maximas
maxx = max(iCv);
th = find(iCv== maxx(1));
th = th(1); % take first if multiple
th = Dom(th); % map to the domain
fprintf(' Found threshold: %.2f', th);
fprintf(' (%d/%d dots)\n', sum(D(:)>th), numel(D));

if interactive
    figure('Name', figTitle);
    subplot(3,1,1)
    cH = cumsum(H);
    plot(Dom, cH/cH(end))
    title('Cumulative distribution')
    ylabel('Int H')        
    
    subplot(3,1,2)
    plot(Dom, H)
    ax = axis;
    ax(1)= mind;
    hold on
    plot([th, th], ax(3:4), 'r')
    axis(ax);
    
    title(sprintf('Histogram, %d dots', numel(D)))
    set(gca, 'YScale', 'log')
    xlabel('Threshold')
    ylabel('#')
    
    subplot(3,1,3)
    plot(Dom, iCv)
    %hold on
    %plot(Dom, iCv2, '--r')
    xlabel('Threshold')
    ylabel('1/CV');
    %ylabel('mean(w)/(std(w)+offset)');
    hold on
    
    ax = axis;
    ax(1)= mind;
    axis(ax);
    % patch show width
    plot([th, th], ax(3:4), 'r')
    title(sprintf('Threshold: %.3f Dots: %d', th, sum(D(:)>th)));
    
end

end