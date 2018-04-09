function [M,N] = df_nm_load(fileName)

D = load(fileName, '-mat');

if ~isfield(D, 'M')
    error('No meta data available');
end

if ~isfield(D, 'N')
    error('No nuclei available');
end

M = D.M;
N = D.N;

end
