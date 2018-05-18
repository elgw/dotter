function df_manageOverlapping()
%% Find dots that overlap from different channels

%% Options

s.radius = 200; % nm

%% Read NM files

folder = df_getConfig('manageOverlap', 'folder', '~/');
s.folder = uigetdir(folder)
if isnumeric(s.folder)
    error('No folder given');
    return
end
df_setConfig('manageOverlap', 'folder', s.folder);

[N, M] = df_getNucleiFromNM('folder', s.folder);

%% Open GUI
keyboard
figure,
hold on
c = jet(numel(M{1}.channels));
for kk = 1:numel(M{1}.channels)
    dots = M{1}.dots{kk};
    dots = dots(1:100,:);
    x = dots(:,2);
    y = dots(:,1);
    z = dots(:,3);
    plot3(x, y, z, 'o', 'Color', c(kk,:))
end

%{

I think that we don't need to know what points can be mapped to what other
points, just want to see what points are well separated from all other
points. That can probably be achieved by a small change to volbucket.

%}

end

function applyToFile(file, s)

end