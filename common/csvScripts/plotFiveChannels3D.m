
s.normalize = 1; % Normalize by DAPI diameter

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
        
        %% Reorder P to reflect the correct order of the dots
        
        
    startPos = startPos+size(P,1);
    size(P,1)
    if(size(P,1)==5)
        P = cell2mat(P(:,5:7))
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
        
        figure
        hold on
        for kk = 1:size(P,1)-1
            plot3( [P(kk,1) P(kk+1,1)], [P(kk,2) P(kk+1,2)], [P(kk,3) P(kk+1,3)], 'k', 'LineWidth', 1.25);
        end
        r = 50;
        for kk = 1:size(P,1)
            surf('XData', r*X+P(kk,1), 'YData', r*Y+P(kk,2), 'ZData', r*Z+P(kk,3), 'EdgeColor', 'None', 'FaceColor', FColors(kk,:));
        end
        %plot3(P(:,1), P(:,2), P(:,3), 'o')
        if 1
        
            view(3)
        axis equal
        grid on
        camproj('perspective')
        rotate3d
        lighting phong
        camlight
            
        w = 1500;
        axis([-w, w, -w, w, -w, w]);
        mkdir('fives')
        
        drawnow
          set(gcf,'Units','centimeters',...
            'PaperUnits', 'centimeters', ...
            'PaperSize',[10 10], ...
            'PaperPosition', [0,0,10,10], ...
            'PaperPositionMode', 'Manual')
        
         drawnow
         drawnow
        
        print('-dpdf', sprintf('fives/pairs_%03d_%03d_%03d.pdf', P0{1,1}, P0{1,2}, P0{1,3}))
        end
    end 
     P = getAllele(t, startPos);  
     P = reorderAllele(P, Chan, chan2probe);
     P0=P;
    end
end
