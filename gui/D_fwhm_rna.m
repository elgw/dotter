[file, folder] = uigetfile('*.tif');
V = df_readTif([folder file]);

volumeSlide(V);

D = dotCandidates(V);
s.useClustering= 1;
s.sigmafitXY= 1.5000;
s.sigmafitZ= 3;
s.fitSigma= 0;
s.verbose = 0;
s.clusterMinDist= 5;

F = dotFitting(V, D(1:512,:));
W = df_fwhm(V, F);

%% Show results
% Numerical
[yn,xn] = kdeParzen(131.05*W, [], [200,600], 5);
figure, 
plot(xn,yn,'LineWidth', 2)
hold all

% From gaussian fitting
[yg,xg] = kdeParzen(131.05*F(:,6)*2*sqrt(2*log(2)),  [], [200,600], 5);
plot(xg,yg,'LineWidth', 2)

nloc = find(yn==max(yn(:)));
nloc = nloc(1);
fprintf('Numerical: Peak at %3.2f\n', xn(nloc));

gloc = find(yg==max(yg(:)));
gloc = gloc(1);
fprintf('Gaussian : Peak at %3.2f\n', xg(loc));

legend({sprintf('Numerical (%d nm)', nloc), sprintf('Gaussian, (%d nm)', gloc)});

ptitle = strsplit(folder, '/');
ptitle = ptitle{end-1};
title(['FWHM: ' ptitle], 'Interpreter', 'none')
xlabel('Size, [nm]')
ylabel('density')
print('-dpng', ['fwhm_' ptitle '_' file(end-6:end-4) '.png']);
