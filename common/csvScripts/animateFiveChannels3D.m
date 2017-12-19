
s.normalize = 1; % Normalize by DAPI diameter

mkdir('videos');

%% Read data from csv and calculate pairwise distances
files = dir('*.csv');

Chan = {'a594', 'cy5', 'cy7', 'gfp', 'tmr'};

D = cell(5,5); % summed distances
res = [131.08, 131.08, 200];

[X,Y,Z] = sphere(10);
FColors = jet(5);

for ff = 1:numel(files)
    fprintf('Loading %s\n', files(ff).name);
    t = readtable(files(ff).name);
    t = table2cell(t);
    
    startPos = 1;
    P = getAllele(t, startPos);
    P = reorderAllele(P, Chan, chan2probe);
    P0=P;
    while numel(P)>0
        startPos = startPos+size(P,1);
        size(P,1)
        if(size(P,1)==5)
            P = cell2mat(P(:,5:7));
            P = P-repmat(P(1,:), size(P,1),1);
            P(:,1) = P(:,1)*res(1);
            P(:,2) = P(:,2)*res(2);
            P(:,3) = P(:,3)*res(3);
            
            D1 = P(2,:)-P(1,:);
            D1 = D1/norm(D1);
            D2 = P(3,:)-P(2,:);
            D2 = D2/norm(D2);
            D2 = D2- D1*(D2*D1');
            D2 = D2/norm(D2);
            D3 = cross(D1,D2);
            
            R = [D1;D2;D3];
            P = (R*P')';
            
            P = P-repmat(min(P)+(max(P)-min(P))/2, size(P,1),1);
            
            v = VideoWriter( sprintf('videos/%03d_%03d_%03d.avi', P0{1,1}, P0{1,2}, P0{1,3}), ...
                'Uncompressed AVI');
            v.FrameRate=24;
            
            fig = figure('Position', 2*[0, 0, 1024, 1024], 'Visible', 'Off');
            open(v);
            for theta=linspace(0,2*pi, 240)
                clf
                hold on
                PT = (rotmatrix3d([theta,0,0])*P')';
                
                for kk = 1:size(P,1)-1
                    plot3( [PT(kk,1) PT(kk+1,1)], [PT(kk,2) PT(kk+1,2)], [PT(kk,3) PT(kk+1,3)], 'k', 'LineWidth', 1.25);
                end
                r = 50;
                for kk = 1:size(P,1)
                    surf('XData', r*X+PT(kk,1), 'YData', r*Y+PT(kk,2), 'ZData', r*Z+PT(kk,3), 'EdgeColor', 'None', 'FaceColor', FColors(kk,:));
                end
                view(3)
                axis equal
                grid on
                camproj('perspective')
                lighting phong
                camlight
                
                w = 1500;
                axis([-w, w, -w, w, -w, w]);
                
                
                drawnow
                frame = getframe;
                frame.cdata(:,:,1) = gsmooth(frame.cdata(:,:,1),1);
                frame.cdata(:,:,2) = gsmooth(frame.cdata(:,:,2),1);
                frame.cdata(:,:,3) = gsmooth(frame.cdata(:,:,3),1);
                frame.cdata = frame.cdata(1:2:end, 1:2:end, :);
                
                writeVideo(v,frame);
                
            end
            close(v);
            close(fig)
        end
        P = getAllele(t, startPos);
        P = reorderAllele(P, Chan, chan2probe);
        P0=P;
    end
end

