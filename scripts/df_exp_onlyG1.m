function [M,N] = df_exp_onlyG1(M,N)
% Filter out nuclei that are not G1

N2 = [];
for kk = 1:numel(N)
    if isfield(M{N{kk}.metaNo}, 'dapiTh')
        if N{kk}.dapisum <= M{N{kk}.metaNo}.dapiTh
            N2 = [N2 , N(kk)];
        end
    else
        warning('No dapiTh available using nuclei anyways')
        N2 = [N2 , N(kk)];
    end
end

N = N2;

end