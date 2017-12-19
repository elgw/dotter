%% presentPairs.m
% Loads pairs of dots exported from NEditor and stored in csv files
% CA-correction is applied prior to the evaluation of pairwise distances

close all

% Dependencies
addpath('~/code/cCorr/') % For chromatic aberrations correction

%% Settings
% Cut off value, all distances above this will be disregarded
% if 0, disabled.
s.cutOff = 0;  % [nm]

% Correct for chromatic aberrations or not
s.CA = 1;

ex1.folder = '/Users/erikw/data/iJC63_160915_003_calc/NE1/';
ex1.description = '(M) Probe 5 and 6, (2296)';
ex1.desc = 'M5_6';
ex1.outFilePrefix = '5_6_';
ex1.chA = 'a594';
ex1.chB = 'tmr';

ex2.folder = '/Users/erikw/data/iJC65_160915_001_calc/NE1/';
ex2.description = '(M) Probe 13 and 14, (959)';
ex2.desc = 'M13_14';
ex2.outFilePrefix = '13_14_';
ex2.chA = 'a594';
ex2.chB = 'tmr';

ex3.folder = '/Users/erikw/data/iJC63_160915_003_calc/pairs/';
ex3.description = '(A) Probe 5 and 6, (2296)';
ex3.desc = 'A5_6';
ex3.outFilePrefix = '5_6_';
ex3.chA = 'a594';
ex3.chB = 'tmr';

ex4.folder = '/Users/erikw/data/iJC65_160915_001_calc/pairs/';
ex4.description = '(A) Probe 13 and 14, (959)';
ex4.desc = 'A13_14';
ex4.outFilePrefix = '13_14_';
ex4.chA = 'a594';
ex4.chB = 'tmr';

ex5.folder = '/Users/erikw/data/iEG40_211019_004_calc/NE1/';
ex5.description = '(M) Probe 5 and 6, (2296)';
ex5.desc = 'M2_5_6';
ex5.outFilePrefix = 'M2_5_6_';
ex5.chA = 'a594';
ex5.chB = 'cy5';


%% MAIN

% Choose what experiments to use:
%ex = {ex1, ex2}; % manual
%ex = {ex1, ex2}; % A vs M, 5 and 6
%ex = {ex2, ex4}; % A vs M, 13 and 14
ex = {ex5, ex5}; % 

for xx = 1:numel(ex)   
    folder = ex{xx}.folder;
    disp(folder)
    afiles = dir([folder '*' ex{xx}.chA '*.cvs']);
    bfiles = dir([folder '*' ex{xx}.chB '*.cvs']);
    
    
    A = []; B = [];
    
    for kk = 1:numel(afiles)
        aname = afiles(kk).name;
        bname = '';
        if ~strcmp(aname(1), 'r')
            bstart = strrep(aname, ex{xx}.chA, ex{xx}.chB);
            bstart = bstart(1:20);
            for ll = 1:numel(bfiles)
                if strcmp(bfiles(ll).name(1:20), bstart)
                    bname = bfiles(ll).name;
                end
            end
            
            % disp(aname), disp(bname)
            
            if numel(bname)>0
                adata = csvread([folder aname]);
                A = [A; adata(1,1:3)];
                
                bdata = csvread([folder bname]);
                B = [B; bdata(1,1:3)];
            end
            
            % Query for long interactions
                a = adata(1,1:3);
                a(:,1:2) = a(:,1:2)*130;
                a(:,3) = a(:,3)*200;
                
                b = bdata(1,1:3);
                b(:,1:2) = b(:,1:2)*130;
                b(:,3) = b(:,3)*200;
                
                if(eudist(a,b)>1000)
                    disp(aname)
                    disp(bname)
                end        
        end
    end
    
    % Correct for chromatic aberrations
    if s.CA == 1
        B = cCorrI(B, 'a594_quim', 'tmr_quim', 'cc_20151019.mat');
    end
    
    % Change from pixel to nm scale
    A(:,1:2) = A(:,1:2)*130;
    A(:,3) = A(:,3)*200;
    
    B(:,1:2) = B(:,1:2)*130;
    B(:,3) = B(:,3)*200;
    
    % Pairwise distances
    d = eudist(A,B);
    
    % Cut off all distances above some value
    if s.cutOff > 0
        d = d(d<s.cutOff);
    end
    
    ex{xx}.A = A;
    ex{xx}.B = B;
    ex{xx}.d = d;
end


% Figure out the bin layout, the widest data will decide
X = [0]; Y = [0];
for xx = 1:numel(ex)
    [Yt, Xt] = hist(d,21);
    if(max(Xt)>max(X))
        X = Xt;
    end
    if(max(Yt)>max(Y))
        Y = Yt;
    end
end

% Plot histograms
for kk = 1:numel(ex)
    figure
    hist(ex{kk}.d,X);
    title(sprintf('%s, %d pairs, mean %f nm\n', ex{kk}.description, size(ex{kk}.A,1), mean(ex{kk}.d)), 'interpreter', 'none')
    axis([0,max(Xt)*(1+1/20), 0, max(Y)+2])
    print('-dpng', sprintf('hist_%s.png', ex{kk}.desc));
end

% KDEs for all experiments on one plot
if 1
    figure,
    if s.cutOff== 0
        dmax = 1000;
    end
    for kk = 1:numel(ex)
        [k,d] = kdeParzen(ex{kk}.d, [], [0,s.cutOff], 400);
        plot(d,k, 'linewidth', 2)
        hold all
        leg{kk} = ex{kk}.description;
    end
    legend(leg)
    
    xlabel('distance, nm')
    ylabel('pdf')
    print('-dpng', sprintf('%s_%s.png', ex{1}.desc, ex{2}.desc));
end

fprintf('Summary:\n')
fprintf('Cut off: %d\n', s.cutOff);
fprintf('CA correction: %d\n', s.CA);
fprintf('\n');
for kk=1:numel(ex)
    fprintf('\n');
    fprintf('%d\t %s\n', kk, ex{kk}.description);
    fprintf('\t # pairs: %d\n', size(ex{kk}.A,1))
    fprintf('\t Mean: %f\n', mean(ex{kk}.d));
end

