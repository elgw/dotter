function T = df_analyzeAlleles(M,N)
% function df_analyzeAlleles(M,N)
%
% Purpose: Measure properties of individual allelles as well as how the
% alleles relate to the nuclei
%
% Usage:
% # set userDots from the GUI
% [N, M] = df_getNucleiFromNM();
% T = df_analyzeAlleles(M,N)
% writetable('T', '~/Desktop/myAlleles.csv');
%

voxelSize = df_getVoxelSize();
sphereRadius = inputdlg('Sphere radius for volume calculations: [nm] ', 'df_analyzeAlleles', 1, {'500'});
sphereRadius = str2double(sphereRadius);

fprintf('voxelSize: %d x %d x %d nm\n', voxelSize(1), voxelSize(2), voxelSize(3));
fprintf('sphereRadius: %.1f nm\n', sphereRadius);

fn = getFN(M,N); %field and nuclei

disp('Geting the distances between alleles -- if there are two of them');
dA = d2alleles(M,N);

disp('Creating distance masks for each M.mask');
M = createDistanceMasks(M);

disp('Getting distances between allele centroids and the nuclei edge')
dP = dPer(M,N);

disp('Calculating the volumes of the alleles')
vA = getVolumeAlleles(M,N);


% Prepare the output table
% File, nuclei number, dA, dP1, dP2, dC1, dC2, v1, v2
A = [fn num2cell([dA dP vA])];

T = cell2table(A);
T.Properties.VariableNames = ...
    {'File', 'Nuclei', ...
    'nDotsAllele1', 'nDotsAllele2', ...
    'DistanceBetweenAlleles', ... %dA
    'DistanceAllele1_periphery', 'DistanceAllele2_periphery', ...
    'VolumeAllele1', 'VolumeAllele2'};

    function vA = getVolumeAlleles(M,N)
        % Calculate the volume of each allele
        
        vA = nan(numel(N),2);
        for nn = 1:numel(N)
            nuc = N{nn};
            for cc = 1:nuc.nClusters
                assert(nuc.nClusters<3);
                
                vA(nn,cc) = volumeAllele(nuc, cc);
            end
        end        
    end

    function v = volumeAllele(nuc, cc)
        % Returns the volume for allele cc in nuc
         p = getAllDots(nuc, cc);
         
        v = df_volumeSpheres([p(:,1:3) repmat(sphereRadius, [size(p,1),1])] );        
    end


    function fn = getFN(M,N)
        % Get file name and nuclei number
        % and the number of dots in each cluster
        fn = cell(numel(N,2));
        for kk = 1:numel(N)
           fn(kk,1) = {N{kk}.file};
            fn(kk,2) = {N{kk}.nucleiNr};
            if(N{kk}.nClusters>0)
                fn(kk,3) = {size(N{kk}.clusters{1},1)};
            end
            if(N{kk}.nClusters>1)
                fn(kk,4) = {size(N{kk}.clusters{2},2)};
            else
                fn(kk,4) = 0;
            end
        end
    end

    function dP = dPer(M, N)
        % Distance from allele centroid to periphery
        dP = nan(numel(N),2);
        for nn = 1:numel(N)
            nuc = N{nn};
            for cc = 1:nuc.nClusters
                assert(nuc.nClusters<3);
                dP(nn,cc) = peripheryDistance(nuc, cc);
            end
        end
    end

    function d2a = d2alleles(M,N)
        % Euclidean distance between alleles
        d2a = nan(numel(N),1);
        for nn = 1:numel(N)
            nuc = N{nn};
            if nuc.nClusters == 2
                d2a(nn) = centroidDistance(nuc);
            end
        end
    end

    function d = getAllDots(nuc, cl)
        % return a list with all dots,d, from nuclei, nuc, in cluster, cl
        
        C = nuc.clusters{cl};
        d = [];
        for cc = 1:numel(C.dots)
            d = [d; C.dots{cc}];
        end
    end

    function d = centroidDistance(nuc)
        % return the distance, d, between the two alleles in nuclei, nuc.
        
        a = getAllDots(nuc, 1); a = a(:,1:3);
        b = getAllDots(nuc, 2); b = b(:,1:3);
        
        a = a.*repmat(voxelSize, [size(a,1),1]);
        b = b.*repmat(voxelSize, [size(b,1),1]);
        
        ma = mean(a,1);
        mb = mean(b,1);
        d = norm(ma-mb, 2);
    end

    function d = peripheryDistance(nuc, cc)
        % return the 2D distance from the centroid of cluster cc in nuclei nuc to the
        % periphery of the nuclei mask
        
        p = getAllDots(nuc, cc);
        p = p(:,1:2);
        p = mean(p,1);
        %keyboard
        d = interpn(M{nuc.metaNo}.distanceMask, p(1), p(2), 'linear');
        d = d*voxelSize(1);        
    end

    function M = createDistanceMasks(M)
        % Append distanceMask to each M, defined as the distance transform
        % of the binary mask M.mask
        
        for kk = 1:numel(M)
            
            mask = M{kk}.mask;
            mask = mask>0;
            mask = ~mask;
            M{kk}.distanceMask = bwdist(mask);
            
        end
    end

disp('done');
end



