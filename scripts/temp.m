L = read_raw('/home/erikw/data/chromflock/1000G_extra_compaction_relax/8.000000_1000_MAX.L.uint8', 'uint8');
L = L(L<24); % Excluded Y if not already excluded

G = loadGPSeq(L, ...
    '/bicroserver2/projects/GPSeq/centrality_by_seq/SeqNoGroup/B170_transCorrected/all/B170_transCorrected.asB165.rescaled.bins.size100000.step100000.csm3.rmOutliers_chi2.rmAllOutliers.tsv', ...
    100000);

GN = log2(G);
%GN(GN>1) = 1;
%GN(GN<0) = 0;
% GG: That's GPSeq score, ergo "centrality". I.e., greater at the center.
GN = 1-GN;

figure
GNX = GN;
GNX(GNX<0) = 0+eps;
GNX(GNX>1) = 1-eps;
[counts, edges] = histcounts(GNX, linspace(0,1,15));
%[counts, edges] = histcounts(GN, linspace(0,1,15));
volumes = 0*counts;
for kk = 1:numel(counts)
    volumes(kk) = 4/3*pi*edges(kk+1)^3 - 4/3*pi*edges(kk)^3;
end

figure
histogram('BinCounts', volumes, 'BinEdges', edges)
hold on
histogram('BinCounts', counts, 'BinEdges', edges)

dens20 = numel(GN)/((4/3)*pi); % beads/volume
histogram('BinCounts', (counts./volumes), 'BinEdges', edges)
hold on
plot([0,1], 5*[dens20, dens20])
xlabel('Radius')
ylabel('Density, beads/volume')
legend({'From GPSeq', 'Max possible'})
figure,
histogram(GNX, linspace(0,1,15))

axis([0,1.2, 0, 2000])
x = linspace(0,1); hold on, plot(x, 2000*x.^2, 'r');


outfile = 'metadata.csv';
fout = fopen(outfile, 'w');
fprintf(fout, 'chr, start_mb\n');
for kk = 1:numel(L)
    chrStr = '';
    if(L(kk) < 23)
        chrStr = sprintf('chr%d', L(kk));
    end
    if L(kk) == 9
        chrStr = 'chr9.22';
    end
    if L(kk) == 22
        chrStr = 'chr22.9';
    end
    if L(kk) == 23
        chrStr = 'chrX';
    end
    assert(numel(chrStr)>0);
    
    fprintf(fout, '%s, %d\n', chrStr, S(kk));
end
fclose(fout);       

gpseqFile='/mnt/bicroserver2/projects/GPSeq/centrality_by_seq/SeqNoGroup/B170_transCorrected/all/B170_transCorrected.asB165.rescaled.bins.size1000000.step100000.csm3.rmOutliers_chi2.rmAllOutliers.tsv';
wpseqFile='/mnt/bicroserver2/projects/GPSeq/centrality_by_seq/SeqNoGroup/B170_transCorrected/all/B170_transCorrected.asB165.rescaled.bins.chrWide.csm3.rmOutliers_chi2.rmAllOutliers.tsv';

gpseq = tdfread(gpseqFile);
gpseqw = tdfread(wpseqFile);

prob_g_avg = 0*gseqw.prob_g;
for kk = 1:24
    chrStr = gpseqw.chrom(kk,:);
    n = 0;
    for ll = 1:size(gpseq.chrom, 1)        
        if strcmp(chrStr, gpseq.chrom(ll,:)) == 1
            prob_g = gpseq.prob_g(ll,:);
            if isfinite(prob_g)
                prob_g_avg(kk) = prob_g_avg(kk) + gpseq.prob_g(ll);
                n = n + 1;
            end            
        end
    end
    prob_g_avg(kk) = prob_g_avg(kk)/n;
end

figure,
scatter(gpseqw.prob_g, prob_g_avg)
ylabel('Average per chromosome')
xlabel('Chr Wide GPSeq')
pcorr = corr(gpseqw.prob_g(1:23), prob_g_avg(1:23));
title(sprintf('pcorr: %f', pcorr));

E = gpseqw.prob_g(1:23)- prob_g_avg(1:23);
pause
dprintpdf('/home/erikw/temp/chrWideVsAverageGPSeq', 'publish');

X = linspace(-1,1, 1000);
nDiv = 3;

v = (X+1)/2 * nDiv;

plot(X, floor(v));

A= [-0.077 0.591 0.755]
B = [-0.051 0.595 0.748]
norm(A-B)

I = df_readTif('/data/current_images/iEG/iEG613_190118_001/a594_001.tif');
%I = I(130:290, 250:350,:);
[P, meta] = df_getDots(I);
dotterSlide(I, P(:,1:4))

fwhm = df_fwhm(I, P(1:200, 1:3), 'verbose');

