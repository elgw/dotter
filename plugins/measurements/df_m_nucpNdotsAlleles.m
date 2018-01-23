function NDA = df_m_nucpNdotsAlleles(varargin)
% Number of dots per allele

if numel(varargin)==1
    if strcmpi(varargin{1}, 'getSettings')
        t.string = 'Dots per cluster';
        t.selChan = 1;
        t.features = '2N';
        NDA = t;
        return
    end
end


%M = varargin{1};
N = varargin{2};
chan = varargin{3};
%chan2 = varargin{4};

        % Number of dots per allele
        NDA = zeros(numel(N), 2);
        for kk = 1:numel(N)
            for cc = chan
                for aa = 1:2 % allele
                    %keyboard
                    dots = N{kk}.clusters{aa}.dots{cc};
                    NDA(kk,aa) = NDA(kk,aa) + size(dots, 1);
                end
            end
        end
        % Fix the order
        NDA = NDA';
        NDA = NDA(:);
        %keyboard
    end
