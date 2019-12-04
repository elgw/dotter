%% Dots, One, Two, ...

function strongestDots()

%% The strongest dots
% selecting the strongest dots in each nuclei for further analysis

% publish('strongest_dots_170828', 'pdf')
close all
clear all

savefigs = 1; % produce pdfs
calcfwhm = 1; %
reuseMAT = 0; % use saved .mat if available

if 0
    folder = '/data/current_images/iEG/iEG264_271016_002_calc/';
    dapiThres = 2.5*10^9;
    dotThres = 10;
    desc = 'Cy5-iEG264-002';
end

if 1
    folder = '/data/current_images/iEG/iEG120_310116_001_calc/';
    dotThres = 3;
    dapiThres = 8.5*10^9;
    desc = 'Cy5-iEG120-001';
    fwhma = 2.17;
    fwhmb = 4.48;
end
% This data set is labelled with 1 probe in cy5
% The chance of overlapping dots is hence very low

% * Can estimate the binding probability for a single kmer be estimated
%   from the distribution of the intensities?

% Description string for the plots

sname = [desc '.mat'];
if exist(sname, 'file') && reuseMAT
    disp(['Loading ' sname]);
    load(sname)
else
    disp('Loading dots into structures');
    files = dir([folder '*.NM']);
    
    values = [];
    dValues = []; % 100 strongest dots per nuclei
    allDots = [];
    DAPI = [];
    
    fDAPI = [];
    
    for kk = 1:numel(files)
        D = load([folder files(kk).name], '-mat');
        M = D.M;
        N = D.N;
        
        avgDAPI = []; % Get average DAPI for all G1 nuclei in the field
        for nn = 1:numel(N)
            ND = N{nn}.dapisum;
            if ND <dapiThres
                avgDAPI = [avgDAPI, ND];
            end
        end
        
        avgDAPI = mean(avgDAPI);
        fDAPI = [fDAPI; avgDAPI];
        
        
        % Read in the cy5 tif image, used for fwhm calculations
        cy5V = df_readTif(M.channelf{1});
        
        for nn = 1:numel(N)
            allDots = [allDots ; N{nn}.dots{1}];
            DAPI = [DAPI, N{nn}.dapisum];
            if N{nn}.dapisum < dapiThres;
                
                d = N{nn}.userDots{1}; % Two strongest selected already
                dAll = N{nn}.dots{1};
                
                % get distance to periphery
                [dPer, dPerN, M] = df_dPeriphery(M, d);
                dPer = dPer(1:2); dPerN = dPerN(1:2);
                dPer = reshape(dPer, [1,2]);
                dPerN = reshape(dPerN, [1,2]);
                
                % get fwhm for cy5
                if calcfwhm
                    fwhm = df_fwhm(cy5V, d);
                else
                    fwhm = [0,0,0];
                end
                fwhm = fwhm(1:2);
                fwhm = reshape(fwhm, [1,2]);
                
                if numel(d)>0
                    v = d(:,4)';
                    if numel(v) == 1
                        v = [v nan];
                    end
                    if numel(v) == 2
                        v = [v nan];
                    end
                    values = [values; ...
                        [v    kk nn N{nn}.dapisum, avgDAPI, dPer, dPerN, fwhm]];                    
                    %1-3, 4, 5, 6,             7,       8-9,  10-11, 12-13      
                                        
                    
                    if 0% size(dAll,2)>5 % fwhm available
                        t = dAll(:,6);
                        use = 0*t;
                        %keyboard
                        use((t>fwhma & t<fwhmb) | t==-1) = 1;
                        %keyboard
                        dd = dAll(use==1,4);
                        if numel(dd)>100
                            dd = dd(1,1:100);
                        end
                        dd(100)=0;
                        dd= reshape(dd, [1,numel(dd)]);
                        values(end,1:2) = dd(1:2); % Replace strongest two
                    else                                         
                        dd = dAll(:,4)';
                    end
                    if numel(dd)>100
                        dd = dd(1,1:100);
                    end
                    dd(numel(ones(100,1))) = 0;
                    
                    dValues = [dValues; dd];
                end
            end
        end
    end
    % values does now contain the values of the two strongest dots
    % for the G1-cells.
    
    assignin('base', 'allDots', allDots);
    assignin('base', 'dValues', dValues);
    disp(['Saving to ' sname]);
    save(sname)
