close all

%% Compare CC corrections from different timepoints

voxelSize = 1;
pixelUnit = 'pixels';

[file, fdir] = uigetfile('/data/current_images/cc/');
cc1File = [fdir file];
[file, fdir] = uigetfile('/data/current_images/cc/');
cc2File = [fdir file];

save compareCC.mat

cc1 = load(cc1File);
cc2 = load(cc2File);

chan1 = 'a488';%'a594'; % reference channel
chan2 = 'a594';%'tmr';

[X, Y] = meshgrid(0:50:1024, 0:50:1024);
P = [X(:), Y(:), 20*ones(size(X(:)))];

[J1, CxB1, CyB1, dzB1, E1] = cCorrI(P, chan2, chan1, cc1File);
[J2, CxB2, CyB2, dzB2, E2] = cCorrI(P, chan2, chan1, cc2File);

% delta = ||Ax-Bx||
delta = ( (J1(:,1)-J2(:,1)).^2+ (J1(:,2)-J2(:,2)).^2 ).^(1/2);
delta = reshape(delta, size(X));

figure
imagesc(delta*voxelSize)
title(sprintf('||Ax - Bx|| over the image field'))
axis off
axis image
h = colorbar;
xlabel(h, pixelUnit)
dprintpdf('images/axbx.pdf', 1);

% Visual comparison
figure,
quiver(X(:) ,Y(:), X(:)-J1(:,1), Y(:)-J1(:,2))
title(sprintf('%s %s -> %s', cc1File, chan1, chan2), 'interpreter', 'none')
axis equal
axis image

D = [X(:)-J1(:,1), Y(:)-J1(:,2)]; % displacement
De = zeros(size(D,1),1);
for kk = 1:size(D,1)
    De(kk) = norm(D(kk,:));
end

legend({sprintf('Max: %.2f pixels', max(De(:)))});
dprintpdf('images/quiver1.pdf', 1);

figure,
quiver(X(:) ,Y(:), X(:)-J2(:,1), Y(:)-J2(:,2))
title(sprintf('%s %s -> %s', cc2File, chan1, chan2), 'interpreter', 'none')
axis equal
axis image

D = [X(:)-J2(:,1), Y(:)-J2(:,2)]; % displacement
De = zeros(size(D,1),1);
for kk = 1:size(D,1)
    De(kk) = norm(D(kk,:));
end

legend({sprintf('Max: %.2f pixels', max(De(:)))});
dprintpdf('images/quiver2.pdf', 1);

%% Look at the polynomials in the cc2-files
% Model x' = A+Bx (linearization)

%[file, dir] = uigetfile('/data/current_images/cc/');
%cc2A = [dir file];
%dA = load(cc2A);

% Make sure that the cc2 files contains the same channels,
% no attempt is made to collect them


folder = '/data/current_images/cc/';
files = dir([folder 'cc2*.mat']);

swelling = [];

files = files([4,6]);

colors = 'rgb';

for kk = 1:numel(files)

    dA = load([folder files(kk).name]);
    dA.chan
    mid = [];
    for cc = 1:numel(dA.chan)
        cTo = cc;

        Cx = dA.Cx{cTo};
        Cy = dA.Cy{cTo};

        %
        A = [Cx(1) ; Cy(1)];
        B = [Cx(2), Cx(3) ; Cy(2) Cy(3)];
        %mid(cc,:) = inv(eye(2)-B)*A;

        % find min for ||f(x)-x|| instead

        % see cCorrI for how the polynomials are defined.
        afun2 = @(x) norm(sum([[Cx(1) + Cx(2)*x(1) + Cx(3)*x(2) + Cx(4)*x(1)*x(1) + Cx(5)*x(1)*x(2) + Cx(6)*x(2)*x(2)] , ...
                              [Cy(1) + Cy(2)*x(1) + Cy(3)*x(2) + Cy(4)*x(1)*x(1) + Cy(5)*x(1)*x(2) + Cy(6)*x(2)*x(2)]] - [x(1), x(2)]));

        afun = @(x) norm(([poly2mat(x, 3)*Cx, poly2mat(x, 3)*Cy] - x));
        mid(cc,:) = fminsearch(afun, [512,512]);

        swell = 1/mean(diag(B));
        swelling(kk,cc) = swell;
        %fprintf('Channel: %s\n', dA.chan{cc});
        %fprintf('0-point: [%f, %f]. Swelling: %f\n', mid(1), mid(2), swell);
        % Also max displacement can be calculated
    end

    %plot(mid(1,1), mid(1,2), [colors(kk) 'o'])
    %plot(mid(:,1), mid(:,2), colors(kk))
    mids{kk} = mid;
end

figure,
hold on
for kk = 1:numel(mids)
    plot(mids{kk}(2:end,1), mids{kk}(2:end,2), colors(kk))
end

title('drifting centre a488(''o'')->a594->a647->dapi->tmr')
xlabel('x')
ylabel('y')
legend({files.name}, 'interpreter', 'none');
for kk = 1:numel(mids)
    plot(mids{kk}(2,1), mids{kk}(2,2), [colors(kk) 'o'])
end

%legend({'iEG296_004', 'iEG298', 'iEG296_003'}, 'interpreter', 'none', 'location', 'southwest')
axis equal
dprintpdf('images/drift.pdf', 1);

f = figure
hold on
plot(mean(swelling,1), 'k')

for kk = 1:size(swelling,1)
    for ll = 1:size(swelling,2)
       plot(ll, swelling(kk, ll), [colors(kk) 'o']);
    end
end

legend('mean')

a = gca;
set(a, 'XTick', 1:numel(dA.chan));
set(a, 'XtickLabel', dA.chan);

title('Relative magnification')
xlabel('target channel')
ylabel('magnification')
dprintpdf('images/magni.pdf', 1);

% hold on, plot(mids{1}(2,1), mids{1}(2,2), 'ro')
% hold on, plot(mids{2}(2,1), mids{2}(2,2), 'go')
