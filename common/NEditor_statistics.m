

disp(['Status for ' pwd]);

%% Count number of nuclei
files = dir('*.NM');

nnuclei = 0;
for kk = 1:numel(files)
    load(files(kk).name, '-mat');
    nnuclei = nnuclei + numel(N);
end

if numel(files)>0
    fprintf('Number of images: %d\n', numel(files));
    fprintf('Number of segmented cells: %d\n', nnuclei); 
else
   fprintf('! Can''t count the number of images \n or the number of segmented cells because no .NM-files were found in this folder\n');
end
    
%% Read all csv files into a table, T
files = dir('*.csv');
clear T
for kk = 1:numel(files)
    t = readtable(files(kk).name);
    if exist('T', 'var')
        T = [T; t];
    else
        T = t;
    end
end

if ~exist('T', 'var')
    disp('No dots extracted with NEditor')
else

%% Dots per cell
HC = zeros(100,1);
nCells = 0;
startPos = 1;
A = getCell(T, startPos);
while numel(A)>0
    nCells=nCells+1;
    HC(size(A,1)) = HC(size(A,1))+1;
    startPos = startPos+size(A,1);
    A = getCell(T, startPos);
end

ind = find(HC>0);
HC = HC(1:ind(end));
fprintf('\nNumber of cells: %d\n', nCells);
disp('#Dots #cells')
disp([(1:numel(HC))' HC])

%% Dots per allele
HA = zeros(100,1);
nAlleles = 0;
startPos = 1;
A = getAllele(T, startPos);
while numel(A)>0
    nAlleles=nAlleles+1;
    HA(size(A,1)) = HA(size(A,1))+1;
    startPos = startPos+size(A,1);
    A = getAllele(T, startPos);
end

ind = find(HA>0);
HA = HA(1:ind(end));
fprintf('\nNumber of alleles: %d\n', nAlleles);
disp('#Dots #alleles')
disp([(1:numel(HA))' HA])
end
