function C  = com3(V, P, sigma)
%% function C  = com3(V, P, sigma)
% Calculates the centre off mass at locations given by P
% P is rounded initially
%
% Convolves the whole image with filters so the speed is something like
% k0 + k1*N, k0 >> k1, and N is the number of dots

s.masktype = 'ball';

if ~exist('V', 'var')
    test()
    return
end

%% Prepare volume
% Subtract the background
V = V - mean(V(:)); % Simplest option

% Alternatives: subtract low pass filtered version


%% Prepare dots
L = round(P);

r = 2*sigma; % Radius of local mask
[Dy, Dx, Dz] = meshgrid(-r:r, -r:r, -r:r); % Convolution kernels

R = Dy.^2 + Dx.^2 + Dz.^2;
R = R.^(1/2);

if strcmp(s.masktype, 'gaussian')
    k = mvnpdf(R(:), 0, sigma);
    k = reshape(k, size(Dx));
    k = k/sum(k(:));
end

if strcmp(s.masktype, 'ball')
    R = reshape(R, size(Dy));
    R(R<r) = -1;
    R(R>-1) = 0;
    k = -1*R;
    k = k/sum(k(:));
end

mx = convn(V, -Dx.*k, 'same');
my = convn(V, -Dy.*k, 'same');
mz = convn(V, -Dz.*k, 'same');

w = convn(V, ones(size(Dx)).*k, 'same');

C = 0*P;
C(:,1) = L(:,1) + interpn(mx./w, L(:,1), L(:,2), L(:,3), 'nearest');
C(:,2) = L(:,2) + interpn(my./w, L(:,1), L(:,2), L(:,3), 'nearest');
C(:,3) = L(:,3) + interpn(mz./w, L(:,1), L(:,2), L(:,3), 'nearest');

end

function test

    % Create a test volume, V.
    % Set one bright pixel

    V = zeros(128,64,32);
    V = V+5;
    P = [20,15,15]
    V(P(1),P(2), P(3)) = V(P(1),P(2), P(3)) + 2;
    C = com3(V, P, 1)
        
    
    V(P(1)+1,P(2), P(3)) = V(P(1)+1,P(2), P(3)) + 1;
    C = com3(V, P, 2)
    
    V(P(1),P(2)+1, P(3)) = V(P(1),P(2)+1, P(3)) + 1;
    C = com3(V, P, 2)
    
    V(P(1),P(2), P(3)+1) = V(P(1),P(2), P(3)+1) + 1;
    C = com3(V, P, 2)
end