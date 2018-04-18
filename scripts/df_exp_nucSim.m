function [TH, dpn, dpn_all] = df_exp_nucSim(varargin)
%% Look at a set of nuclei and figure out which are outliers based on the
% dot profiles, consisting of the 20 strongest dots.
% Returns the nuclei that are ok
%
% [M,N] = df_exp_nucSim('M', M, 'N', N);
%

%% Settings
s.nTrue = 2;
s.nDots = 5*s.nTrue; % Dots to extract per nuclei

s.plot = 1;
s.nThresholds = 1024;
s.curve_max_dist = 1.1;


s.query = 1;
for kk = 1:numel(varargin)
    if strcmpi(varargin{kk}, 'M')
        M = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'N')
        N = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'noquery')
        s.query = 0;
    end
    if strcmpi(varargin{kk}, 'noplot')
        s.plot = 0;
    end
end

if ~exist('M', 'var')
    %folder = '/data/current_images/iJC766_20170720_002_calc/';
    folder = uigetdir('/data/current_images/iAM/');
    
    [N, M] = df_getNucleiFromNM('folder', {folder}, 'noClusters');
end

fprintf('%d nuclei loaded\n', numel(N));
[M,N] = df_exp_onlyG1(M,N);
fprintf('Keeping %d G1\n', numel(N));

s.nChan = numel(M{1}.channels);

if s.query
    s = StructDlg(s);
end

%% Extract dots
P = extractDots(N, s);

%% Select nuclei for threshold analysis
PS = select_curves(P, s);
for cc = 1:numel(PS)
    fprintf('%d of %d nuclei used\n', size(PS{cc},1), size(P{cc},1));
end

[TH, THS, Q, B] = get_thresholds(PS, s);

dpn = {};
dpn_all = {};
for kk = 1:numel(P)
    dpn{kk} = df_histo16(uint16(sum(PS{kk}>TH(kk),2)));
    dpn_all{kk}= df_histo16(uint16(sum(P{kk}>TH(kk),2)));
end

%% Plot what we got

if s.plot
    fw = 200;
    f = figure;
    pos = f.Position;
    pos(3) = 5*fw;
    pos(4) = s.nChan*fw;
    f.Position = pos;
    
    for cc = 1:s.nChan
        
        subplot(s.nChan, 4, cc*4-4+1)
        plot(P{cc}')
        title('All nuclei')
        h = text(-5, 2, M{1}.channels{cc})
        set(h, 'rotation', 90);
        subplot(s.nChan, 4, cc*4-4+2)
        plot(PS{cc}')
        title('Selected nuclei')
        subplot(s.nChan, 4, cc*4-4+3)
        plot(THS{cc}, Q{cc})
        a = axis();
        hold on
        plot([TH(cc), TH(cc)], [a(3), a(4)], '--k');
        xlabel('Threshold')
        ylabel('Quality');
        title('Threshold finding')
        
        subplot(s.nChan, 4, cc*4-4+4)
        bar(0:s.nDots,B{cc})
        title('At best threshold')
        xlabel('Dots')
        ylabel('#')
        
        %plot(THS{cc}, Q{cc});
    end
end

%dprintpdf('/home/erikw/profiles_iEG458.pdf', 'w', 45, 'h', 10);
%dprintpdf('/home/erikw/profiles_iXL217.pdf', 'w', nChan*10, 'h', 10);
%dprintpdf('/home/erikw/profiles_iAM24.pdf', 'w', nChan*10, 'h', 10);
%dprintpdf('/home/erikw/profiles_iJC1041.pdf', 'w', nChan*10, 'h', 10);
%dprintpdf('/home/erikw/profiles_iJC1024.pdf', 'w', nChan*10, 'h', 10);

end

function P = extractDots(N, s)

for cc = 1:s.nChan
    P{cc} = [];
end

for kk = 1:numel(N)
    for cc = 1:s.nChan
        D = N{kk}.dots{cc};
        if(size(D,1)>s.nDots)
            D = D(1:s.nDots,:);
        end
        if(size(D,1)>=s.nDots)
            P{cc} = [P{cc}; D(:,4)'];
        end
    end
end
end

function PS = select_curves(P, s)

for cc = 1:s.nChan
    Q = P{cc};
    w = sqrt(mean(Q)+1);
    for kk = 1:size(Q,1)
        Q(kk,:) = Q(kk,:)./w;
    end
    m = mean(Q,1);
    nm = norm(m);
    m = m/nm;
    d = zeros(size(Q,1),1);
    for kk = 1:size(Q,1)
        d(kk) = abs(m*Q(kk,:)')/nm;
    end
    
    C = P{cc}(d<s.curve_max_dist,:);
    PS{cc} = C;
end

end

function [TH, THS, Q, B] = get_thresholds(PS, s)
% Return best thresholds in TH
% Threshold that were tried in THS
% Q: quality for each threshold
% B: "bars" for the best threshold

for cc = 1:s.nChan
    C = PS{cc};
    % Set threshold to try
    maxThres = max(max(C(:,s.nTrue:end)));
    ths = linspace(min(C(:)), maxThres, s.nThresholds);
    %keyboard
    for tt = 1:numel(ths)
        CT = C>ths(tt);
        CT = sum(CT,2);
        nCT = df_histo16(uint16(CT));
        nCT = double(nCT(1:s.nDots+1));
        thsq(tt) = histQuality(nCT, s);
        %figure(3)
        %bar(0:s.nDots, nCT)
        %title(sprintf('%f', ths(tt)));
        %pause
    end
    
    thpos = find(thsq==max(thsq));
    thpos = thpos(1);
    thbest = ths(thpos);
    
    CT = C>thbest;
    CT = sum(CT,2);
    nCT = df_histo16(uint16(CT));
    nCT = double(nCT(1:s.nDots+1));
    
    Q{cc} = thsq;
    TH(cc) = thbest;
    THS{cc} = ths;
    B{cc} = nCT;
end

end

function q = histQuality(C, s)
% Quality of histogram
%C(1): n nuclei with 0 dots
%C(2): n nuclei with 1 dot
% ...


weight = (((0:s.nDots)-s.nTrue).^2).^(1/2);
weight = sqrt(weight+1);
weight(1:s.nTrue+1) = 0*weight(1:s.nTrue+1)*0.8;
weight = -weight;
weight = weight*0; % EXPERIMENTAL
weight(s.nTrue+1) = 1;

%keyboard
if 0
    plot(0:numel(weight)-1, weight, 'k')
    hold on
    plot(s.nTrue*[1,1], [min(weight), max(weight)], 'k--');
    legend('Weight Curve', 'nDots')
    xlabel('Number of dots')
    ylabel('Weight')
    
end
%keyboard
q = sum(C'.*weight);

end
