function th = df_dotThresholdP(varargin)
% Suggest a threshold based on binomial modelling of the 
% distribution of dots.
%
% 1/ Loads all NM files in a folder
% 2/ Loads all nuclei from N
% 3/ Picks the 100 strongest dots from each nuclei
% 4/ For each threshold, get the distribution of dots per nuclei, D
% 5/ Find the P that minimizes  ||B(nTrueDots, P)-D||
%
% Uses the following information from about the experiment:
%  - Dapi threshold
%  - Number of dots per nuclei and channel (expected)
%  - Number of k-mers per probe
%
% Example: df_dotThresholdP('folder', '/home/me/images/iAB001_calc/')

%% Parse input
th = [];
folder = [];
files = [];
channels = [];
saveFig = 0;

s.calcp = 0; % estimate p, the binding probability for individual k-mers

for kk = 1:numel(varargin)
    if strcmpi(varargin{kk}, 'files')
        file = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'folder')
        folder = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'saveFig')
        saveFig = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'channels')
        allChannels = 0;
        channels = channels;
    end
end
    
if folder(end) ~= filesep()
    folder = [folder filesep()];
end

if numel(files) == 0
    files = dir([folder '*.NM']);
end


D = load([folder files(1).name], '-mat');

if numel(channels) == 0
    channels = 1:numel(D.M.channels);
end

for chan = channels

fprintf('Using channel %s\n', D.M.channels{chan});
fprintf('N kmers: %d\n', D.M.nkmers);


%% Load the first 100 dots from each nuclei
nucleiDots = [];
nNuclei = 0;
userDots = []; % All the user dots 
nUserDots = []; % User dots per Nuclei
for kk = 1:numel(files)
    D = load([folder files(kk).name], '-mat');
    M = D.M;    
    N = D.N;
    dapiThres = M.dapiTh;
    nNuclei = nNuclei + numel(N);
    for nn = 1:numel(N)
        
        if N{nn}.dapisum < dapiThres
            
            if(isfield(N{nn}, 'userDots'))                
                if numel(N{nn}.userDots{chan})>0
                    nUserDots = [nUserDots; numel(N{nn}.userDots{chan}(:,4))];
                    userDots = [userDots; N{nn}.userDots{chan}(:,4)];                    
                else
                    nUserDots = [nUserDots; 0];
                end
            end
            
            dAll = N{nn}.dots{chan};
            
            dd = dAll(:,4)';
            if numel(dd)>100
                dd = dd(1,1:100);
            end
            dd(numel(ones(100,1))) = 0;
            nucleiDots = [nucleiDots; dd];
        end
    end
end

fprintf('Loaded %d fields. Used %d of %d nuclei\n', numel(files), size(nucleiDots,1), nNuclei);

if 0
if numel(userDots)>0
    figure,
    x = -.5:(max(nUserDots)+.5);
    histogram(nUserDots, x,'normalization', 'pdf')
    min(userDots(:))
    title('userDots');
    xlabel('# userDots per nuclei')
    a = axis();
    a(1) = x(1); a(2) = x(end);
    axis(a)
    %dprintpdf('iEG364_nUserDots.pdf')
    
    figure,
    histogram(userDots, 'normalization', 'pdf')
    min(userDots(:))
    title('userDots');
    xlabel('Strength')
    pause
end
end

nExpDots = M.nTrueDots(chan); % number of expected dots per nuclei
nKmers = M.nkmers;

