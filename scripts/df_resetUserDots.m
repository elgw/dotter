function [M,N,s] = df_resetUserDots(M,N,s)
% [M,N] = resetUserDots(M,N, s)
% Sets userDots based on the settings in s.dots
% s.dots.th : thresholds for each channel
% s.dots.Z : range for valid Z
% s.dots.FWHM : range for valid FWHM
% s.dots.maxDots : max number of dots per nuclei


disp('df_resetUserDots')

% Set a new threshold for a single channel or for all

if ~exist('channels', 'var')
    channels = 1:numel(M.channels);
end

fwhmCol = [];
if isfield(M, 'dotsMeta')
    fwhmCol = find(strcmpi(M.dotsMeta, 'fwhm'));
end
if numel(fwhmCol) == 1
    % good
else
    fprintf('No FWHM available for this dataset\n');
end

disp('Dilating the masks')

for kk = 1:numel(M.channels)
    if numel(s.dilationRadius)>= kk
        [m, ~, ~] = dotter_generateMasks(M.mask, s.dilationRadius(kk));
        M.xmask{kk} = m{2};
    else
        warning('no dilation radius set!');
        M.xmask{kk} = M.mask;
    end
end

for cc = channels
    fprintf('Channel: %s\n', M.channels{cc});
    % Grab all dots
    D0 = M.dots{cc}(:,[1:4]);
    
    % Dilation radius
    if ~isfield(s, 'dilationRadius');
        s.dilationRadius = 5*ones(channels,1);
    else
        if numel(s.dilationRadius)<channels
            s.dilationRadius = 5*ones(numel(channels),1);
        end
    end
    
    % FWHM
    if numel(fwhmCol) == 1            
        if numel(s.dots.fwhm) >= cc
            fwhmMin = s.dots.fwhm{cc}(1);
            fwhmMax = s.dots.fwhm{cc}(2);
        else
            warning('Now fwhm range for this file')
            fwhmMin = 0;
            fwhmMax = 10;
            s.dots.fwhm{cc}(1) = fwhmMin;
            s.dots.fwhm{cc}(2) = fwhmMax;
        end
        
        fprintf('FWHM restrictions: from %d to %d pixels.\n', fwhmMin, fwhmMax);
        
        F = M.dots{cc}(:,fwhmCol);
        Fok = 0*F;
        Fok(F<0) = 1;
        
        Fok(F>=fwhmMin  & F<=fwhmMax) = 1;
        D0 = D0(Fok==1,:);
        nRem = sum(Fok==0);
        if nRem > 0
            fprintf('Removed %d dots\n', nRem);
        end
    end
    
    % Thresholds
    % Set automatically if not available
    if numel(s.dots.th{cc})==0
        s.dots.th{cc} = dotThreshold(D0(:,4));
        assert(isnumeric(s.dots.th{cc}));
        s.dots.th0{cc} = s.dots.th{cc}/2;
    end
    
    fprintf('Threshold for channel %s: %.2d (%.2d).\n', M.channels{cc}, s.dots.th{cc}, s.dots.th0{cc});    
    s.dots.th0{cc} = s.dots.th{cc}/2;
    D1 = D0;
    
	D0 = D0(D0(:,4)>s.dots.th0{cc}, :);
	D0 = D0(D0(:,4)<s.dots.th{cc}, :);
    
    
    %D1 = M.dots{cc}(:,1:4);
    
    D1 = D1(D1(:,4)>=s.dots.th{cc}, :);
    
    
    % Z limits
    fprintf('Applying restrictions in Z, from %d to %d.\n', s.dots.Z(1), s.dots.Z(2));
    D0 = D0(D0(:,3)>=s.dots.Z(1) & D0(:,3)<=s.dots.Z(2), :);
    D1 = D1(D1(:,3)>=s.dots.Z(1) & D1(:,3)<=s.dots.Z(2), :);
    
    % Be verbosive about the max dots per nuclei
    if isfield(s.dots, 'maxDots')
        if numel(s.dots.maxDots)>=cc
            md = s.dots.maxDots(cc);
        else
            md = 10000;
            s.dots.maxDots(cc) = md;
        end
    else
        md = 10000;
    end
    
    if isfinite(md)        
        fprintf('Applying max dots=%d restriction\n', md);
    else
        disp('No restrictions on the number of dots');
    end
    
    % Per nuclei, selection and max dots restrictions
    for nn = 1:numel(N)
                        
        D0n = D0;
        inside = interpn(M.xmask{cc}, D0(:,1), D0(:,2));
        D0n = D0n(inside==nn, :);
        
        D1n = D1;
        inside = interpn(M.xmask{cc}, D1(:,1), D1(:,2));
        D1n = D1n(inside==nn, :);
        
        if isfinite(md)
            mdn = md; % Maximum number of dots for this nuclei
            % x2 if the nuclei is non-GI (G2)
            if N{nn}.dapisum > M.dapiTh
                mdn = mdn*2;
            end
            
            size0 = size(D1n,1) + size(D0n,1);
            if size(D1n,1) > mdn
                t = D1n(mdn+1:end,:);
                D1n = D1n(1:mdn, :);
                D0n = [t; D0n];
            end
            assert(issorted(flipud(D0n(:,4))))
            assert(size(D1n,1)+size(D0n,1) == size0);            
        end
        
        N{nn}.userDots{cc} = D1n(:,[1,2,3,4]);
        N{nn}.userDotsLabels{cc} = zeros(size(D1n,1),1); % One or two, representing allele
        N{nn}.userDotsExtra{cc} = D0n(:,[1,2,3,4]);
    end
end

end
