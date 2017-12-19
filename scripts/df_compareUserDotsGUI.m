function df_compareUserDotsGUI()

t = 1;
es(t).expName = 'iJC797';
es(t).folderA = '/data/current_images/iJC/iJC797_20170829_001_calc/';
es(t).folderB = '/data/current_images/iJC/iJC797_20170829_001_calc_michi/';

t = 2;
es(t).expName = 'iJC849';
es(t).folderA = '/data/current_images/iJC/iJC849_001_002_calc/';
es(t).folderB = '/data/current_images/iJC/iJC849_001_002_calc_xinge/';

t = 3;
es(t).expName = 'select two calc folders';


esStr = cell(numel(es),1);
for kk = 1:numel(es)
    esStr{kk} = es(kk).expName;
end

[expNum, ~] = listdlg('PromptString','Select an experiment:',...
                      'SelectionMode','single',...
                      'ListString',esStr);
                  

if expNum == 3
    es(expNum).folderA = uigetdir('', 'Select first calc folder');
    es(expNum).folderB = uigetdir(es(expNum).folderB, 'Select second calc folder');
end



expName = es(expNum).expName;
folderA = es(expNum).folderA;
folderB = es(expNum).folderB;

folderA = [folderA filesep()];
folderB = [folderB filesep()];

s.verbose = 0; % change with key 'v'

% To be viewed
s.meta = 1;
s.nuclei = 1;
s.channel = 1;

% Currently viewing
s.currentMeta = -1;
s.currentNuclei = -1; % Number in the big list, not in the meta
s.currentChannel = -1;

s.updateMeta = 1;
s.updateNuclei = 1;
s.updateDots = 1;
s.updateAll = 1;
s.updateImage = 1;
s.showDots = 1;
s.maxFiles = []; % 2


[NA, MA] = df_getNucleiFromNM('folder', folderA, 'maxFiles', s.maxFiles);
[NB, MB] = df_getNucleiFromNM('folder', folderB, 'maxFiles', s.maxFiles);

gui.figure = figure('Name', 'df_compareUserDotsGUI', 'KeyPressFcn', @gui_keys);

gui.nucleiList = uicontrol('Style', 'listbox', ...
    'String', {'1 1 1', '2(1) .4'}, ...
    'Units', 'Normalized', ...
    'Position', [0,.2,.1,.8], ...
    'Callback', @nucChange, ...
    'KeyPressFcn', @gui_keys);

gui.channelList = uicontrol('Style', 'listbox', ...
    'String', {'1 1 1', '2(1) .4'}, ...
    'Units', 'Normalized', ...
    'Position', [0,0,.1,.2], ...
    'Callback', @chanChange, ...
    'KeyPressFcn', @gui_keys);

uicontrol('Style', 'pushbutton', ...
    'String', 'Red', ...
    'Units', 'Normalized', ...
    'Position', [.9,0,.1,.05], ...
    'Callback', @vote);

uicontrol('Style', 'pushbutton', ...
    'String', 'Green', ...
    'Units', 'Normalized', ...
    'Position', [.8,0,.1,.05], ...
    'Callback', @vote);

gui.axis = subplot('Position', [.2, .2, .7, .7]);
gui.image = imagesc(rand(100,100));
axis image
colormap gray

gui.dots = [];


V = zeros(min(numel(NA), numel(NB)),1);

T = compareAllNuclei(NA, MA, MB, NB, s);
T = mean(T,2);

gui_update();

