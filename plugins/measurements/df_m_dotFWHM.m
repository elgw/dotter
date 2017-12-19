function V = df_m_dotFWHM(varargin)
% Calculates the FWHM for all dots in allele 1 or 2
% Image data is required.

if numel(varargin)==1
    if strcmpi(varargin{1}, 'getSettings')
        t.string = 'Dot FWHM [AU]';
        t.selChan = 1;
        t.features = 'D';
        V = t;
        return
    end
end

M = varargin{1};
N = varargin{2};
chan = varargin{3};


lastMeta = -1;

V = [];
for nn = 1:numel(N)
    
    % If this nuclei belongs to another M than the last one, load images
    % from all channels
    if lastMeta ~= N{nn}.metaNo
        for cc = 1:numel(M{N{nn}.metaNo}.channels);
            imFile = strrep(M{N{nn}.metaNo}.dapifile, 'dapi', M{N{nn}.metaNo}.channels{cc});
            disp(imFile);
            I{cc} = df_readTif(imFile);
            lastMeta = N{nn}.metaNo;
        end
    end
    
    for aa = 1:2
        dots = [];
        for cc = chan
            dots = N{nn}.clusters{aa}.dots{cc};
            fwhm = df_fwhm(I{cc}, dots);
            V = [V; fwhm];
        end
    end
    
    
end

% Follow the conventions and set nan for non-calculatable properties.
V(V==-1) = nan;

end