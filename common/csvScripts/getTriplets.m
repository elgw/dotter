function T = getTriplets(aProbeNr, aCoord, probes)
% Return a struct with all possible consequtive probes of three

% aChan : maps row to probeNr
% probes: possible probes

probes = sort(probes);

ntrip = 0;
T = [];

for kk = 1:numel(probes)-2
    
    want = probes(kk:kk+2);
    if sum(ismember(want, aProbeNr)) == 3
        ntrip = ntrip+1;
        T{ntrip}.p = aCoord(find(aProbeNr==probes(kk)), :);
        T{ntrip}.q = aCoord(find(aProbeNr==probes(kk+1)), :);
        T{ntrip}.r = aCoord(find(aProbeNr==probes(kk+2)), :);
        T{ntrip}.probes = probes(kk:kk+2);
    end
end
end