imgname = sprintf('%s/PvsE_%s.pdf', folder, M.channels{chan});
[retth, retP, retp] = thVsP(nucleiDots, nExpDots, nKmers, imgname);
fprintf('P: %.2f, p: %.3f, Threshold: %.2f\n', retP, retp, retth);
th(chan) = retth;
end

    function [retth, retP, retp] = thVsP(values, N, nKmers, imgname)
        %
        
        retth = [];
        retP = [];
        retp = [];
        
        threshold = linspace(0,max(values(:,1)), 1000);
        thp = zeros(size(threshold));
        
        for kk = 1:numel(threshold)
            dotThres = threshold(kk);
            v = values;
            v = (v>dotThres);
            nDots = sum(v,2);
            %p = [sum(nDots==2), sum(nDots==1), sum(nDots==0)];
            p = double(df_histo16(uint16(nDots)))';
            p = p/sum(p(:));
            p = p(1:(N+1));
            
            
            % Find the probability that minimizes the l2-norm
            optimP = @(a) norm(binopdf(0:N, N, a)-p);
            [a,e] = fminsearch(optimP, .5);
            thp(kk) = a;
            l2(kk) = e;
        end
        
        f = figure,
        plot(threshold, thp)
        hold on
        plot(threshold, l2)
        legend({'P', 'l2-error'});
        xlabel('dot threshold');
        axis([0,40,0,1])
        grid on
        %dprintpdf('thVSp_iEG120_001.pdf')
        %dprintpdf('thVSp_iEG264_002.pdf')
        
        
        % Define as P where l2 drops below 0.1
        ipos = find(l2<.1);
        if numel(ipos)>0
            ipos = ipos(1);
            retth = threshold(ipos);
        else
            warning('Could not find a good threshold, errors high all over');
            retth = threshold(end);
        end
        retP = thp(ipos);
        ax = axis();
        plot([retth, retth], ax(3:4), 'k');
        legend({'P', 'l2-error', 'automatic threshold'});
        th1 = retth+5;
        th2 = retth+15;
        
        if saveFig
            dprintpdf(imgname);
            close(f);
        end
        
        try
            p1 = interp1(threshold, thp, th1);
            p2 = interp1(threshold, thp, th2);
        catch e            
            p1 = nan;
            p2 = nan;
        end
        
        %hold on
        %plot(th1, p1, 'ko')
        %plot(th2, p2, 'ko')
        
        % for iEG120
        p40 = 8.92; % curve is .6
        p60 = 17.8; % curve is .4
        
        % for iEG264
        p75 = 13.7; % curve is .25
        p85 = 19.1; % curve is .4
        
        if s.calcp
        [A, P] = meshgrid(10.^linspace(-3,log10(0.5)), linspace(0,0.07));
        
        E = 0*A;
        for mm =1:size(A,1)
            for nn = 1:size(A,2)
                a = A(mm,nn);
                p = P(mm,nn);
                %E(mm,nn) = norm(...
                %    [binocdf(round(a*p40), 96, p)-.4, ...
                %    binocdf(round(a*p60), 96, p)-.6]);
                %E(mm,nn) = norm(...
                %    [binocdf(round(a*p75), Nkmers, p)-.75, ...
                %    binocdf(round(a*p85), Nkmers, p)-.85]);
                E(mm,nn) = norm(...
                    [binocdf(round(a*th1), nKmers, p)-(1-p1), ...
                    binocdf(round(a*th2), nKmers, p)-(1-p2)]);
            end
        end
        end
        
        if s.calcp
        figure,
        su = surface(A,P, E);
        xlabel('Scaling')
        ylabel('p')
        su.EdgeColor = 'none';
        %dprintpdf('p_scaling_iEG120_001.pdf')
        %dprintpdf('p_scaling_iEG264_002.pdf')
        
        
        set(gca, 'CLim', [min(E(:)), min(E(:))+.1*(max(E(:))-min(E(:)))])
        
        emin = min(E(:));
        
        minpos = find(E==min(E(:)));
        [m,n] = ind2sub(size(E), minpos);
        hold on
        
        retp = [];
        for kk = 1:numel(m)
            retp = [retp, P(m(kk), n(kk))];
        end
        retp = mean(retp);
        
        x = [];
        y = [];
        
        
        %% 2nd alternative, which is smooth, match the tail of 1-thp against
        % the cumulative binomial distribution. Assumption: the position of
        % 0 is not shifted.
        
        ma = @(x) match(x, threshold, thp, ipos, nKmers);
        [xmin,e] = fminsearch(ma, [1, 0.02]);
        c = xmin(1);
        p = xmin(2);
        
        dataCDF = 1-thp;
        modelCDF = interp1(0:nKmers, binocdf(0:nKmers, nKmers, p), c*threshold);
        figure
        plot(threshold, dataCDF)
        hold on
        plot(threshold, modelCDF)
        xlabel('Intensity')
        hold on
        plot([threshold(ipos), threshold(ipos)], [0,1], 'k')
        title(sprintf('CDF, p=%.3f\n', p))
        legend({'data', 'model', 'threshold'}, 'Location', 'NorthWest')
        
        fprintf('Estimated p=%.3f\n', p);
        
        if 0
            figure,
            h = histogram(values(values>retth),100, 'normalization', 'pdf')
            hold on
            y = interp1(0:Nkmers, binopdf(0:Nkmers, Nkmers, .5), c*threshold*10)
            y = y/sum(y(:))*35;
            plot(threshold,y);
            %plot((0:Nkmers)/c, binopdf(0:Nkmers, Nkmers, p))
            keyboard
        end
        end
        
        
    end

    function e = match(x, threshold, thp, ipos, nKmers)
        % ipos: first position to include in the error function
        % i.e., integration from ipos to end
        c = x(1);
        p = x(2);
        
        dataCDF = 1-thp;
        modelCDF = interp1(0:nKmers, binocdf(0:nKmers, nKmers, p), c*threshold, 'spline');
        
        if 0
            figure(10)
            clf
            plot(dataCDF), hold on, plot(modelCDF), pause
        end
        
        e = norm(modelCDF(ipos:end)-dataCDF(ipos:end));
        
    end

end