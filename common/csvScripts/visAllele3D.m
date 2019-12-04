cdpwd
files = dir('*.csv');
ff = 2;

record = 1;

t = readtable(files(ff).name);
t = table2cell(t);
P0 = t;
res = [131.08, 131.08, 200];

Chan = {'a594', 'cy5', 'cy7', 'gfp', 'tmr'};

[X,Y,Z] = sphere(10);
FColors = jet(5);

P = cell2mat(t(:,8:10)); % Not the CA-corrected
P = P-repmat(P(1,:), size(P,1),1);
P(:,1) = P(:,1)*res(1);
P(:,2) = P(:,2)*res(2);
P(:,3) = P(:,3)*res(3);

c = (t(:,4));
for kk=1:numel(c)
    c{kk} = find(strcmp(Chan, c{kk})==1);
end
c = cell2mat(c);

P = P-repmat(min(P)+(max(P)-min(P))/2, size(P,1),1);

PT = P;

f=figure('Position', 2*[0, 0, 1024, 1024], 'Visible', 'Off');
hold on
r = 50;
for kk = 1:size(P,1)
    su(kk)=surf('XData', r*X+PT(kk,1), 'YData', r*Y+PT(kk,2), 'ZData', r*Z+PT(kk,3), 'EdgeColor', 'None', 'FaceColor', FColors(c(kk),:));
end
view(3)
axis equal
grid on
camproj('perspective')
lighting phong
camlight
w = 1800;
axis(repmat([-w, w], 1, 3))

if record
    v = VideoWriter( sprintf('%03d_%03d_%03d.avi', P0{1,1}, P0{1,2}, P0{1,3}), ...
        'Uncompressed AVI');
    v.FrameRate=24;
    open(v);
end

for ll=1:240
    for kk=1:size(P,1)
        rotate(su(kk), [0,0,1], 360/240);
        drawnow
    end
    if record
        frame = getframe;
        frame.cdata(:,:,1) = gsmooth(frame.cdata(:,:,1),1);
        frame.cdata(:,:,2) = gsmooth(frame.cdata(:,:,2),1);
        frame.cdata(:,:,3) = gsmooth(frame.cdata(:,:,3),1);
        frame.cdata = frame.cdata(1:2:end, 1:2:end, :);
        
        writeVideo(v,frame);
    end
    
end

if record
    close(v);
end


