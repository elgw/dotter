function F = df_getFWHMstrongest(varargin)
% function F = df_getFWHMstrongest(varargin)
% Get fwhm for the strongest dot per nuclei
%
% 1. Get the strongest dot from each nuclei and it's fwhm
% 2. Set some boundaries for fwhm, i.e. an allowed range, [a,b]

s.folder = '/data/current_images/iEG/iEG120_310116_001_calc_fwhm/';

s.dummy = 1;

for kk = 1:numel(varargin)
    if strcmpi(varargin{kk}, 'getDefaults')
        n = s;
        return
    end
    if strcmpi(varargin{kk}, 'folder')
        s.folder = varargin{kk+1};
    end
end

disp('Settings:');
disp(s);

if ~isfield(s, 'folder')
    s.folder = uigetdir();
    fprintf('Picked: %s\n', s.folder);
end

if s.folder == 0
    disp('No folder selected')
    return
end

files = dir([s.folder '/*.NM']);

if numel(files) == 0
    disp(['No .NM files in ' s.folder])
    return
end
fprintf('Found %d files\n', numel(files));

F = [];

D = load([s.folder files(1).name], '-mat');
M = D.M; N = D.N;

for ch = 1:numel(M.channels)
    fprintf('Processing channel: %s\n', M.channels{ch});
    %% 1 FWHM for strongest dot per nuclei
    
    f = []; % for storing the fwhm
    for kk = 1:numel(files)
        D = load([s.folder files(kk).name], '-mat');
        M = D.M; N = D.N;
        
        
        
        chV = df_readTif(M.channelf{ch});
        
        for nn = 1:numel(N)
            d = N{nn}.dots{1};
            d = d(1,:);
            f = [f, df_fwhm(chV, d(1,1:3)) ];
        end
    end    
    
    figure
    histogram(f, 'normalization', 'pdf')
    xlabel('fwhm (pixels)')
    
    %% 2. Set range
    fp = f(f>0);
    a = min(fp);
    b = max(fp);
    
    hold on
    ax = axis();
    plot([a,b], ax(4)/2*[1,1], 'k');
    legend({sprintf('fwhm %d dots', numel(f)), 'suggested fwhm range'})
    plot([a,a],[0,ax(4)]);
    plot([b,b],[0,ax(4)]);
    title(sprintf('%s: strongest dot per nuclei\nfwhm in [%.2d and %.2d]', M.channels{ch}, a, b'));
    F{ch} = f;
end

disp('done');
end