end

fprintf('%d fields of view, %d nuclei\n', numel(files), size(values,1));

%% DAPI
% Description: Showing dapi from all nuclei
%
% Result: Set a threshold based on this which is marked in the figure.

figure
histogram(fDAPI, numel(fDAPI))
xlabel('DAPI');
ylabel('#')
title('Average G1-nuclei DAPI, per field')

figure
histogram(DAPI, linspace(0, max(DAPI), 75))
xlabel('DAPI sum')
ylabel('#');
hold on
vLine(dapiThres);
legend({desc, sprintf('DAPI threshold: %.2e', dapiThres)});
title('DAPI per nuclei')


figure
subplot(1,2,1)

G1DAPI = values(:,6);
histogram(G1DAPI, linspace(0, max(DAPI), 75))
xlabel('DAPI sum')
ylabel('#');
hold on
vLine(dapiThres);
title('G1 DAPI per nuclei')
subplot(1,2,2)
G1DAPI_N = values(:,6)./values(:,7)*mean(fDAPI);
histogram(G1DAPI_N, linspace(0, max(DAPI), 75))
xlabel('DAPI sum')
ylabel('#');
hold on
vLine(dapiThres);

title('G1 DAPI per nuclei - normalized')

std(G1DAPI)
std(G1DAPI_N)


%% Some analysis

v = values(:,1:2);
v = (v>dotThres);
nDots = sum(v,2);
p = [sum(nDots==2), sum(nDots==1), sum(nDots==0)];
fprintf('Nuclei with 2 dots: %d, 1: dot: %d, no dots: %d\n', p(1), p(2), p(3));

pp = p/sum(p); %normalized probability
% Find the probability that minimizes the l2-norm
optimP = @(a) norm([a^2 2*a*(1-a) (1-a)^2]-pp);
a = fminsearch(optimP, .5)

%a = sqrt(pp(1)) % binding probability



% The binomial distribution does only have one parameter so it is unlikely
% that it will fit perfectly. However it should fit quite well if these
% events are INDEPENDENT

fprintf(['Just caring about the probability of two dots,\n' ...
    'and treating the first and second dots as independent events \n' ...
    'the probability for each probe to bind is %d\n'], a);

aa = [a^2 2*a*(1-a) (1-a)^2];

fprintf('This gives the following numbers:\n')
fprintf('       Observed, Predicted\n');
NN  = size(values,1); %Number of nuclei
for kk = 1:3
    fprintf('%d dots: %.2d (%.0f) %.2d (%.0f)\n', 3-kk, pp(kk), NN*pp(kk), aa(kk), NN*aa(kk));
end

fprintf('L2-error: %.2f\n', norm(pp-aa))

% Hypothesis: a few nuclei are not accepting probes. By removing a fraction
% of these we can get a good fitting.

thVsP(dValues);
defunctNuclei(p)



% For iEG264 this was true.
% fprintf(['The discrepancy can be interpreted as having already one\n', ...
%         'dot increases the chance to get another one\n'])

%% Distribution of the two strongest dots

% save('iEG120_values.mat', 'values');


%% The intensity of all nuclei dots
% Description: Initially, 10000 dots were extracted for each field of view
% only the dots within segmented nuclei are used here
%
% Result: assuming that the background dots are the big mountain, a threshold
% around 10 seems resonable. I verified this visually, using setUserDotsDNA.

