function D = df_m_maxDistanceAlleles(varargin)
% Outliner Distance for each Allele
%
% Returns the smallest distance for the dot with largest minimal distance

if numel(varargin)==1
    if strcmpi(varargin{1}, 'getSettings')
        t.string = 'Cluster: Outlier Distance [NM]';
        t.selChan = 1;
        t.features = 'C';
        t.s.plot = 0;
        D = t;
        return
    end
end

M = varargin{1};
N = varargin{2};
chan = varargin{3};
s = varargin{5};

D = [];

if ~isfield(M{1}, 'pixelSize')
    warning('Pixel size not specified!')
    res = [130,130,300];
else
    res = M{1}.pixelSize;
end

styles = 'xo';
colours = jet(numel(M{1}.channels));

if s.plot
    f = figure();
end

for nn = 1:numel(N)
    if s.plot        
        figure(f)
        clf
        title(sprintf('Nuclei %d', nn));
        imagesc(M{N{nn}.metaNo}.mask == N{nn}.nucleiNr)
        colormap gray
        hold on
        axis image
        set(gco, 'Clim', [0,2]);
    end
        
    for aa = 1:numel(N{nn}.clusters)
        dots = [];
        
        for cc = chan
            cdots = N{nn}.clusters{aa}.dots{cc};
            dots = [dots ; cdots];
            if s.plot
                %plot3(cdots(:,1), cdots(:,2), cdots(:,3), styles(aa), 'Color', colours(cc,:));
                if numel(cdots)>0
                    plot(cdots(:,2), cdots(:,1), styles(aa), 'Color', colours(cc,:));                
                end
            end
        end
        
        if s.plot
            legend(M{1}.channels);
        end
        
        if size(dots,1)>1
            % Convert pixels to metric distance
            dots(:,1)=dots(:,1)*res(1);
            dots(:,2)=dots(:,2)*res(2);
            dots(:,3)=dots(:,3)*res(3);
            % Distance matrix between dots
            DM = squareform(pdist(dots(:,1:3), 'euclidean'));
            
            % Handle diagonal                                    
            DM(1:size(DM,1)+1:end) = Inf;            
            
            % Get outliner distance
            D = [D; max(min(DM))];
            
        else
            D = [D; nan];
        end
    end
    
    if s.plot        
        fprintf('Nuclei: %d\n', nn);
        set(gca, 'Clim', [0,2])
        bbx = N{nn}.bbx;
        axis(bbx([3,4,1,2]));
        title(sprintf('Max distances: x: %.0f/%.1f, o: %.0f/%.1f nm/pixels', D(nn,1), D(nn,1)/130, D(nn,2), D(nn,2)/130));
        pause
    end
end

end
