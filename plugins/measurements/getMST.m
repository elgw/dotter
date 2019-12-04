function P = getMST(D)
% Calculates the minimal spanning tree in D
% Returns P, all paths in the graph (not sorted/connected in any way)
% each row in P desribes a line segment by from x,y,z, to x,y,z

g_mst = graphminspantree(sparse(squareform(pdist(D, 'euclidean'))));
P = [];
for aa = 1:size(g_mst,1)
    for bb = 1:size(g_mst,2)
        if(g_mst(aa,bb))>0
            P = [P; [D(aa,:), D(bb,:)]];
        end
    end
end

end