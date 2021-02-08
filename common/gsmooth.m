function V=gsmooth(V, sigma, varargin)
% Smooth a 3D volume by convolving with a gaussian (separated)
% with sigma and a specific radius (optional)
%
% Optional parameters:
% 'normalized'
% To do: FFT for large sigma

%iptsetpref('UseIPPL', true)
%
% 2017-03-30, normalized almost as fast as non-normalized
%             'normalized' now triggers the normalized2-algorithm

if sigma == 0
    return
end

if isvector(V)
    V = gsmooth1(V, sigma, varargin);
    return
end

if sigma == 0
    return
end

if numel(sigma)==1
    if numel(size(V))==3
        sigma = sigma*[1,1,1];
    end
    if numel(size(V))==2
        sigma = sigma*[1,1];
    end
end

normalized = 0;
normalized2 = 0;
radius=round(4*sigma+2);
if (mod(radius,2)==0)
    radius=radius+1;
end

for kk = 1:numel(varargin)
    if strcmp(varargin{kk}, 'radius')
        radius = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'normalized')
        normalized2 = 1;
    end
    if strcmpi(varargin{kk}, 'normalized2')
        normalized = 1;
    end
end

%convf=@imfilter; % Handles uint8 and uint16 as well :) Alternative convn
convf=@convn;

if(numel(size(V))==3)
    d=2*radius+1;
    %k=fspecial('gaussian', [d, 1], sigma);
    if(sigma(1)>0)
        k1=reshape(ggaussian(d(1), sigma(1)), [d(1),1,1]);
    else
        k1 = 1;
    end
    if sigma(2)>0
        k2=reshape(ggaussian(d(2), sigma(2)), [1, d(2),1]);
    else
        k2 = 1;
    end
    if sigma(3)>0
        k3=reshape(ggaussian(d(3), sigma(3)), [1,1,d(3)]);
    else
        k3 = 1;
    end
    
    if sigma(1) > 0
        V=convf(V, k1, 'same');
        if normalized
            V=V./convf(0*V+1, k1, 'same');
        end
    end
    
    if sigma(2) > 0
        V=convf(V, k2, 'same');
        if normalized
            V=V./convf(0*V+1, k2, 'same');
        end
    end
    
    if sigma(3) > 0
        V=convf(V, k3, 'same');
        if normalized
            V=V./convf(0*V+1, k3, 'same');
        end
    end
    
    if normalized2                
        V=V./gnorm(size(V), [numel(k1), numel(k2), numel(k3)], max(sigma, [0.1, 0.1, 0.1]));
    end
    
end

if(numel(size(V))==2)
    d=2*radius+1;
    k1=fspecial('gaussian', [d(1), 1], sigma(1));
    
    k2=fspecial('gaussian', [1, d(2)], sigma(2));
    
    %fprintf('1... ');
    V=imfilter(V, k1, 'same');
    if normalized | normalized2
        V=V./imfilter(0*V+1, k1, 'same');
    end
    %fprintf('2... ');
    V=imfilter(V, k2, 'same');
    if normalized | normalized2
        V=V./imfilter(0*V+1, k2, 'same');
    end
    %fprintf('3... ');
    %fprintf('\n');
end

    function test()
        
        %% Normalized or not
        I = rand(120,60);
        J = gsmooth(I, 5);
        JN = gsmooth(I, 5, 'normalized');
        figure, imagesc([I J JN]);
        
        I = rand(120,60, 30);
        J = gsmooth(I, 5);
        JN = gsmooth(I, 5, 'normalized');
        figure, imagesc([I(:,:,15) J(:,:,15) JN(:,:,15)]);
        
        
        I=ones(100,100);
        figure
        for ss=1:2:40
            tic, s=gsmooth(I, ss);
            plot(ss, toc, 'x', 'MarkerSize', 15)
            hold on
            tic
            s=conv2(I, fspecial('gaussian', (ceil(ss)*4+1)*[1,1], ss), 'same');
            plot(ss, toc, 'o', 'MarkerSize', 15)
        end
    end
    function N = gnorm(siz, d, sigmas)
        % siz: size of volume
        % d: dimensions of kernel
        % sigmas: for the gaussian kernel
        if 0
            siz = [1024,1024, 60];
            d = [11,11,11];
            sigmas = [1,2,3];
        end
        
        % Normalization volume
        k1= ggaussian(d(1), sigmas(1))';
        k2= ggaussian(d(2), sigmas(2))';
        k3= ggaussian(d(3), sigmas(3))';
        
        L1 = convn(ones(siz(1),1), k1, 'same');
        L2 = convn(ones(siz(2),1), k2, 'same');
        L3 = convn(ones(siz(3),1), k3, 'same');
        
        % This can be expressed more elegant and less computationally
        % demaning with tensor calculus. Many unneccessary multiplications
        % ...
        xy = L1*L2';
        z = reshape(L3, [1,1,numel(L3)]);
        Nxy = repmat(xy, [1,1,numel(L3)]);
        Nz = repmat(z, [siz(1), siz(2), 1]);
        N = Nxy.*Nz;
    end

end

function V = gsmooth1(V, sigma, varargin)

V = reshape(V, [1,numel(V)]);

radius=round(4*sigma+2);
if (mod(radius,2)==0)
    radius=radius+1;
end

for kk = 1:numel(varargin)
    if strcmp(varargin{kk}, 'radius')
        radius = varargin{kk+1};
    end
    if strcmp(varargin{kk}, 'normalized')
        normalized = 1;
    end
end

% Kernel
K=ggaussian(radius, sigma);

V = conv(V, K, 'same');

if normalized
    V = V./conv(ones(size(V)), K, 'same');
end

end