wstring = sprintf('Green:\n%s\n\nRed:\n%s\n', folderA, folderB);
msgbox(wstring);

    function gui_parse()
        n = gui.nucleiList.Value;
        s.meta = NA{n}.metaNo;
        s.nuclei = n; % NA{n}.nucleiNr;
        s.channel = gui.channelList.Value;
        if s.verbose
            s
        end
    end

    function gui_update()
        disp('Loading ...');
        gui_parse();
        
        if s.updateAll
            
            % Update list of nuclei
            strs = cell(min(numel(NA), numel(NB)),1);
            for kk = 1:min(numel(NA), numel(NB))
                strs{kk} = sprintf('F%d N%d C%.2f', NA{kk}.metaNo, NA{kk}.nucleiNr, T(kk));
            end
            gui.nucleiList.String =  strs;
            
            % Update list of channels
            strs = cell(numel(MA{1}.channels),1);
            for kk = 1:numel(MA{1}.channels)
                strs{kk} = MA{1}.channels{kk};
            end
            strs{kk+1} = 'DAPI/ALL';
            
            gui.channelList.String =  strs;
            
            s.updateAll = 0;
        end
        
        if s.currentMeta ~= s.meta
            M = MA{s.meta};
            w = waitbar(0, 'loading images');
            for cc = 1:numel(MA{1}.channels)                
                fName = strrep(MA{s.meta}.dapifile, ...
                    'dapi', ...
                    MA{1}.channels{cc});
                I = df_readTif(fName);
                s.I{cc} = max(I, [], 3);
                waitbar(cc/(numel(MA{1}.channels)+1), w);
            end
            
            cc = cc+1;
            fName = MA{s.meta}.dapifile;
            I = df_readTif(fName);
            s.I{cc} = max(I, [], 3);
            close(w);
            s.updateImage = 1;
            s.currentMeta = s.meta;
            s.currentChannel = -1; % force reload
        end
        
        if s.currentChannel ~= s.channel
            gui.image.CData = s.I{s.channel};
            s.currentChannel = s.channel;
            s.updateDots = 1;
        end
        
        if s.nuclei ~= s.currentNuclei
            subplot(gui.axis)
            bbx = NA{s.nuclei}.bbx;
            axis(bbx([3,4,1,2]));
            s.currentNuclei = s.nuclei;
            s.updateDots = 1;
        end
        
        if s.updateDots
            
                        for kk = 1:numel(gui.dots)
                try
                    delete(gui.dots(kk));
                end
                        end
            if s.showDots
            [da1, da2] = getUserDots(NA, s.currentChannel);
            [db1, db2] = getUserDots(NB, s.currentChannel);
                       
            hold on
            if numel(da1)>0
                gui.dots(1) = plot(da1(:,2), da1(:,1), 'g^');
            end
            if numel(da2)>0
                gui.dots(2) = plot(da2(:,2), da2(:,1), 'gv');
            end
            
            if numel(db1)>0
                gui.dots(3) = plot(db1(:,2), db1(:,1), 'ro');
            end
            if numel(db2)>0
                gui.dots(4) = plot(db2(:,2), db2(:,1), 'rs');
            end
            s.updateDots = 0;
            end
        end
        
        disp('Done loading');
    end

    function nucChange(varargin)
        disp('nucChange');
        s.updateNuclei = 1;
        s.updateMeta = 1;
        s.updateImage = 1;
        s.updateDots = 1;
        gui_update();
    end

    function chanChange(varargin)
        disp('chanChange');
        s.updateDots = 1;
        s.updateImage = 1;
        gui_update();
    end

    function gui_keys(varargin)
        
        key = varargin{2}.Key;
        if s.verbose
            disp('gui_keys');
            key
        end
        
        switch key
            case 'v'
                s.verbose = mod(s.verbose +1, 2);
            case 'w'
                gui.nucleiList.Value = max(1, gui.nucleiList.Value-1);
                gui_update();
            case 's'
                gui.nucleiList.Value = min(min(numel(NA), numel(NB)), gui.nucleiList.Value+1);
                gui_update();
            case 'e'
                gui.channelList.Value = max(1, gui.channelList.Value-1);
                gui_update();
            case 'd'
                gui.channelList.Value = min(numel(MA{1}.channels)+1, gui.channelList.Value+1);
                gui_update();
            case 'space'
                s.showDots=mod(s.showDots+1, 2);
                s.updateDots = 1;
                gui_update();
        end
    end

    function [d1, d2] = getUserDots(N, channel)
        % Return the user dots per allele
        
        if channel > numel(MA{1}.channels)
            channel = 1:numel(MA{1}.channels);
        end
        
        d = [];
        l = [];
        for kk = channel            
            d = [d; N{s.currentNuclei}.userDots{kk}];
            l = [l; N{s.currentNuclei}.userDotsLabels{kk}];
        end
        
        d1 = d(l==1, :);
        d2 = d(l==2, :);
    end

