function s1 = df_structput(s1, s2)
% copy fields of s2 into s1

fnames = fieldnames(s2);
for kk = 1:numel(fnames)
    s1.(fnames{kk}) = s2.(fnames{kk});
end

end