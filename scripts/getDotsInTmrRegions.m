function [D1, D2, status] = getDotsInTmrRegions(M, N, nucnum, channum)
%% Return the dots in cell nucnum and channel channum that are in the two distinct regions of 
% tmr in the cells

% Conditions:
% I. dots have to be withing dapi, but dapi is dilated a little which makes
% this a somewhat soft condition
% II. dots are associated to the closest tmr-region if close to more than
% one
% Status:
% 0: Didn't find enought number of dots in any homolog
% 1: One homolog ok
% 2: Both homologs ok

testing = 0;
if testing
nucnum = 2;
channum = 1;
end

% Settings
dapidilation = 4;
tmrdilation = 10;

%%
allDots = N{nucnum}.dots{channum};

%% 
if 0
ichannel = df_readTif(strrep(M.dapifile, 'dapi', M.channels{channum}));
allDots(:,4) = interpn(convn(ichannel, M.PSF, 'same'), allDots(:,2), allDots(:,1), allDots(:,3), 'linear');
[~, idx] = sort(allDots);
end


mask0 = M.mask == nucnum;
mask = imdilate(mask0, strel('disk', dapidilation));

reg1 = mask.*M.mask_regions == 1;
reg2 = mask.*M.mask_regions == 2;

reg1 = bwdist(reg1);
reg2 = bwdist(reg2);

D{1} = [];
D{2} = [];

dotNo = 1;
status = 0;

while size(D{1},1)<M.nTrueDots(channum)/2 || size(D{2},1)<M.nTrueDots(channum)/2
    if dotNo> size(allDots,1)          
        break
    end
    dot = allDots(dotNo, :);
    
    % distance to tmr regions
    d(1) = interpn(reg1, dot(1), dot(2));
    d(2) = interpn(reg2, dot(1), dot(2));
    
    reg = find(d == min(d));
    reg = reg(1);
    
    if d(reg)<tmrdilation
        D{reg} = [D{reg} ; dot];        
    end
    dotNo = dotNo+1;
end

D1 = D{1};
D2 = D{2};

status = 0;
if size(D1,1)>= M.nTrueDots(channum)/2
    status = 1;
end
if size(D2,1)>= M.nTrueDots(channum)/2
    status = 1;
end

if size(D1,1)>= M.nTrueDots(channum)/2
    if size(D2,1)>= M.nTrueDots(channum)/2
        status = 2;
    end
end


end