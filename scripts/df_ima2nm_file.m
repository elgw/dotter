function df_ima2nm_file(imafile, nmfile, outFolder)
% Import dots from .ima-files, i.e., that
% are produced by ImageM

% SERVER>projects>iFISH>FOR REVISION

%{
                        stack_range: [1 65]
                             status: [1×1 struct]
                                  N: 15
                              sigma: 1.5000
                          Cy5_SIGMA: 6
                         A594_SIGMA: 4
                          TMR_SIGMA: 8.5000
                             MARGIN: 10
                          Cy5_shift: [0 0]
                         A594_shift: [0 0]
                          TMR_shift: [0 0]
                       n_thresholds: 100
                  auto_thresholding: [1×1 struct]
                  projection_method: 'max'
                     enhance_method: 'imadjust'
                               cell: [1×9 struct]
                               dots: [677×5 double]
                       nuclear_dots: []
                                  I: [1024×1024 double]
                                 I2: [1024×1024 double]
                                 I3: []
                              scale: [1 1]
                         image_size: [1024 1024 65]
                          save_path: '/Users/magdabienko/Desktop/'
                          save_name: 'ieg642_310119_001.001.ima'
                                 BW: []
                               RECT: []
                          reference: [1024×1024 double]
                           skeleton: []
                       channel_name: {'Cy5_'  'a594_'  'ir800_'  'tmr_'}
               nuclear_channel_name: []
               num_dot_cell_channel: [9×4 double]
    num_dot_cell_channel_normalized: []
                            outline: []
                          neighbors: []
                            version: 2
                               name: 'a594_001.tif'
                               path: '/Users/magdabienko/Desktop/ieg642_310119_001/'
                         file_index: '001'
                      current_stack: 1
       num_nuclear_dot_cell_channel: [9×0 double]
                  full_channel_name: {'Cy5_'  'a594_'  'ir800_'  'tmr_'}
%}


%imafile = '/home/erikw/data/current_images/iEG/ieg642_001_ima/ieg642_310119_001.001.ima';
%nmfile = '/home/erikw/data/current_images/iEG/ieg642_310119_001_calc/001.NM';

D = load(imafile, '-mat'); % Domain
T = load(nmfile, '-mat'); % Target

%% Dot detection
fprintf('-> DOT DETECTION\n');
fprintf('sigma=%f\n', D.UserData.sigma)
fnames = fieldnames(D.UserData);
for kk = 1:numel(fnames)
  if numel(strfind(fnames{kk}, 'SIGMA')) == 1
      fprintf('%s=%f\n', fnames{kk}, D.UserData.(fnames{kk}));
  end
end
%Cy5_SIGMA: 6
%A594_SIGMA: 4
%TMR_SIGMA: 8.5000

%% Channels
fprintf('-> Verifying that the channels are the same\n');
% Note that the names does not have the same cases as the _SIGMA fields
% Remove trailing '_'
% D.UserData.channel_name
for kk = 1:numel(D.UserData.channel_name)
    cima = D.UserData.channel_name{kk};
    cnm = T.M.channels{kk};
    fprintf('IMA: %s, NM: %s\n', cima, cnm )    
    ncnm = numel(cnm);
    assert(strcmp(cnm(1:ncnm), cima(1:ncnm)) == 1)
end
fprintf('ok!\n');

if 0
figure,
imagesc(D.UserData.I)
axis image
colormap gray
hold on, contour(T.M.mask, [.5, .5], 'Color', 'green')
title('UserData.I (max projection of nuclei staining). Mask from NM')
end

% UserData.I2 seems to be a temporary image from one of the channels

%% Nuclei
fprintf('-> NUCLEI\n');
% D.UserData.cell(1)
% D.UserData.cell(1)
%ans = 
%  struct with fields:
%      edge: [29×2 double]
%    center: [183.7242 324.4074]
%      area: 18371
%     label: '1'
     
%% Dots
fprintf('-> DOTS\n');
% D.UserData.dots
% X, Y, Z
% max(D.UserData.dots(:, 4)) == 4 % Channel ?
% max(D.UserData.dots(:, 5)) == 9 % Nuclei?
for kk = 1:numel(D.UserData.channel_name)
    ndots = sum(D.UserData.dots(:,4) == kk);
    fprintf('%s : %f dots\n', D.UserData.channel_name{kk}, ndots);
    % The IMA files does not contain either pixel values of filter response
    % etc...
    % While the NM file expects: T.M.dotsMeta:
    %  {'x'}    {'y'}    {'z'}    {'fvalue'}    {'pixel'}    {'fwhm'}
    
    dots = D.UserData.dots( D.UserData.dots(:,4) == kk, [2,1,3]);
    dots = [dots, fliplr(1:size(dots,1))']; % fvalue
    dots = [dots, fliplr(1:size(dots,1))']; % pixel
    dots = [dots, -2*ones(size(dots,1), 1)]; % fwhm
    T.M.dots{kk} = dots;
end

s.dots.th = cell(1, numel(T.M.channels));
s.dots.Z = [-inf, inf];
s.dots.FWHM = [-inf, inf];
s.dots.maxDots = inf;
s.dilationRadius = 5;
s.dots.fwhm = [];

[M, N] = df_resetUserDots(T.M, T.N, s)

save([outFolder nmfile(end-5:end)], 'M', 'N');
end