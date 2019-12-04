function r = df_cc(varargin)

s.filename = '';  % Where to write the result
s.maxDist1 = 15;  % Max possible distance between dots
s.maxDist2 = 2;   % Max distance between dots after correction for shifts
s.polyorder = 2;  % Order of polynomial model, 1, 2 or 3
s.verbose = 0;
s.plot = 0;

channels = {};

for kk = 1:numel(varargin)
    if strcmpi(varargin{kk}, 'dots')
        D = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'channels')
        channels = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'settings')
        s = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'getDefaults')
        r = s;
        return
    end
end

assert(numel(channels) == numel(D));

if numel(s.filename) == 0
    outFolder = df_getConfig('df_cc', 'ccfolder', '~');
    
    [b,a] = uiputfile([outFolder, filesep(), datestr(now, 'yyyymmdd'), '.cc'], 'Where to save the cc?');
    
    if isnumeric(b)
        return
    end
    
    s.filename = [a b];
    df_setConfig('df_cc', 'ccfolder', a);    
end

disp('Finding correspondences');
C = df_cc_cluster('dots', D, 'settings', s, 'channels', channels);

disp('Finding polynomials');
ccFile = df_cc_create('dots', C, 'settings', s, 'channels', channels);

if numel(ccFile)>0    
    opts.outputDir = tempdir;
    opts.codeToEvaluate = sprintf('df_cc_view(''%s'')', ccFile);
    opts.showCode = false;
    rfile = publish('df_cc_view.m', opts);
    web(rfile);
else
    warning('Failed to complete the cc calculations')
end
 
disp('df_cc() is done');

end