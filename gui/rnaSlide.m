function rnaSlide(nmFile)
% function rnaSlide(nmFile)
% Loads an NM file corresponding to a RNA-FISH experiment and shows
% detected dots and segmented cells.
% Call without arguments to get a file dialogue.
        
if ~exist('nmFile', 'var')
    disp('Select a NM');
    rnaSlide_folder = df_getConfig('DOTTER', 'rnaSlide_folder', [pwd '/']);
    disp([rnaSlide_folder '*.NM']);
    [nmFile, folder] = uigetfile([rnaSlide_folder '*.NM']);
    if ~isnumeric(folder)
        df_setConfig('DOTTER', 'rnaSlide_folder', folder);
        nmFile = [folder nmFile];
    else
        disp('No NM-file selected')
        return
    end
end

if isnumeric(nmFile)
    disp('No file selected, quiting')
    return
end


NE = load(nmFile, '-mat');

channel = selectChannel(NE);

disp([channel ' selected']);
cFile = strrep(NE.M.dapifile, 'dapi', channel);
disp(['opening ' cFile])

if exist(cFile, 'file')
    V = df_readTif(cFile);
else
    warndlg('The tif file could not be found. If it was moved, try relocating it');
    return
end

% Fix this to work with samples with more than one channel
findDots = 0;
if ~isfield(NE.M, 'dots')
    findDots = 1;
else
    if numel(NE.M.dots) < channelNo
        findDots = 1;
    else
        if numel(NE.M.dots{channelNo})<1
            findDots = 1;
        end
    end
end

if findDots
    disp('No dots in meta data, finding them')
    if ~isfield(NE.M, 'dots')
        NE.M.dots = {};
    end
    NE.M.dots{channelNo} = dotCandidates(V);
    M = NE.M; N = NE.N;
    disp('Updating NE file on disk')
    save(nmFile, '-mat', 'N', 'M');
    clear M
    clear N
end



s.mask = NE.M.mask;
s.cFile = cFile;
s.NMfile = nmFile;
s.channelNo = channelNo;

dotterSlide(V, NE.M.dots{channelNo}, [], s);

function channel = selectChannel(NE)
% Select a channel among those listed in NE.M.channels
if numel(NE.M.channels)>1
    disp('Select a channel')
    channelNo = listdlg('PromptString', 'Select a channel', 'ListString', NE.M.channels);
    channel = NE.M.channels{channelNo};
else
    channelNo = 1;
    channel = NE.M.channels{1};
end
end

end