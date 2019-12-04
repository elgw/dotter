imNo = 1;
load(sprintf('%03d.NM', imNo), '-mat');
folder = pwd();
folder = strrep(folder, '_calc', '');
dapiFile = sprintf('%s/dapi_quim_%03d.tif', folder, imNo);
tmrFile = sprintf('%s/tmr_quim_%03d.tif', folder, imNo);

%iD = df_readTif(dapiFile);
iT = df_readTif(tmrFile);

%volumeSlide(iT, 'mask', M.mask);

dT = dotCandidates(iT);

dotterSlide(iT,dT, [], M);

%dTS = dT([1:5, 7:12], :);
%dTS = dT(1:100,:);

dTS = dT(1:200,:);

F = dotFitting(iT, dTS);

H = F(:,6)*130*2*sqrt(2*log(2));
H=H(H>0);
H = H(H<1000);

fprintf('FWHM: %f, (%d dots)\n', mean(H), numel(H));