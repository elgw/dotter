function AD = df_cc_cluster(varargin)
% Input: a cell with dots from a number of channels
% Output: associated dots in the sense that
% A{a,b}(kk,1:3) corresponds to A{a,b}(kk,4:6)

s.maxDist1 = 15; % max distance between same dot in different channels
s.maxDist2 = 2;  % max distance after translation
s.plot = 0;
s.verbose = 0;

for kk = 1:numel(varargin)
    if strcmpi(varargin{kk}, 'dots')
        D = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'settings')
        s = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'channels')
        channels = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'getDefaults')
        AD = s;
        return
    end
end
   
AD = cell(numel(D));

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
            
            C = closest(A,B, s.maxDist1);
            
            delta = C(:,4:5)- C(:,1:2);  % delta xt
            r = (delta(:,1).^2 + delta(:,2).^2).^(1/2); % r xy
            rhat = median(r);
            
            if rhat < 10e-4
                d = [0,0];
            else
                deltan = delta;
                deltan(:,1) = deltan(:,1)./r;
                deltan(:,2) = deltan(:,2)./r;            
                thetahat = atan2(sum(deltan(:,1)), sum(deltan(:,2)));
                d = rhat*[sin(thetahat), cos(thetahat)];
            end
               
            if s.verbose
                whos
                rhat                
                d
                thetahat                
            end            
            
            % Translate for more narrow matching
            C = closest(A+repmat([d 0], [size(A,1),1]),B, s.maxDist2);
            C(:,1:3) = C(:,1:3) - repmat([d 0], [size(C,1),1]); % Translate back for the original locations
            
            if s.plot
            
            figure, 
            plot(A(:,1),A(:,2), 'k.'), 
            hold on, 
            plot(B(:,1),B(:,2), 'r.'), 
            
            plot(C(:,1),C(:,2), 'kx'),             
            plot(C(:,4),C(:,5), 'ro')
            plot((C(:,1)+ C(:,4))/2, (C(:,2) + C(:,5))/2, 'g.')            
            fprintf('%d dots between set %s and %s\n', size(C,1), channels{aa}, channels{bb});            
            pause
            end
            
            AD{aa,bb} = C;
        end
    end
end

end


function C = closest(A, B, maxDist)
% Find the closest dot in B for each dot in A.
% TODO: is it better to include all dots within the maximal distance?

C = zeros(size(A,1), 6);
nFound = 0;

for kk = 1:size(A,1)
    p = A(kk,1:3);
    
    d = eudist(p, B);
    mind = min(d(:));
    if mind<maxDist
        nFound = nFound + 1;
        idx = find(d==mind);
        idx = idx(1);
        C(nFound,:) = [p, B(idx,:)];
        
    end
           
    C = C(1:nFound,:);    
    
end

end