function vote(varargin)
    fprintf('Thanks for voting!\n');
    
    if strcmpi(varargin{1}.String, 'Green')
        V(s.currentNuclei) = 1;
    end
    if strcmpi(varargin{1}.String, 'Red')
        V(s.currentNuclei) = 2;
    end
    
   fprintf('Votes for green: %d\n', sum(V==1));
   fprintf('Votes for red  : %d\n', sum(V==2));    
   uicontrol(gui.nucleiList);
end

end


function [T, Ndots, C] = compareAllNuclei(NA, MA, MB, NB, s)
% Compare the userDots, A vs B
% T: correspondence per channel, one row per nuclei
%    in [0,1]
% C: error types; 
%    0, identical dots (perfect
%    1, A\AcapB OR A\AcapB nonempty (non-serious)
%    2, A\AcapB AND A\AcapB nonempty (serious, different dots preferred)

channels = MA{NA{1}.metaNo}.channels;

ndotsA = zeros(1, numel(channels));
ndotsB = zeros(1, numel(channels));

T = [];
C = [];

for nn = 1:min(numel(NA), numel(NB))
    
    A = NA{nn};
    B = NB{nn};
    
    
    assert(isequal(A.bbx, B.bbx));
    
    dotsA = {[], [], []};
    dotsB = {[], [], []};
    
    for aa = 1:2
        for cc = 1:numel(channels)
            
            dA = A.clusters{aa}.dots{cc};
            if numel(dA) == 0
                dA = zeros(0,3);
            end
            dA = dA(:,1:3);
            dotsA{cc} = [dotsA{cc}; dA];
            
            dB = B.clusters{aa}.dots{cc};
            if numel(dB) == 0
                dB = zeros(0,3);
            end
            dB = dB(:,1:3);
            dotsB{cc} = [dotsB{cc}; dB];
        end
    end
    
    if s.verbose
        for cc = 1:numel(channels)
            disp(MA{1}.channels{cc})
            disp(dotsA{cc})
            disp('vs')
            disp(dotsB{cc})
        end
    end
    
    res = []; typ = 2*ones(1,numel(channels));
    for cc = 1:numel(channels)
        % Number of unique dots in A and B
        u = unique([dotsA{cc}; dotsB{cc}], 'rows');
        nUnique = size(u,1);
        % Number of dots in both
        b = intersect(dotsA{cc}, dotsB{cc}, 'rows');
        inBoth = size(b,1);
        
        % type of error        
        if inBoth == nUnique
            typ(cc) = 0;
        else             
            if isempty(setdiff(dotsA{cc}, b, 'rows')) || isempty(setdiff(dotsB{cc}, b, 'rows'))
                typ(cc) = 1;
            end
        end
        
        if 0
        disp('A')
        dotsA{cc}
        disp('B')
        dotsB{cc}        
        typ(cc)
        end
        %keyboard
        %pause
        
        res = [res, inBoth/nUnique];
        %T = [T; [nUnique, inBoth, size(dotsA,1), size(dotsB,1)]];
        ndotsA(cc) = ndotsA(cc) + size(dotsA{cc},1);
        ndotsB(cc) = ndotsB(cc) + size(dotsB{cc},1);
    end
    T = [T; res];
    C = [C; typ];
end

Ndots = [ndotsA, ndotsB];

% T is nan when there are 0 dots in each, that means perfect correspondence
T(isnan(T)) = 1;
end
