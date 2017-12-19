function [d,dN,M] = df_dPeriphery(M, D)
% Calculates the distance to the periphery of the dots in D using
% metadata in M. In particular it uses M.mask to generate a M.distanceMask
% and then interpolates the distance values at D to produce d

% Create the maskDistance if not already in M
if ~isfield(M, 'distanceMask')
    M = createDistanceMask(M);
end

% extract the distances
d = interpn(M.distanceMask, D(:,1), D(:,2), 'linear');
% as well as the largest distance of the nuclei
N = interpn(M.distanceMaskMax, D(:,1), D(:,2), 'linear');
dN = d./N;

    function M = createDistanceMask(M)
        % Append distanceMask to each M, defined as the distance transform
        % of the binary mask M.mask         
            mask = M.mask;
            mask = mask>0;
            mask = ~mask;            
            M.distanceMask = bwdist(mask) - bwdist(~mask) + (M.mask==0);   
            
            % Set the max distance of each object in distanceMaskMax
            % might be useful for normalization
            M.distanceMaskMax = zeros(size(mask));
            for kk = 1:max(M.mask(:))                
                M.distanceMaskMax = M.distanceMaskMax + max(max(max(M.distanceMask.*(M.mask==kk))))*(M.mask==kk);
            end
            
    end

end