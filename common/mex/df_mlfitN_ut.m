function df_mlfitN_ut(varargin)

doCompile = 0;
doPlot = 0;

if doCompile
mex  df_mlfitN.c CFLAGS='-g $CFLAGS -std=c99 `pkg-config gsl --cflags --libs`' COPTIMFLAGS='-g -O3 -D verbose=0' ...
LINKLIBS='$LINKLIBS -lgsl -lgslcblas' mlfit.o blit3.o gaussianInt2.o
end

disp('  no input')
error = false;
try
    df_mlfitN();
catch e
    %disp('  the expected error generated for no input')
    error = true;
end
assert(error)

disp('  wrong input type')
error = false;
try
    df_mlfitN(double(1));
catch e
    %disp('expected error generated for wrong type of input')
    error = true;
end
assert(error)

disp('  Correct localization, 1 dot');
P = [8,8,8 , 1000, 1.5, 1.5, 1.7];
V = df_blit3(0*ones(15,15,15), [], P');
F = df_mlfitN(V, P');
assert(eudist(P(1:3), F(1:3)')<1e-3);

P = [7,8,8 , 1000, 1.5, 1.5, 1.7];
V = df_blit3(0*ones(15,15,15), [], P');
F = df_mlfitN(V, P');
assert(eudist(P(1:3), F(1:3)')<1e-3);

P = [8,7,8 , 1000, 1.5, 1.5, 1.7];
V = df_blit3(0*ones(15,15,15), [], P');
F = df_mlfitN(V, P');
assert(eudist(P(1:3), F(1:3)')<1e-3);

P = [8,8,7 , 1000, 1.5, 1.5, 1.7];
V = df_blit3(0*ones(15,15,15), [], P');
F = df_mlfitN(V, P');
assert(eudist(P(1:3), F(1:3)')<1e-3);


P = [5,5,5 , 15, 1.0, 1.1, 1.2];
V = df_blit3(0*ones(15,15,15), [], P');
V = V/max(V(:))*15;
F = df_mlfitN(V, P');
assert(eudist(P(1:3), F(1:3)')<1e-3);


disp('  Correct localization, 2 dots -- when start guess = final');
P = [5,5,5 , 15, 1.0, 1.1, 1.1; 
     7,7,7 , 15, 1.1, 1.1, 1.1];
V = df_blit3(zeros(15,15,15), [], P',2);
F = df_mlfitN(V, P');
assert(eudist(P(1,1:3), F(1:3,1)')<1e-3);
assert(eudist(P(2,1:3), F(1:3,2)')<1e-3);

if 0
P2 = P;
P2(1:2,1:4) = F(1:4,1:2)';
V2 = df_blit3(zeros(15,15,15), [], P2',2);
end


disp('  Correct localization, 2 dots -- when start pos guess != final');
P = [5.1,5,5 , 15, 1.0, 1.1, 1.1; 
     7,6.9,7 , 15, 1.1, 1.1, 1.1];
Pguess = [5  ,5, 5 , 15, 1.0, 1.1, 1.1; 
          7, 7.0, 7 , 15, 1.1, 1.1, 1.1];
V = df_blit3(zeros(15,15,15), [], P',2);
F = df_mlfitN(V, Pguess');
assert(eudist(P(1,1:3), F(1:3,1)')<1e-3);
assert(eudist(P(2,1:3), F(1:3,2)')<1e-3);

disp('  Correct localization, 2 dots -- when start intensity guess != final');
P = [5.1,5,5 , 15, 1.0, 1.1, 1.1; 
    7,6.9,7 ,  10, 1.1, 1.1, 1.1];
Pguess = [5  ,5,5 , 10, 1.0, 1.1, 1.1; 
          7,7.0,7 , 15, 1.1, 1.1, 1.1];
      
V = 100*df_blit3(zeros(15,15,15), [], P',2);
F = df_mlfitN(V, Pguess');
assert(eudist(P(1,1:3), F(1:3,1)')<1e-3);
assert(eudist(P(2,1:3), F(1:3,2)')<1e-3);

disp('  Correct localization, 2 dots -- with background');
P =      [5.1, 5, 5 , 15, 1.0, 1.1, 1.1; 7, 6.9, 7 , 15, 1.1, 1.1, 1.1];
Pguess = [5  , 5, 5 , 15, 1.0, 1.1, 1.1; 7, 7.0, 7 , 15, 1.1, 1.1, 1.1];
V = 100+100*df_blit3(zeros(15,15,15), [], P',2);
F = df_mlfitN(V, Pguess');
assert(eudist(P(1,1:3), F(1:3,1)')<1e-3);
assert(eudist(P(2,1:3), F(1:3,2)')<1e-3);

disp('  right size of output')

disp('  timing in a realistic case')
P = [ 5,    5,  5,    15, 1.0, 1.1, 1.1
      7,    7,  7,    15, 1.1, 1.1, 1.1
      9,  9.2,  9,    15, 1.0, 1.1, 1.1
     11,   11, 11,    15, 1.0, 1.1, 1.1
      7,    7,  15,    15, 1.1, 1.1, 1.1];
  
ndots = 2:5;
for kk = 1:numel(ndots)
    nd = ndots(kk);
    
    V = df_blit3(zeros(30,30,30), [], P(1:nd,:)',2);
  
    tic
        F = df_mlfitN(V, P(1:nd,:)'); F = F';
    tfit(kk) = toc;
    
end

fprintf('   #dots, time (s)\n');
for kk=1:numel(ndots)
    fprintf('    %2d %.3f\n', ndots(kk), tfit(kk));
end

if doPlot % Test on real data
    fName = '/data/current_images/iMB/iMB36_290416_001/a594_001.tif';
    fprintf('Reading %s\n', fName);
    V = df_readTif(fName);
    V = double(V);
    % Interesting nuclei with two super strong dots
    V = V(1:100, 400:512,:);
    D = dot_candidates(V);
    dotterSlide(V, D([12,14], :));
    F = df_com3(V, D(:,1:3)', 1)';
    
    D(:,1:3) = F; % Replace integer coordinates with fitted
    
    dotterSlide(V,D); % manually detect clustered dots
    %D = D(D(:,4)>4, :);
    D = D([12,14], :);
    whos D
         dotterSlide(V, D)
    F2 = df_mlfitN(V, [D(:,1:3), ones(size(D,1),1), 1.26*ones(size(D,1),2), 1.26*1.3*ones(size(D,1),1)]');
    
    dotterSlide(V, F2')
    
end

disp('  with noise -- TODO')

end
