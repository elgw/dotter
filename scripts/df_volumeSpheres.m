function A= df_volumeSpheres(S, varargin)
%% function df_volumeSpheres(S)
%
% Volume of possibly overlapping spheres given in S
% S = [[x,y,z,r]; [x,y,z,r], ...
%
% Figure out the range in x, y, z
% For examples, see unittest.m in DOTTER
%
% This can also be solved analytically, see Avis 1988

% 2017-08-23
% Renamed from AreaOfSpheres.m to df_volumeSpheres.m
%
% 2017-02-01
% Created


verbose = 0;
for kk = 1:numel(varargin)
    if strcmp(varargin{kk}, 'verbose')
        verbose = 1;
    end
end

NEL = 10^6; % number of volume elements to use

rmax = max(S(:,4),[],1);

minxyz = min(S(:,1:3),[],1)-rmax;
maxxyz = max(S(:,1:3),[],1)+rmax;

N = abs(prod(minxyz-maxxyz));
step = N.^(1/3)/NEL^(1/3);

if verbose
    fprintf('Element side: %f [AU]\n', step);
end

[X, Y, Z] = ndgrid(minxyz(1):step:maxxyz(1), ...
    minxyz(2):step:maxxyz(2), ...
    minxyz(3):step:maxxyz(3));

V = zeros(size(X));
for kk = 1:size(S,1)
    V = V + setSphere(X, Y, Z, S(kk,:));
end

%volumeSlide(V)

if verbose
    f = figure;
    imagesc(max(V,[],3));
    title(sprintf('%d dots\n', size(S,1)));
    axis image
    colorbar
    S
    pause
    close(f);
end


A = sum(V(:)>0);

if verbose
    fprintf('%d / %d elements covered\n', A, numel(V));
end

A = A*step^3;


    function V = setSphere(X, Y, Z, S)
        % Place ONE sphere in V at location S(1:3) with radius S(4)
        % X,Y,Z are the coordinates of V "meshgrid"
        
        R = (X-S(1)).^2 + (Y-S(2)).^2  + (Z-S(3)).^2;
        
        V = R<=S(4)^2;
        
    end

end