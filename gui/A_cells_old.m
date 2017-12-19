
if 0
    folder = '/Users/erikw/data/121212/'; % w. trailing /
    s.channels = {'a594', 'cy5', 'gfp'};
    s.nTrueDots = [2, 2]; % Total number of true signals per cell in G1
end

if 0
    folder = '/Users/erikw/data/iEG40_211019_001/'; % w. trailing /
    s.channels = {'a594', 'cy5', 'tmr'};
    s.nTrueDots = [2, 2, 2]; % Total number of true signals per cell in G1
end

if 0
    folder = '/Users/erikw/data/iEG40_211019_004/'; % w. trailing /
    s.channels = {'a594', 'cy5', 'tmr'};
    s.nTrueDots = [2, 2, 2]; % Total number of true signals per cell in G1
end

if 0
    folder = '/Users/erikw/data/iEG45_281015_001/'; % w. trailing /
    s.channels = {'a594', 'cy5'};
    s.nTrueDots = [2, 2, 2]; % Total number of true signals per cell in G1
end

if 0
    folder = '/Users/erikw/data/iEG43_281015_002/'; % w. trailing /
    s.channels = {'a594', 'cy5', 'tmr'};
    s.nTrueDots = [2, 2, 2]; % Total number of true signals per cell in G1
end

if 0
    folder = '/Users/erikw/Desktop/iEG38_141015_001/'; % w. trailing /
    s.channels = {'a594', 'cy5', 'tmr'};
    s.nTrueDots = [2, 2, 2]; % Total number of true signals per cell in G1
end

if 0
    folder = '/Users/erikw/data/iEG60_021115_001/'; % w. trailing /
    s.channels = {'a594', 'cy5', 'tmr'};
    s.nTrueDots = [2, 2, 2]; % Total number of true signals per cell in G1
end

if 0
    folder = '/Users/erikw/data/iJC99_041115_003/'; % w. trailing /
  %  s.channels = {'a594', 'cy5', 'tmr'};
    s.nTrueDots = [2, 2]; % Total number of true signals per cell in G1
end

if 0
    folder = '/Users/erikw/Desktop/111212/cc/'; % w. trailing /
    s.channels = {'a594', 'cy5', 'tmr'};
    s.nTrueDots = [4, 3, 4]; % Total number of true signals per cell in G1
end

if 0
    folder = '~/Desktop/200912/200912_Chr1_Chr17_iPhase/cc/'; % w. trailing /
    s.channels = {'a594', 'cy5'};
    s.nTrueDots = [4, 3, 4]; % Total number of true signals per cell in G1
end


%iJC80_071015_002	iJC82_071015_001	iJC84_071015_004	iJC85_071015_004
%iJC81_071015_001	iJC84_071015_001	iJC85_071015_001
%iJC81_071015_002	iJC84_071015_002	iJC85_071015_002
%iJC81_071015_003	iJC84_071015_003	iJC85_071015_003

if 0
    folder = '/Users/erikw/data/iJC80-85/iJC85_071015_003/'; % w. trailing /
    %s.channels = {'cy5'};
    s.nTrueDots = [1,1,1]; % Total number of true signals per cell in G1
end

if 0
    folder = '/Users/erikw/data/combinatorial/'; % w. trailing /
    s.nTrueDots = [1,1,1]; % Total number of true signals per cell in G1
end



if 0
    wfolder = '/Users/erikw/data/iJC80-85/iJC80_071015_002_calc/'
    wfolder = '/Users/erikw/data/iJC80-85/iJC81_071015_001_calc/'
    wfolder = '/Users/erikw/data/iJC80-85/iJC81_071015_002_calc/'
    wfolder = '/Users/erikw/data/iJC80-85/iJC81_071015_003_calc/'
    wfolder = '/Users/erikw/data/iJC80-85/iJC82_071015_001_calc/'
    wfolder = '/Users/erikw/data/iJC80-85/iJC84_071015_001_calc/'
    wfolder = '/Users/erikw/data/iJC80-85/iJC84_071015_002_calc/'
    wfolder = '/Users/erikw/data/iJC80-85/iJC84_071015_003_calc/'
    wfolder = '/Users/erikw/data/iJC80-85/iJC84_071015_004_calc/'
    wfolder = '/Users/erikw/data/iJC80-85/iJC85_071015_001_calc/'
    wfolder = '/Users/erikw/data/iJC80-85/iJC85_071015_002_calc/'
    wfolder = '/Users/erikw/data/iJC80-85/iJC85_071015_003_calc/'
    wfolder = '/Users/erikw/data/iJC80-85/iJC85_071015_004_calc/'
    s.nTrueDots = [2, 2];
end

if 0
    wfolder = '/Users/erikw/data/iJC80-85/iJC81_071015_001_calc/'
    dapival = 2*10^8;
end

if 0
    wfolder = '/Users/erikw/data/iJC80-85/iJC81_071015_002_calc/'
    dapival = 2*10^8;
end

if 0
    wfolder = '/Users/erikw/data/121212_calc/'
    dapival = 4*10^9;
    s.nTrueDots = [4 4 4]; % Will overwrite M.nTrueDots
end

if 0
    wfolder = '/Users/erikw/data/iEG40_211019_002_calc/'
    dapival = .75*10^10;
end

if 0
    wfolder = '/Users/erikw/data/combinatorial_calc/'
    s.nTrueDots = [8 8 6 2]; % Will overwrite M.nTrueDots
end

if 0
wfolder = '/Users/erikw/data/iEG41_281015_002_calc/'
s.nTrueDots = [2,2,2];
end
if 0
wfolder = '/Users/erikw/data/iEG43_281015_002_calc/'
s.nTrueDots = [2,2,2];
end

if 0
wfolder = '/Users/erikw/data/iEG45_281015_001_calc/'
s.nTrueDots = [2,2,2];
end

if 0
wfolder = '/Users/erikw/data/iJC99_041115_004_calc/';
s.nTrueDots = [2,2];
end

if 0
    wfolder = '/Users/erikw/Desktop/111212/cc_calc/'; % w. trailing /
    s.channels = {'a594', 'cy5', 'tmr'};
    s.nTrueDots = [4, 3, 4]; % Total number of true signals per cell in G1
end
if 1
    wfolder = '~/Desktop/200912/200912_Chr1_Chr17_iPhase/cc_calc/';
    s.channels = {'a594', 'cy5'};
    s.nTrueDots = [10,10];
end

%iJC80_071015_002	iJC82_071015_001	iJC84_071015_004	iJC85_071015_004
%iJC81_071015_001	iJC84_071015_001	iJC85_071015_001
%iJC81_071015_002	iJC84_071015_002	iJC85_071015_002
%iJC81_071015_003	iJC84_071015_003	iJC85_071015_003

