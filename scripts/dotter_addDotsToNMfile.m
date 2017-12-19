files = dir('*.NM');

for kk = 1:numel(files)
    nmFile = files(kk).name;
    NE = load(nmFile, '-mat');
    if ~isfield(NE.M, 'dots')
        disp(['Updating ' nmFile])        
        NE.M.dots = {};
        
        for channelNo = 1:numel(NE.M.channels)
            filename = NE.M.dapifile;
            filename = strrep(filename, 'dapi', NE.M.channel(channelNo));
            V = df_readTif(filename);
            NE.M.dots{channelNo} = dotCandidates(V);
            M = NE.M; N = NE.N;
            disp('Updating NE file on disk')
            save(nmFile, '-mat', 'N', 'M');
        end
    end
end