function C = df_bcluster(X, r)
    % slower alternative to the compiled df_bcluster
    z = linkage(X, 'single', 'euclidean');
    c = cluster(z,'criterion', 'distance', 'cutoff',r);        
    C = [];
    for kk = 1:max(c(:))
        idx = find(c==kk);
        if numel(idx) > 1
            C = cat(1, C, [idx ; 0]);
        end
    end
    C = C(1:end-1);
end