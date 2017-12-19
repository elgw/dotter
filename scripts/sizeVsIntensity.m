
folder = '/Users/erikw/data/290113/290113_samplesOF280113/4/';
files = dir([folder '*twocolor']);
addpath('../dotter')
addpath('../deconv/')


for kk = 1:numel(files) %% Per file
 
    numOkNuclei = 0;
    F = [];
    load([folder files(kk).name], '-mat')
    
    mask = M.mask;
    idapi = df_readTif(M.dapifile);    
    %idapid = deconvW3(double(idapi), PSF);
  
    
    ic1 = df_readTif(M.c1file);
    ic2 = df_readTif(M.c2file);
    
    c1dots = N{kk}.c1dots;
    %c1dots = c1dots(1:40,:);
    
    fittingSettings.sigmafitXY = 1;
    fittingSettings.sigmafitZ = 1;
    fittingSettings.useClustering = 1;
    fittingSettings.clusterMinDist = 2*fittingSettings.sigmafitXY;
    fittingSettings.fitSigma = 1;
    fittingSettings.verbose = 0;   
    
    c1fit = dotFitting(double(ic1), c1dots, fittingSettings);
    ok = c1fit(:,7)==0;
    
    plot(c1dots(ok, 4), c1fit(ok, 6), 'x')
    xlabel('Intensity')
    ylabel('Sigma')
    
    dotterSlide(ic1, c1fit)
end