figure,
histogram(allDots(:,4))
xlabel('strength')
ylabel('#')
title('All nuclei dots');
mh = axis();
vLine(dotThres);
legend({desc, sprintf('DOT threshold: %.2e', dotThres)});

figure, % with log scale for y
histogram(allDots(:,4))
xlabel('strength')
ylabel('#')
title('All nuclei dots');
mh = axis();
vLine(dotThres);
legend({desc, sprintf('DOT threshold: %.2e', dotThres)});
set(gca, 'YScale', 'log')

if savefigs
    dprintpdf('allDots.pdf');
end

%% Histogram of the strongest dots for each nuclei
% Description: Only using G1 cells as defined by the threshold above.
%
% Result: The strongest dots does not follow a binimial distribution at
% all. Could it be that some probes does not bind at all, and that those
% that bind follow a binomial distribution?

figure
edges = linspace(-.5, max(values(:,1))+.5, 21);
histogram(values(:,1), edges)
title('strongest dot per nuclei')
legend(desc)
% histogram of the second strongest dots
vLine(dotThres);
if savefigs
    dprintpdf([desc 'first.pdf'])
end

figure
histogram(values(:,1)./values(:,6)*mean(values(:,6)), edges)
title('strongest dot per nuclei, DAPI-normalized per nuclei')
legend(desc)
% histogram of the second strongest dots
vLine(dotThres);
if savefigs
    dprintpdf([desc 'first_dapiN.pdf'])
end



figure
histogram(values(:,1)./values(:,7)*mean(values(:,7)), edges)
title('strongest dot per nuclei, DAPI-normalized per field')
legend(desc)
% histogram of the second strongest dots
vLine(dotThres);
if savefigs
    dprintpdf([desc 'first_dapiF.pdf'])
end

figure
histogram(values(:,2), edges)
title('second strongest dot per nuclei')
legend(desc)
vLine(dotThres);
if savefigs
    dprintpdf([desc 'second.pdf'])
end
% third
figure
histogram(values(:,3), edges)
title('third strongest dot per nuclei')
legend(desc)
vLine(dotThres);
if savefigs
    dprintpdf('third.pdf')
end

%% Histogram of the mean of the two strongest dots per nuclei
% Description:
% Result:

figure
histogram(sum(values(:,1:2),2)/2, edges)
title('mean of two strongest dots per nuclei')
xlabel('strength')
ylabel('#');
vLine(dotThres);
if savefigs
    dprintpdf('allSum.pdf')
end
legend(desc)

%% Strongest two in the same plot
% Description: Same as above, easier to compare when they are shown together
figure
histogram(values(:,1), edges)
hold on
histogram(values(:,2), edges)
hold on
histogram(values(:,3), edges)
vLine(dotThres);
title('two strongest dots per nuclei')
if savefigs
    dprintpdf('all2.pdf')
end
legend({'1st', '2nd', '3rd'})


figure,
histogram(values(:,1:2), linspace(-.5, 99.5, 100));
xaxis([-.5, 60])
dprintpdf([desc 'strongest2.pdf'])



%% Strongest vs second strongest dot, one dot per nuclei
% Description: shown as a scatterplot
figure
scatter(values(:,1), values(:,2))
axis([0, max(values(:,1)), 0, max(values(:,2))])
grid on
xlabel('strongest')
ylabel('second strongest')
legend(desc)
vLine(dotThres);
hLine(dotThres);
title(sprintf('%d nuclei', size(values,1)))
if savefigs
    dprintpdf('scatter12.pdf')
end

%% Second vs third strongest dot, one dot per nuclei
% Description: shown as a scatterplot
figure
scatter(values(:,2), values(:,3))
axis([0, max(values(:,2)), 0, max(values(:,3))])
grid on
ylabel('third strongest')
xlabel('second strongest')
legend(desc)
title(sprintf('%d nuclei', size(values,1)))
if savefigs
    dprintpdf('scatter23.pdf')
