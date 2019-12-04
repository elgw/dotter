% Coordinate box for volume rendering
% Extremely slow, but this is how it can be done... directly on GPU
% For cpu- To rotate the volume first is likely to be much better.
% Dirk-Jan Kroons code seems good at this. Cris has also some good code.

% Need to capture coordinate box with more than 8 bit resolution!
% Use view() to get the transformation matrix instead maybee.



close all

%V=df_readTif('~/data/310715_iMB2/a594_001.tif');
%V = double(V(1000:1050, 1000:1050, :));

bbx = [0, 50, 0, 50, 0, 50];
vertices = [ 0 0 0
             1 0 0 
             0 1 0
             1 1 0 % Top
             0 0 1
             1 0 1
             0 1 1 
             1 1 1 ]; % bottom

faces = [1, 2, 3; 2 3 4 ; ... % Top
         5, 6, 7; 6 7 8]; % Bottom
     % Left 
     % Right
     % Front
     % Back
         
for kk = 1:3
    vertices(:,kk) = vertices(:,kk)*(bbx(2*kk)-bbx(2*kk-1));
    vertices(:,kk) = vertices(:,kk)+bbx(2*kk-1);
end

figure
view(-35,68)
axis off
p = patch('Faces', faces(1:2,1:3), 'Vertices', vertices, ...
            'FaceColor', 'Interp', ...
            'FaceVertexCData', vertices, ...
            'EdgeColor', 'none') 
        hold on
p = patch('Faces', faces(3:4,1:3), 'Vertices', vertices, ...
            'FaceColor', 'Interp', ...
            'FaceVertexCData', vertices, ...
            'EdgeColor', 'none');      

pause
[a, b]=view();
t1 = [cos(a), 0, -sin(a), 0;0, 1, 0, 0; sin(a), 0, cos(a), 0; 0,0,0,1];
t2 = [1, 0, 0, 0; 0, cos(b), -sin(b), 0; 0, sin(b), cos(b), 0; 0,0,0,1];
T = affine3d(t1*t2);
v = view
v(1:3,4)=0;
v(4,1:3)=0;

T = affine3d(v);
V2 = imwarp(V, T);
V2t = imwarp(1+0*V, T);
figure, imagesc(sum(V2, 3)./sum(V2t, 3))

pause
figure         
view(a,b)
axis off
p = patch('Faces', faces(1:2,1:3), 'Vertices', vertices, ...
            'FaceColor', 'Interp', ...
            'FaceVertexCData', vertices, ...
            'EdgeColor', 'none') 
        hold on

        c1 = getframe(); % 8 bit...
        c1 = c1.cdata;

figure
view(a,b)
axis off
p = patch('Faces', faces(3:4,1:3), 'Vertices', vertices, ...
            'FaceColor', 'Interp', ...
            'FaceVertexCData', vertices, ...
            'EdgeColor', 'none');      

c2 = getframe(); % 8 bit...
c2 = c2.cdata;
        
figure
x1 = c1(:,:,1); x1 = double(x1(:))/255*50;
x2 = c2(:,:,1); x2 = double(x2(:))/255*50;
y1 = c1(:,:,2); y1 = double(y1(:))/255*50;
y2 = c2(:,:,2); y2 = double(y2(:))/255*50;
z1 = c1(:,:,3); z1 = double(z1(:))/255*50;
z2 = c2(:,:,3); z2 = double(z2(:))/255*50;
I = double(0*c1(:,:,1));
for kk = 1:numel(x1)
    progressbar(kk, numel(x1))
    if((abs(z1(kk)-z2(kk))+abs(x1(kk)-x2(kk)))>0)
    lx = linspace(x1(kk), x2(kk), 10);
    ly = linspace(y1(kk), y2(kk), 10);
    lz = linspace(z1(kk), z2(kk), 10);
    t = interpn(V, lx, ly, lz, 'nearest');
    I(kk) = max(t(:));
    end
end

figure, imagesc(reshape(I, size(c2,1), size(c2,2)))
colormap gray
