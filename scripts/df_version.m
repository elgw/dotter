function v = df_version()
% Returns the version number of DOTTER

F = fopen('dotterCommitNumber');
cn = fread(F);
v = cn(1:end-1);
fclose(F);

v = sprintf('0.%s',  v);
end