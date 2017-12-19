
% Quicktest
V = df_readTif('/data/current_images/iJC145_031215_001/a594_001.tif');
D = dotCandidates(V);
th = dotThreshold(D(:,4));
ndots = sum(D(:,4)>th);
D = D(D(:,4)>th, :);
F = dotFitting(V,D);
dotterSlide(V,F)
pause

% Quicktest 2
locations = linspace(50,200.5,11)';
locations = [locations locations];

W = zeros(212,212);
for kk = 1:size(locations,1)
    W = blitGauss(W, locations(kk,1:2), 1);
end

W = 100*W;

D = dotCandidates(W);
%th = dotThreshold(D(:,4));
%D = D(D(:,4)>=th, :);
D = D(1:11, :)
F = dotFitting(W, D);
dotterSlide(100*W,F)

figure,
imagesc(W)
axis image
hold on
colormap gray
plot(locations(:,2), locations(:,1), 'g<')
hold on
plot(F(:,2), F(:,1), 'rx')

Errors = sum([locations - F(:,1:2)].^2,2).^(1/2);
max(Errors)

