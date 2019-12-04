function D = df_rescale_dots(D, psize)
%% function D = df_rescale_dots(D, psize)
% Example d = df_rescale_dots(M.dots{1}, [130,130,300]);
if numel(D)==0
    return
end

for kk = 1:3
    D(:,kk) = D(:,kk)*psize(kk);
end

end