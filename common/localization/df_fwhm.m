function w = df_fwhm(V, D, varargin)
%% function w = df_fwhm(V, D, varargin)
%  Calculates full width, half max for dots in V in the xy-plane
%  Coordinates for the dots are given in D in the three first columns
%  width is given in pixels.
%  Returns -1 when no value could be estimated
%
% Options:
%  'interpolation', : 'linear', 'cubic', ... see interpn
%  'verbose', turns extra output on
% 'z' get fwhm in z
% 'side' set the side length of the profiles used to calculate the fwhm.
% 2xside+1 pixels will be used. For small dots, decrease from the default 
% side=11 to something smaller.
% 

if numel(D)==0
    w = [];
    return
end

verbose = 0;
useNewFWHM1d = 1;
s.zMode = 0;

V = double(V);

s.Side = 11; % lines of size s.Side*2+1 are used

if size(V,3)==1
    interpolation = 'linear'; % 'pchip', 'spline'
else
    interpolation = 'cubic';
end

for kk=1:numel(varargin)
    if strcmpi(varargin{kk}, 'interpolation')
        interpolation = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'verbose')
        verbose = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'z')
        s.zMode = 1;
    end
    if strcmpi(varargin{kk}, 'side')
        s.Side = varargin{kk+1};
    end
end

%% Going for z?
if s.zMode == 1
    w = fwhmz(V, D);
    return;
end

%interpolation = 'sinc'; % 'pchip', 'spline'
DD = round(D(:,1:3));
w = -ones(size(D,1),1);
for kk = 1:size(D,1)
    %progressbar(kk, size(D,1));
    
    if (DD(kk,1)>11 && D(kk,1)<(size(V,1)-10) && DD(kk,2)>11 && D(kk,2)<(size(V,2)-10))                
        %try
        if size(V,3)>1
            ROI = V((DD(kk,1)-10):(DD(kk,1)+10), (DD(kk,2)-10):(DD(kk,2)+10), DD(kk,3));
            lzero = sort(ROI(:));
            lzero = mean(lzero(1:80));
            
            if verbose
                hm(kk) = corrsize(ROI);
            end
            
            % Extract and calculate cross sections in x and y direction, then
            % use the average fwhm of these
            %keyboard
            
            lx = interpn(V, (D(kk, 1)-s.Side):(D(kk, 1)+s.Side), ...
                D(kk,2)*ones(1,2*s.Side+1), ...
                D(kk,3)*ones(1,2*s.Side+1), interpolation);
        end
        if size(V,3)==1
            ROI = V((DD(kk,1)-10):(DD(kk,1)+10), (DD(kk,2)-10):(DD(kk,2)+10));
            lzero = sort(ROI(:));
            lzero = mean(lzero(1:100));
            
            if strcmp(interpolation, 'sinc')
                lx = lanczos2D(V, (D(kk, 1)-s.Side):(D(kk, 1)+s.Side), ...
                    D(kk,2)*ones(1,2*s.Side+1), 5);
            else
                lx = interpn(V, (D(kk, 1)-s.Side):(D(kk, 1)+s.Side), ...
                    D(kk,2)*ones(1,2*s.Side+1),interpolation);
            end
        end
        
        
        if useNewFWHM1d == 1
            wx = df_fwhm1d(lx);
        else
            wx = getw(lx, 0, lzero);
        end
        if verbose == 2
            plot(lx)
            title('lx')
        end
        
        
        if size(V,3)>1
            ly = interpn(V, D(kk,1)*ones(1,2*s.Side+1), ...
                (D(kk, 2)-s.Side):(D(kk, 2)+s.Side), ...
                D(kk,3)*ones(1,2*s.Side+1), interpolation);
        end
        if size(V,3)==1
            %keyboard
            if strcmp(interpolation, 'sinc')
                ly = lanczos2D(V, D(kk,1)*ones(1,2*s.Side+1), ...
                    (D(kk, 2)-s.Side):(D(kk, 2)+s.Side), 5);
            else
                ly = interpn(V, D(kk,1)*ones(1,2*s.Side+1), ...
                    (D(kk, 2)-s.Side):(D(kk, 2)+s.Side), interpolation);
            end
        end
        
        if useNewFWHM1d == 1
            wy = df_fwhm1d(ly);
            %save fwhm1dtest.mat ly
        else
            wy = getw(ly, 0, lzero);
        end
                                
        if wx<0
            w(kk) = wy;
        end
        if wy<0
            w(kk) = wx;
        end
        
        if wx>0 && wy>0
            w(kk) = .5*(wx + wy);
        end
        
        if verbose > 1
            figure(1)            
            subplot(1,2,1)
            hold off
            plot(lx)
            hold on
            plot(ly, 'r')
            legend({sprintf('lx: %f', wx), sprintf('ly: %f', wy)})
            title(sprintf('%d: (%f, %f, %f)', kk, D(kk,1), D(kk,2), D(kk,3)))
            subplot(1,2,2)
            imagesc(ROI)
            title(sprintf('%d pixels: %f nm', w(kk), w(kk)*130))
            fprintf('wx: %f wy: %f\n', wx, wy);
            keyboard                       
        end
        
    else
        if verbose
            disp('Out of bounds')
        end
    end
end

end

function w = fwhmz(V, D)
interpolation = 'cubic';

for kk = 1:size(D,1)
    s.Side = 5;    
    lz = interpn(V, ...
        D(kk,1)*ones(1,2*s.Side+1), ...
        D(kk,2)*ones(1,2*s.Side+1), ...
        (D(kk,3)-s.Side):(D(kk,3)+s.Side), interpolation); 
    lz = lz(isfinite(lz));            
    if mod(numel(lz),2)==1
    w(kk) = df_fwhm1d(squeeze(lz)');
    else
        w(kk) = nan;
    end
end

end

function hm = corrsize(I)
I = unpadmatrix(I,2);
I = I - mean(I(:));
I = I/norm(I(:));
sigma = linspace(.8, 4, 200);
for ss = 1:numel(sigma)
    G = fspecial('gaussian', size(I), sigma(ss));
    G = G/norm(G(:));
    gcorr(ss) = sum((G(:).*I(:)));
end
if 0
figure(2)
hold off
plot(sigma*2.35*130, gcorr)
xlabel('FWHM, [nm]')
drawnow
figure(1)
keyboard
end
idx = find(gcorr == max(gcorr(:)));
hm = sigma(idx)*2.35*130;

end