% Look at slice 22
% Small dots ~ 316 nm
% -> sigma = 316/2.35/130 = 1.0344
% -> sigma_D = 1.72*1.0344 = 1.7792

I = df_readTif('a594_001.tif');
s = dotCandidates('getDefaults')
I = double(I);
D1 = dotCandidates(I, s);
s2 = s;
s2.sigmadog = 4.2*s.sigmadog/min(s.sigmadog);
s.ranking = 'DoG'
D2 = dotCandidates(I, s2);
V = gsmooth(I, sigma, 'normalized')-gsmooth(I, sigma+0.001, 'normalized');


D2 = dotCandidates(I, s2);

V = gsmooth(I, sigma, 'normalized')-gsmooth(I, sigma, 'normalized');

V2 = gsmooth(I, sigma)-gsmooth(I, sigma+0.001);
volumeSlide(V2-V)

s2.sigmadog = 4.2*s.sigmadog/min(s.sigmadog)/1.72;
s2.ranking = 'gaussian';
D3 = dotCandidates(I, s2);


function test()
close all

D = 10^9*rand(100,1);
th = median(D);

gui.f = figure();
gui.a = axes('Units', 'Normalized', ...
    'Position', [0.1,0.25,.8,.7]);
gui.h = histogram('Parent', gui.a, D, round(numel(D)/2));
hold on
ax = axis();
gui.thLine = plot([th, th], [ax(3), ax(4)], 'LineWidth', 2);

set(gui.f, 'WindowButtonDownFcn', @interStart);

gui.thValue = uicontrol('Style', 'text', ...
    'String', '', ...
    'Units', 'Normalized', ...
    'Position', [0.1,0,.8,.2], ...
    'Callback', @ok, ...
    'Parent', gui.f, ...
    'HorizontalAlignment','left', ...
    'FontName', get(0,'FixedWidthFontName'));

gui.ok = uicontrol('Style', 'pushbutton', ...
    'String', 'Ok', ...
    'Units', 'Normalized', ...
    'Position', [0.85,0.05,.1,.1], ...
    'Callback', @ok, ...
    'Parent', gui.f);

setTh(th);

uiwait(gui.f);
close(gui.f);

function ok(varargin)
    uiresume();
end

    function interStart(varargin)
        gco
        if gco == gui.h | gco == gui.a
            x = get(gui.a, 'CurrentPoint'); x = x(1);        
            setTh(x);          
        end
        if gco == gui.thLine
            set(gui.f, 'WindowButtonMotionFcn', @lineDrag);  
            set(gui.f, 'WindowButtonUpFcn', @stopDrag);
        end
    end

    function stopDrag(varargin)
            set(gui.f, 'WindowButtonMotionFcn', []);  
    end

    function lineDrag(varargin)
           x = get(gui.a, 'CurrentPoint'); x = x(1);
           setTh(x);
    end

    function setTh(x)
        gui.thLine.XData = ones(1,2)*x;
        th = x;
        gui.thValue.String = sprintf('Nuclei: %d\nTh: %.2e\nAbove: %d\nBelow: %d', numel(D), th, sum(D>th), sum(D<th));     
    end
    
end


files = dir('*.NM')
for kk = 1:numel(files)
    load(files(kk).name, '-mat');
    M.dapifile  = regexprep(M.dapifile,'_*','_')    
    save(files(kk).name, 'M', 'N');
end

D = [  7.673798e+03       51304566  % chr22
       8.433787e+03     135006516  % chr11
       7.189571e+03     141213431  % chr9    
       9.026785e+03     159138663];% chr7		
p = plot(D(:,2), D(:,1))
set(gca, 'XTick', D(:,2));
set(gca, 'XTickLabel', {'22', '11', '9', '7'});
xlabel('Linear size, chr')
ylabel('Centroid distance, nm')
grid on


G = loadGPSeq(L, ...
    '/bicroserver2/projects/GPSeq/centrality_by_seq/SeqNoGroup/B170_transCorrected/all/B170_transCorrected.asB165.rescaled.bins.size100000.step100000.csm3.rmOutliers_chi2.rmAllOutliers.tsv', ...
    100000);

GN = log2(G);
GN(GN>1) = 1;
GN(GN<0) = 0;
% GG: That's GPSeq score, ergo "centrality". I.e., greater at the center.
GN = 1-GN;

figure, plot(GN)


G = loadGPSeq(L, ...
    '/bicroserver2/projects/GPSeq/centrality_by_seq/SeqNoGroup/B170_transCorrected/all/B170_transCorrected.asB165.rescaled.bins.size1000000.step100000.csm3.rmOutliers_chi2.rmAllOutliers.tsv', ...
    1000000);
GN = log2(G);
GN(GN>1) = 1;
GN(GN<0) = 0;
% GG: That's GPSeq score, ergo "centrality". I.e., greater at the center.
GN = 1-GN;
figure, histogram(GN)