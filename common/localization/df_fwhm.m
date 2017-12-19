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

if numel(D)==0
    w = [];
    return
end

verbose = 0;

useNewFWHM1d = 1;

V = double(V);

s.Side = 11; % lines of size s.Side*2+1 are used

if size(V,3)==1;
    interpolation = 'linear'; % 'pchip', 'spline'
else
    interpolation = 'cubic';
end

for kk=1:numel(varargin)
    if strcmp(varargin{kk}, 'interpolation')
        interpolation = varargin{kk+1};
    end
    if strcmp(varargin{kk}, 'verbose')
        verbose = 1;
    end
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
        
        
        if useNewFWHM1d == 1;
            wx = df_fwhm1d(lx);
        else
            wx = getw(lx, 0, lzero);
        end
        if verbose
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
        
        
        if verbose
            fprintf('wx: %f wy: %f\n', wx, wy);
        end
        
        if wx<0
            w(kk) = wy;
        end
        if wy<0
            w(kk) = wx;
        end
        
        if wx>0 && wy>0
            w(kk) = min(wx,wy);
        end        
    else
        if verbose
            disp('Out of bounds')
        end
    end
end

end

