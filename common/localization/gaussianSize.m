function [ D ] = gaussianSize(I, P, sigmas, s )
%% gaussianSize(I, P, sigmas)
% quick and dirty estimation of signal width, assuming gaussian profile and
% constant background

I = double(I);

if ~exist('s', 'var')
    s = [];
end

% 1 or 9 points per pixel
if ~isfield(s, 'mode')
    s.mode = 1;
end

if ~isfield(s, 'side')
    s.side = 13;
end

s.hside = (s.side-1)/2;

% pre allocate for output
P = round(P);
D = zeros(size(P,1), 2);

L = [0,0];

[x,y] = meshgrid(-s.hside:s.hside, -s.hside:s.hside);
d = x.^2+y.^2;
mask = d<= s.hside.^2;
mask = double(mask);

mask = ones(size(mask)); % strange behaviour with round mask!
area = sum(mask(:));

%figure, imagesc(mask);

if s.mode == 9
L = [];
    for kk = -1:1
        for ll = -1:1
            L = [L ; 1/3*[kk,ll]];
        end
    end
end

for kk = 1:size(P,1)
    try
    patch = mask.*I(P(kk,1)-s.hside:P(kk,1)+s.hside, P(kk,2)-s.hside:P(kk,2)+s.hside, P(kk,3));
    for jj = size(L,3)
    minerror = realmax;
    for ll = 1:numel(sigmas)
        sigma = sigmas(ll);
        gpatch = mask.*df_gaussianInt2(L(jj,1:2), sigma, s.hside);
       
       
       max = patch(s.hside+1,s.hside+1); % in image
       psum = sum(patch(:));
       gsum = sum(gpatch(:));
       % constant background, number of photons in signal
       %%% !!!! [area, psum] vs [area, 1]
       h = [[area, gsum];[1,gpatch(s.hside+1, s.hside+1)]]\[psum;max];
       synth = gpatch*h(2)+h(1);
       %ssum = sum(synth(:));       
       error = sum(abs(patch(:)-synth(:)));
       if error<minerror;
           minerror=error;
           D(kk,1)=sigmas(ll); D(kk,2)=h(2);
       end
    end
    end
    end
end