function AD = df_m_nucpDalleles(varargin)
% Distance between alleles.
%
% Measured by first calculating the centre
% of mass for each allele and then calculating the euclidean
% distance between them.

if numel(varargin)==1
    if strcmpi(varargin{1}, 'getSettings')
        t.string = 'Distance between alleles';
        t.selChan = 1;        
        t.features = 'N';
        AD = t;
        return
    end
end

M = varargin{1};
N = varargin{2};
chan = varargin{3};
% chan2 = varargin{4};

if ~isfield(M{1}, 'pixelSize')
    warning('Pixel size not specified!')
    res = [130,130,300];
else
    res = M{1}.pixelSize;
end

AD = zeros(numel(N), 1);
for kk = 1:numel(N)
    A1 = [];
    A2 = [];
    
    for cc = chan
        d1 = N{kk}.clusters{1}.dots{cc};
        A1 = [A1; d1];
        d2 = N{kk}.clusters{2}.dots{cc};
        A2 = [A2; d2];
    end
    
    if size(A1,1) == 0 || size(A2,1) == 0
        fprintf('Only one allele in nuclei %d\n', kk);
        AD(kk) = nan;
    else
        mA1 = mean(A1(:,1:3),1);
        mA2 = mean(A2(:,1:3),1);
        AD(kk) = norm(res.*(mA1-mA2));
    end
end

end