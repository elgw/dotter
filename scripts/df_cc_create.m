function varargout = df_cc_create(varargin)
% Create correction coefficients for chromatic aberrations
% Input:
%
% D: MATCHED dots, i.e., D{1}(1,:) should correspond to the same bead as
% D{n}(1,:) etc.
% Unmatched dots are matched with D = df_cc_cluster(P);
%
% s, settings
% s.polyorder  : order of correction, 1 or 2 is good most of the times
%
% Possible improvement: Set polyorder automatically (i.e., set to 1 when
% very few dots).


s.polyorder = 2;

for kk = 1:numel(varargin)
    if strcmpi(varargin{kk}, 'dots')
        D = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'channels')
        channels = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'settings')
        s = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'getDefaults')
        varargout{1} = s;
        return
    end
end

assert(size(D,1) == size(D,2));
assert(numel(channels) == size(D,1));
assert(s.polyorder > 0);
assert(s.polyorder < 4);

Cx = cell(size(D,1));
Cy = cell(size(D,1));
dz = cell(size(D,1));
E0 = zeros(size(D,1)); % MSE errors before
E = zeros(size(D,1)); % MSE errors after fitting
N = zeros(size(D,1)); % Number of dots

for aa = 1:size(D,1)
    % Create matrix for the polynomial model from D{aa}
                
    for bb=1:size(D,1)        
        if aa ~= bb
            
        Daa = D{aa,bb}(:,1:3);
        Dbb = D{aa,bb}(:,4:6);
        
        
        N(aa,bb) = size(D{aa,bb}, 1);
        
        fprintf('%d dots in %s, %d dots in %s\n',...
            size(Daa,1), channels{aa}, ...
            size(Dbb,1), channels{bb});
        
        if size(D{aa,bb},1) < 10
            warning('Using identity transformation. Error will be set to nan.');
            Daa  = 1024*rand(100, 3);
            Dbb = Daa;
        end
            
        % Possibly do a sub-selection on the dots
        % i.e., skip row kk if  numel(sum([Daa(kk,1:3), Dbb(kk,1:3)] ==
        % nan)> 0
        
        MXY1 = poly2mat(Daa(:,1:2), s.polyorder);
        
        % Polynomial coefficients        
        Cx{aa,bb} = MXY1\Dbb(:,1);
        Cy{aa,bb} = MXY1\Dbb(:,2);
        dz{aa,bb} = mean(Dbb(:,3)) - mean(Daa(:,3));
                
        Ft = zeros(size(MXY1,1), 2);
        Ft(:,1)=MXY1*Cx{aa,bb};
        Ft(:,2)=MXY1*Cy{aa,bb};        
        
        D2 = eudist(Ft(:,1:2), Dbb(:,1:2));
        D20 = eudist(Daa(:,1:2), Dbb(:,1:2));
        if size(D{aa,bb},1) < 10
            E(aa,bb) = nan;
            E0(aa,bb) = nan;
        else
            E(aa,bb) = mean(D2.^2);                
            E0(aa,bb) = mean(D20.^2);
        end
            
        end
    end
end

M.creationDate = datestr(now(), 'YYmmDD');
M.dotterVersion = df_version();

if isfield(s, 'filename')
    fprintf('Writing to %s\n', s.filename)
    save(s.filename, 'Cx', 'Cy', 'dz', 'E', 'channels', 'M', 'E0', 'N');
    varargout{1} = s.filename;
else
    varargout{1} = '';
end
    

end