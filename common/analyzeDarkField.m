I = df_readTif('dapi_001.tif');

minI = min(I(:)); maxI = max(I(:));
fprintf('Directory: %s\n', pwd());
fprintf('Image size: %d x %d x %d\n', size(I));
fprintf('Min: %f max: %f\n', minI, maxI);

mi = squeeze(min(min(I)));
me = squeeze(mean(mean(I)));
ma = squeeze(max(max(I)));

%% See what happens in z by plotting the min, mean and max for each slice
figure,
plot(mi, 'k')
hold on
plot(me, 'b:')
plot(ma, 'r')
legend({'min', 'mean', 'max'})
xlabel('Slice')
ylabel('Intensity')
ax = axis;
ax(3) = 0;
ax(1) = 1;
ax(2) = size(I,3);
axis(ax)
title('Flicker?')

%% Se what happens in x by plotting the min, mean and max for each slice
figure,
plot(squeeze(mean(mean(I, 2), 3)), 'k')
legend({'mean'})
xlabel('Slice')
ylabel('Intensity')
hold on
plot(squeeze(mean(mean(I, 1), 3)), 'r')
legend({'mean'})
xlabel('Slice')
ylabel('Intensity')
ax = axis;
ax(1) = 1;
ax(2) = size(I,1);
axis(ax)
legend({'Mean along x', 'Mean along y'})

%% See if the response is flat in x and y by looking at the z-projections
figure,
s=sum(I,3);
imagesc(s)
set(gca, 'clim', size(I,3)*percentile16(uint16(s/size(I,3)), [.01, .99]));
colorbar
title(sprintf('sum projection [%d, %d]', min(s(:)), max(s(:))))

%% As before but here Gaussian kernel is used to smooth the output
figure,
imagesc(gsmooth(s, 4)./gsmooth(ones(size(s)), 4));
colormap gray
colorbar
title('Averaged sum projection, sigma = 4');

%% Plot the distribution of pixel values and see how they look
figure
h = histo16(I);
d = 0:numel(h)-1;
plot(d,h);
title('Distribution of pixel values');
axis([percentile16(I, [0.01,0.99]), 0, max(h(:))])

emin = 10^100;
amaxh = find(h==max(h(:)),1);

for ss = linspace(5,25,1000)

n = normpdf(double(d), amaxh, ss);
n=n/max(n(:))*max(double(h(:)));
e = sum( (n'-double(h)).^2);
if e<emin
    emin = e;
    ssmin = ss;
end
end

n = normpdf(double(d), amaxh, ssmin);
n=n/max(n(:))*max(double(h(:)));
sum( (n-d).^2)

hold on
plot(d,n, 'r-')
legend({'histogram', 'fitted gaussian'})
title(sprintf('Distribution of pixel values, sigma=%3.1f', ssmin));

%% Subtract the xy average from each slice and see if the distribution 
% is tighter
Id = double(I);
s=sum(Id,3)/size(Id,3);
s = gsmooth(s, 4)./gsmooth(ones(size(s)), 4);
J = Id-repmat(s, [1,1,size(Id,3)]);
J = J+mean(Id(:));
J = uint16(J);

figure
h = histo16(J);
d = 0:numel(h)-1;
plot(d,h);

axis([percentile16(J, [0.01,0.99]), 0, max(h(:))])
% The distribution looks poissonian, not gaussian, could be combination

emin = 10^100;
amaxh = find(h==max(h(:)),1);

for ss = linspace(5,25,1000)

n = normpdf(double(d), amaxh, ss);
n=n/max(n(:))*max(double(h(:)));
e = sum( (n'-double(h)).^2);
if e<emin
    emin = e;
    ssmin = ss;
end
end

n = normpdf(double(d), amaxh, ssmin);
n=n/max(n(:))*max(double(h(:)));
sum( (n-d).^2)

hold on
plot(d,n, 'r-')
legend({'histogram', 'fitted gaussian'})
title(sprintf('Distribution of pixel values, sigma=%3.1f', ssmin));
