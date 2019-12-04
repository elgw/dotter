%% Strategy for clustering of dots within nuclei

%{

. Use the first N dots from all channels to build the clusters (=homologs)
. Visualise per nuclei
. Try 2-means (kmeans) and gaussian mixture
. Set up an assignment routine that associates the correct number of dots
to each cluster
. Validation routine.

. If the clustering above does not work (due to the lack of circular
symmetry or bad resemblance to a trivariate normal distribution, try
another heuristics. Possibly based on shortest distances - pair points
based on shortest distance. Increase the distance threshold until only one
cluster. Go back till where there are two. Analyse volume of these.

%}

% include dapi-val in plot
%close all

wfolder = '/Users/erikw/data/310715_calc/';
files = dir([wfolder '*NM']);

fileno = 4;

load([wfolder files(fileno).name], '-mat')
M.nTrueDots = [3,4,5];
figure,
w = ceil(sqrt(numel(N)));
h = ceil(numel(N)/w);

for n = 1%:numel(N)
subplot(w,h,n)
    
nN = N{n};

%imagesc(M.mask)
contour(M.mask, .5*[1,1], 'k')
hold on
axis(nN.bbx([3,4,1,2]))

dots = [];
for kk = 1:3
    cdots = nN.dots{kk};
    cdots = cdots(1:M.nTrueDots(1)*2, :);
    dots = [dots; cdots];
end

    cidx = kmeans(dots,2);
    dotsA = dots(cidx==1,:);
    dotsB = dots(cidx==2,:);
    
    if abs(sum(cidx==1)-sum(cidx==2)) < 20
    plot3(dotsA(:,2), dotsA(:,1), dotsA(:,3),'ro')
    plot3(dotsB(:,2), dotsB(:,1), dotsB(:,3),'bo')
    else
        plot3(dots(:,2), dots(:,1), dots(:,3), 'ko')
    end
    title(sprintf('%d', N{n}.dapisum<dapival));

end