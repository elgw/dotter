function V = df_volumeTubes(varargin)
%% function df_volumeTubes(S)
%
% Volume of possibly overlapping tubes/cylinders given
% in T where each line is a pair of 3D points: [x,y,z,  x,y,z]
%
% Uses monte-carlo sampling to calculate the volume.
%
% See df_volumeTubes_ut for examples

% Defaults
s.ndots = 100000;
s.radius = 1;
s.verbose = 0;

% Parse settings
for kk = 1:numel(varargin)
    if strcmpi(varargin{kk}, 'data')
        T = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'verbose')
        s.verbose = 1;
    end
    if strcmpi(varargin{kk}, 'radius')
        s.radius = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'npoints')
        s.ndots = varargin{kk+1};
    end
end

if s.verbose
    disp('Input:')
    fprintf('Number of tubes: %d\n', size(T,1));
    fprintf('Number of dots: %d\n', s.ndots);
    fprintf('Radius: %f [au]\n', s.radius);
end

% Get bounds of domain to know where to sample
D = zeros(1,6);

D([1,3,5]) = min([T(:,1:3);T(:,4:6)]) - s.radius;
D([2,4,6]) = max([T(:,1:3);T(:,4:6)]) + s.radius;

if s.verbose
    D
end

R = rand(s.ndots, 3); % random sample points
for kk = 1:3
    k2 = (kk-1)*2;
    R(:,kk) = R(:,kk)*(D(k2+2)-D(k2+1));
    R(:,kk) = R(:,kk)+D(k2+1);
end

if s.verbose
    min(R)
    max(R)
end

ED = inf(size(R,1),1);
for kk = 1:size(T,1)
    ED = min(ED,dPointsToLines(T(kk,:), R)); % return smallest distance to any tube
end

%figure, histogram(ED)
N_inside = sum(ED<s.radius); % Figure out which points are within the treshold

V = N_inside/s.ndots * (D(2)-D(1))*(D(4)-D(3))*(D(6)-D(5));

end