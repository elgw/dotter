function [AD, Delta] = df_cc_cluster(varargin)
%% function [AD, Delta] = df_cc_cluster(varargin)
% Input: 
% A n-cell, D, with dots from n channels specified by a [N x 3]
% array.
% 
% Output: 
% A [n x n] cell where A{a,b} is a [ . x 6 ] array
% so that 
% the point A{a,b}(kk,1:3) from D{a} corresponds to 
% the point A{a,b}(kk,4:6) from D{b}.
%
% delta is the linear displacement that was found and used in
% the registration.
%
% General info
% This function performs Point set registration
% https://en.wikipedia.org/wiki/Point-set_registration
% only looking for a translation. It minimizes
% sum(erf(d/4)) over all d, beeing the distance from each point
% in A to the closest point in B.
%
% In a future version it should be merged with df_cc_create
% and some version of ICP should be used.
% Points could also be weighed based on the fitting error 
% and their intensity

s.maxDist = 2;  % max distance translation to identify matching pairs
s.plot = 0;
s.verbose = 0;

gotDots = 0;
gotSettings = 0;

for kk = 1:numel(varargin)
    if strcmpi(varargin{kk}, 'dots')
        D = varargin{kk+1};
        gotDots = 1;
    end
    if strcmpi(varargin{kk}, 'settings')
        s = varargin{kk+1};
        gotSettings = 1;
    end
    if strcmpi(varargin{kk}, 'getDefaults')
        AD = s;
        return
    end
end

if gotDots == 0
    fprintf('Error: Not dots specified\n');
end
if gotSettings == 0
    fprintf('Error: No settings provided\n');
end

if gotSettings*gotDots == 0
    error('Invalid usage');
end

AD = cell(numel(D));
Delta = cell(numel(D));

if ~exist('channels', 'var')
    channels = cell(1, numel(D));
    for kk = 1:numel(channels)
        channels{kk} = sprintf('%d', kk);
    end
end

% For each channel vs each other channel
for aa = 1:numel(D)
    for bb = 1:numel(D)
        if aa ~= bb
            A = D{aa}(:,1:3); B = D{bb}(:,1:3);
            
            % TODO: optimization over shifts
            delta = get_registration_displacement(A, B);
            Delta{aa,bb} = delta;
            
            Bshift = [B(:, 1)+delta(1), ...
                B(:, 2)+delta(2), ...
                B(:, 3)+ delta(3)];
            
            idx = dsearchn(A, Bshift);
            
            C = [A(idx, :), B];
            
            C_shifted = [A(idx, :), Bshift];
            
            d = eudist(C_shifted(:, 1:3), C_shifted(:, 4:6));
            % Ideally this is a very low threshold
            % but when strong chromatic aberrations besides 
            % shifts it needs to be higher
            Cuse = C(d < s.maxDist, :); 
                        
            if s.plot            
                figure, 
                scatter3(A(:,2),A(:,1), A(:,3), 'ko'), 
                hold on, 
                scatter3(B(:,2),B(:,1), B(:,3), 'ro'), 
                for pp = 1:size(Cuse, 1)
                    plot3([Cuse(pp, 2), Cuse(pp,5)], ...
                        [Cuse(pp, 1), Cuse(pp,4)], ...
                        [Cuse(pp, 3), Cuse(pp,6)], 'g')
                end                
                title(sprintf('%d dots between set %s and %s\n', ...
                    size(Cuse,1), channels{aa}, channels{bb}));                        
            end
            
            AD{aa,bb} = Cuse;
        end
    end
end

end


function delta = get_registration_displacement(A, B)

gridSearch = 1;
gridN = 20;

delta0 = [0,0,0];

if gridSearch
g0 = goodness(A, B, delta0);
% Initial grid search
for dx = linspace(-10, 10, gridN)
    for dy = linspace(-10, 10, gridN)
        for dz = linspace(-10, 10, gridN)
            g = goodness(A, B, [dx, dy, dz]);
            if g < g0
                delta0 = [dx, dy, dz];
                g0 = g;
            end
        end
    end
end

end

% figure, scatter3(A(:,1), A(:,2), A(:,3)), hold on, scatter3(B(:,1), B(:,2), B(:,3))
[delta, ~] = fminsearch(@(x) goodness(A, B, x), delta0);

end

function g = goodness(A, B, delta)

idx = dsearchn(A, ...
    [B(:,1) + delta(1), B(:,2) + delta(2), B(:,3) + delta(3)]);
A = A(idx, :);
Bm = B;
%Bm = B(idx, :);
d = ( (A(:,1)-(Bm(:,1)+delta(1))).^2 ...
    + (A(:,2)-(Bm(:,2)+delta(2))).^2 ...
    + (A(:,3)-(Bm(:,3)+delta(3))).^2 ).^(1/2);


e = erf(d/4); %  0.22 with grid search, 0.39 without


g = sum(e);

end