end


%% Distance to periphery
figure
histogram(values(:,8))
title('Distance to periphery for strongest dots')
figure
D = linspace(0,1, size(values,1)/4);
histogram(values(:,10), D)
title('Normalized distance to periphery for strongest dots')

figure
histogram(values(:,9))
title('Distance to periphery for second strongest dots')

figure
histogram(values(:,11), D)
title('Normalized distance to periphery for second strongest dots')

try
    %% FWHM
    figure
    scatter(values(:,1), values(:,12))
    xlabel('Strength');
    ylabel('FWHM');
    title('Strongest dots')
    axis([0,max(max(values(:,1:2))), 0, max(max(values(:,12:13)))]);
    vLine(dotThres)
    if savefigs
        dprintpdf([desc '-fwhm-1st.pdf'])
    end
    
    figure
    scatter(values(:,2), values(:,13))
    xlabel('Strength');
    ylabel('FWHM');
    title('Second Strongest dots')
    axis([0,max(max(values(:,1:2))), 0, max(max(values(:,12:13)))]);
    vLine(dotThres);
    if savefigs
        dprintpdf([desc '-fwhm-2nd.pdf'])
    end
end

%% DAPI vs strength
% Description:
%  DAPI means the sum of the pixel values of the segmented nuclei
%
% Result: Looking at the strongest dot, only the DAPI rich nuclei have really
%  bright dots

figure
scatter(values(:,1), values(:,6))
xlabel('Strongest dot');
ylabel('DAPI');
legend(desc)
grid on
if savefigs
    dprintpdf('first_vs_dapi.pdf');
end

% second
figure
scatter(values(:,2), values(:,6))
xlabel('2nd strongest dot');
ylabel('DAPI');
legend(desc)
grid on
if savefigs
    dprintpdf('second_vs_dapi.pdf');
end

% third
figure
scatter(values(:,3), values(:,6))
xlabel('3rd strongest dot');
ylabel('DAPI');
legend(desc)
grid on
if savefigs
    dprintpdf('third_vs_dapi.pdf');
end

%% Parallel coordinates
% Description:
%  Too see how intensity changes when going from 1st, to 2nd to 3rd ...
% Result:
%  Only a few curves have the ideal shape

