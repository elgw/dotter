function th = findThresholdForBestDistribution(Meta, channel)
D = [];
  for kk = 1:numel(Meta.N)
                d = Meta.N{kk}.dots{channel}(:,4); % Dots in this nucleus
                D = [D; d];
            end

[th, ~] = fminbnd(@(x) fun(x), min(D(:)),max(D(:)));

    function e = fun(threshold)
        %keyboard
        DPN = [];
            for kk = 1:numel(Meta.N)
                PN = sum(Meta.N{kk}.dots{channel}(:,4)>=threshold); % Dots in this nucleus
                DPN = [DPN, PN];
            end
            h = double(histo16(uint16(DPN)))';
            e = (1:numel(h))-Meta.M.nTrueDots(channel)-1;
            e = sum(h.*e.^2);            
    end

end


