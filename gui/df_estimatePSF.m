function PSF = df_estimatePSF()
folder = df_getConfig('df_estimatePSF','folder', './');

[file, folder] = uigetfile([folder '*.tif']);

df_setConfig('df_estimatePSF','folder', folder);

fName = [folder file];

fprintf('Reading\n%s\n', fName);
I = df_readTif(fName);

channel = df_channelsFromFileNames(file);

s = dotCandidates('getDefaults', 'channel', channel);
d = dotCandidates('Image', I, 'settings', s);

f = figure;
h = histogram(d(:,4));
th = dotThreshold(d(:,4));

disp('Close the window and enter threshold value afterwards')
uiwait(f)
th = inputdlg('Enter threshold value', 'Threshold selection', 1, {num2str(th)});

th = str2num(th{1}); 

fprintf('Threshold: %f.1\n', th);
fprintf('%d/%d dots\n', sum(d(:,4)>th), size(d,1));
D = d(d(:,4)>th,:);

ndots = size(d,1);

separation = 7;

while ndots>10

uni = getSeparated(I, D, separation);
ndots = numel(uni);
fprintf('separation: %d pixels: %d dots\n', separation, ndots);

separation = separation + 1;
end

separation = separation - 2;
fprintf('Selecting separation: %d dots\n', separation);
uni = getSeparated(I, D, separation);

save temp.mat
PSF = estimatePSF(I, uni, 'side', separation, 'symmetric', 0);

end


function D2 = getSeparated(I, D, separation)
D2 = D;

% too close to z border
D2 = D2(D2(:,3)>separation, :);
D2 = D2(D2(:,3)<size(I,3)-separation, :);

fprintf('Finding isolated dots\n');

[c,~] = cluster3e(D2(:,1:3), 2*separation);
h = df_histo16(uint16(c));
h = h(2:end);
uni = find(h==1);

D2 = D(ismember(c,uni),:);

end