figure
plot(values(:,1:3)')
a = gca;
a.XTick = [1, 2, 3];
a.XTickLabels = {'1st', '2nd', '3rd'};
hLine(dotThres);
ylabel('Strength')
title('Parallel coordinates for the three strongest dots')

    function vLine(x)
        hold on
        % put up a vertical line in the current axis
        mh = axis();
        plot([x,x], [mh(3), mh(4)]);
    end

    function hLine(y)
        hold on
        % put up a vertical line in the current axis
        mh = axis();
        plot([mh(1), mh(2)], [y,y]);
    end

    function defunctNuclei(ndots)
        figure
        P = ndots/sum(ndots(:));
        
        % Try exclude 0 up to all nuclei with 0 dots and figure out
        % the amount to remove to get a binimial distribution for the
        % remaining ones.
        for kk = 0:ndots(3)
            ndotsR = ndots;
            ndotsR(3) = ndotsR(3)-kk;
            
            Pp = sqrt(P(1)); % probqability for a probe to bind
            Pall = [Pp^2, 2*Pp*(1-Pp), (1-Pp)^2];
            e(kk+1) = norm(Pall-ndotsR/sum(ndotsR));
        end
        plot(0:size(e)-1, e)
        
        
        plot(0:(numel(e)-1), 1-e)
        xlabel('Number of inactive nuclei');
        ylabel('Correspondance with binimial model')
        
        def = find(e==min(e(:)))-1;
        fprintf('Model 1:\n');
        fprintf('If we consider %d nuclei non-functional (%.1f percent)\n', def, 100*def/sum(ndots));
        fprintf('The probability that a probe work is %.3f percent\n', 100*sqrt(ndots(1)/(sum(ndots)-def)));
        
        ndots1 = ndots-[0,0,def];
        ndots1P = ndots1/sum(ndots1);
        disp('Data probabilites');
        disp(ndots1P);
        p1 = sqrt(ndots1P(1));
        m1p = [p1*p1, 2*p1*(1-p1), (1-p1)*(1-p1)];
        disp('Model probabilites');
        disp(m1p);
        disp('Prediction')
        disp(m1p*sum(ndots1))
        disp('Actual counts')
        disp(ndots1);
        fprintf('l2-Error: %.2f\n', norm(ndots1P-m1p));
        
        fprintf('Model 2:\n')
        fprintf('If we assign individual probabilites to the probes to work\n')
        % Numerical method to find the optimal setting since the problem
        % usually can't be solved with real values
        
        
        diffProbMin = @(x) diffProb(x, ndots/sum(ndots));
        
        [ps, fval] = fminsearch(diffProbMin, [.5, .5]);
        
        p1 = ps(1); p2 = ps(2);
        fprintf('p1 = %.2f, p2 = %.2f\n', p1, p2);
        disp('Model probabilites')
        Pm2 = [p1*p2, p1*(1-p2) + p2*(1-p1), (1-p1)*(1-p2)];
        disp(Pm2);
        disp('Data probabilites')
        disp(ndots/sum(ndots));
        fprintf('l2-Error: %.2f\n', norm(Pm2-ndots/sum(ndots)));
        
    end

    function e = diffProb(x, P)
        
        p1 = x(1); p2 = x(2);
        if(p1<0)
            e = inf;
            return;
        end
        if(p2<0)
            e = inf;
            return;
        end
        e = norm([p1*p2, p1*(1-p2) + p2*(1-p1), (1-p1)*(1-p2)] - P);
    end

end

function thVsP(values)


threshold = linspace(0,max(values(:,1)), 1000);
thp = zeros(size(threshold));

for kk = 1:numel(threshold)
    dotThres = threshold(kk);
    v = values;
    v = (v>dotThres);
    nDots = sum(v,2);
    p = [sum(nDots==2), sum(nDots==1), sum(nDots==0)];
    
    pp = p/size(values,1); % normalized probability
    % Find the probability that minimizes the l2-norm
    optimP = @(a) norm([a^2 2*a*(1-a) (1-a)^2]-pp);
    [a,e] = fminsearch(optimP, .5);
    thp(kk) = a;
    l2(kk) = e;
end

close all

figure,
plot(threshold, thp)
hold on
plot(threshold, l2)
legend({'P', 'l2-error'});
xlabel('dot threshold');
axis([0,40,0,1])
grid on
%dprintpdf('thVSp_iEG120_001.pdf')
%dprintpdf('thVSp_iEG264_002.pdf')

% for iEG120
p40 = 8.92; % curve is .6
p60 = 17.8; % curve is .4

% for iEG264
p75 = 13.7; % curve is .25
p85 = 19.1; % curve is .4

[A, P] = meshgrid(10.^linspace(-3,log10(0.5)), linspace(0,0.07));

E = 0*A;
for mm =1:size(A,1)
    for nn = 1:size(A,2)
        a = A(mm,nn);
        p = P(mm,nn);
        %E(mm,nn) = norm(...
        %    [binocdf(round(a*p40), 96, p)-.4, ...
        %    binocdf(round(a*p60), 96, p)-.6]);
        E(mm,nn) = norm(...
            [binocdf(round(a*p75), 96, p)-.75, ...
            binocdf(round(a*p85), 96, p)-.85]);
    end
end

figure,
s = surface(A,P, E);
xlabel('Scaling')
ylabel('p')
s.EdgeColor = 'none';
%dprintpdf('p_scaling_iEG120_001.pdf')
%dprintpdf('p_scaling_iEG264_002.pdf')

end
