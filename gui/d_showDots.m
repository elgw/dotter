kk = 20; % File
cc = 1; % Channel
ll = 1; % nuclei

close all

load([wfolder files(kk).name], '-mat')
idapi = df_readTif(M.dapifile);
ichannel =  df_readTif(M.channelf{cc});
fprintf('Possibly saturated: %d\n', sum(ichannel(:) == 2^16));
dots = N{ll}.dots{cc};

 cLimDapi = quantile16(idapi, [0.01, 0.99]);
 cLimChannel = quantile16(ichannel, [0.1, 0.99995]);
 cLimChannel = quantile16(ichannel, [0,1])
 bbx = N{ll}.bbx;
 %bbx = [350, 370, 160, 180]
 
 figure
 %imagesc(idapi(bbx(1):bbx(2), bbx(3):bbx(4)));
 %colormap gray
 %set(gca, 'clim', cLimDapi);
 
 % XY
 subplot(2,3,1)
 imagesc(max(ichannel,[], 3));
 set(gca, 'clim', cLimChannel)
 axis([bbx(3), bbx(4), bbx(1), bbx(2)])
 
 subplot(2,3,4)
 imagesc(max(ichannel,[], 3));
 axis([bbx(3), bbx(4), bbx(1), bbx(2)])
 set(gca, 'clim', cLimChannel)
 hold on
 plot(dots(:,2), dots(:,1), 'ro') 
 colormap gray

 % XZ
 subplot(2,3,2)
 ichannelx = ichannel(bbx(1):bbx(2), :, :);
 ichannelx = max(ichannelx, [], 1);
 ixz = squeeze(ichannelx)';
 imagesc(ixz)
 set(gca, 'clim', cLimChannel); 
 axis([bbx(3), bbx(4), 1, size(ichannel,3)])  
 
 subplot(2,3,5)
 ichannelx = ichannel(bbx(1):bbx(2), :, :);
 ichannelx = max(ichannelx, [], 1);
 ixz = squeeze(ichannelx)';
 imagesc(ixz)
 set(gca, 'clim', cLimChannel); 
 hold on
  plot(dots(:,2), dots(:,3), 'o', ...
                'MarkerEdgeColor','r',...
                       'MarkerFaceColor','none');
axis([bbx(3), bbx(4), 1, size(ichannel,3)])  

% YZ
subplot(2,3,3)
ichannely = ichannel(:,bbx(3):bbx(4), :);
ichannely = max(ichannely, [], 2);
iyz = squeeze(ichannely)';
imagesc(iyz)    
set(gca, 'clim', cLimChannel); 
axis([bbx(1), bbx(2), 1, size(ichannel,3)])

subplot(2,3,6)
ichannely = ichannel(:,bbx(3):bbx(4), :);
ichannely = max(ichannely, [], 2);
iyz = squeeze(ichannely)';
imagesc(iyz)     
set(gca, 'clim', cLimChannel); 
hold on
plot(dots(:,1), dots(:,3), 'o', ...
                'MarkerEdgeColor','r',...
                       'MarkerFaceColor','none');
axis([bbx(1), bbx(2), 1, size(ichannel,3)])