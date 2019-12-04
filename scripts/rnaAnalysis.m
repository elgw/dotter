[file, directory] = uigetfile('*.csv');

file = [directory file];

fprintf('File: %s\n', file);

T=readtable(file);

maxFWHM = 500;

DD = table2array(T);


D1=DD(DD(:,6)<0, :); % Dots in the nuclei
D2=DD(DD(:,6)>0, :); % Dots outside of the nuclei

fprintf('maxFWHM: %d nm\n', maxFWHM);
fprintf('%d dots in nuclei\n', size(D1,1));
fprintf('%d dots outside nuclei\n', size(D2,1));

% Remove those with a too high FWHM and no estimation of nPhotons

D1 = D1(D1(:,7)<maxFWHM, :);
D1 = D1(D1(:,7)>0, :);
D1 = D1(D1(:,8)>0,:);

D2 = D2(D2(:,7)<maxFWHM, :);
D2 = D2(D2(:,7)>0, :);
D2 = D2(D2(:,8)>0,:);



properties = {'DoG', 'FWHM', 'nPhotons'};
columns = [4 7 8];
sigmas = [10, 50, 1000];
maxVals = [200, 1000, 20000];

for kk = 1:numel(properties)
    [y1,x1] = kdeParzen(D1(:,columns(kk)), [], [0,maxVals(kk)], sigmas(kk));
    [y2,x2] = kdeParzen(D2(:,columns(kk)), [], [0,maxVals(kk)], sigmas(kk));
    
    figure
    plot(x1,y1, 'r', 'lineWidth', 2)
    hold on
    plot(x2,y2, 'b', 'lineWidth', 2)
    legend({[num2str(size(D1,1)) ' in nuclei'], ...
        [ num2str(size(D2,1)) ' outside nuclei']})
    title([directory(end-22:end-6) ': ' properties{kk}], 'interpreter', 'none')
    dprintpdf([directory properties{kk} '.pdf'])
end
