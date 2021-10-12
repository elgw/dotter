function snr = df_snr(image, dots)
% Calculates SNR for the dots [x,y,z, ... ; x,y,z, ... ; ...]
% in the supplied image
%
% SNR is defined as:
% (signal-background)/noise
% background and noise is estimated from a circle around each point,
% the radius of the circle is hard coded to 5

assert(size(dots,2)>2);
assert(numel(image)>0);

snr = zeros(size(dots,1), 1);

% Create a set off 100 points in a circle
radius = 5;
thetas = linspace(0,2*pi, 101);
thetas = thetas(1:end-1);
X = radius*sin(thetas);
Y = radius*cos(thetas);

for kk = 1:size(dots,1)
    dot = dots(kk,:);
    
    % Signal value, interpolate image    
    signal = interpn(image, dot(1), dot(2), dot(3));
    
    xd = dot(1)+X;
    yd = dot(2)+Y;
    zd = ones(size(xd))*dot(3);    
    bg = interpn(image, xd(:), yd(:), zd(:));
    bg = bg(isfinite(bg));
    noise = std(bg);
    bg = mean(bg);
    
    snr(kk) = (signal-bg)/noise;
    if(isnan(snr(kk)))
        warning('NaN value encountered, either the dot is outside of the image')        
    end
end

end