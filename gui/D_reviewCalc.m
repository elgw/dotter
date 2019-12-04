function D_reviewCalc()

[file, folder]= uigetfile('*.NM');

load([folder file], '-mat');
s.mask = M.mask;

dotterSlide(df_readTif(M.dapifile), [], [], s);

s.NMfile = [folder file];

for cc = 1:numel(M.channels)
    iChannel = df_readTif(M.channelf{cc});
    
    D = [];
    for nn = 1:numel(N)
        D = [D ; N{nn}.dots{cc}];
    end
    [~,I] = sort(D(:,4), 'descend');
    DS = D(I,:);
    s.title = M.channels{cc};
    s.channelNo = cc;
    dotterSlide(iChannel, DS, [], s);
    
end
end