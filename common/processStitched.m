% Process/analyze stitched images with no overlap.
%

if ~exist('I', 'var');
    I = df_readTif('/data/current_images/iMS/iMS96_20170227_003/DAPI_001.tif', 'verbose');
end

fwidth = 1024;
fheight = 1024;

width = size(I,2)/fwidth;
height = size(I,2)/fheight;

fprintf('%d x %d fields of %d stacks\n', width, height, size(I,3));

%% See if there are any trends in the fields
if 0 % will not work if the fields
S = zeros(width, height, width*height*size(I,3), class(I));
for kk = 1:width
    for ll = 1:height
    end
end
end

%% Look for local contrast
% Gradient magnitude, gm
Cx = gpartial(I, 1, 4);
Cy = gpartial(I, 2, 4);
gm = Cx.^2+Cy.^2;
clear Cx Cy

for kk = 1:size(gm,3)
    gm(:,:,kk) = gsmooth(gm(:,:,kk,100));
end

F = zeros(size(I,1), size(I,2));
for kk = 1:size(gm,3)
    kk
    F(gm(:,:,kk) == max(gm, [], 3)) = kk;
end

% Plot which slice is most in focus
figure
plot(squeeze(sum(sum(gm(:,:,1:5)))));
t = squeeze(sum(sum(gm(:,:,1:5))))
grid on
xlabel('z')
ylabel('focus [AU]')
dprintpdf('focusplot.pdf')