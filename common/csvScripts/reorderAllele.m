function P = reorderAllele(P, Chan, chan2probe)
if size(P,1)>1
for kk = 1:size(P,1)
    probe(kk) = chan2probe(find(strcmp(P{kk,4}, Chan)==1));
end

[~, probe] = sort(probe);

P = P(probe,:);
end