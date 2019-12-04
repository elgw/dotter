function df_bbx3_intersection_ut()

disp(' -> Self intersection is unity, 2 bbx')
bbx = [-1, 1, -1, 1, -1, 1];
[v, ibbx] = df_bbx3_intersection([bbx; bbx])
assert(abs(v-8)<10e-9);
assert(abs(max(bbx-ibbx))<10e-9);

disp(' -> Self intersection is unity, 3 bbx')
bbx = [-1, 1, -1, 1, -1, 1];
[v, ibbx] = df_bbx3_intersection([bbx; bbx; bbx])
assert(abs(v-8)<10e-9);
assert(abs(max(bbx-ibbx))<10e-9);


disp(' -> No intersection')
bbx = [-1, 1, -1, 1, -1, 1];
[v, ibbx] = df_bbx3_intersection([bbx; 2+bbx]);
assert(abs(v)<10e-9);

s.plot = 0;

if s.plot    
        figure
        bbx1 = 1.5*[-1, 1, -1, 1, -1, 1];
        bbx2 = 0.8*[-1, 1, -1, 1, -1, 1];                                
        subplot(1,2,1)
        
        plot_bbx(bbx1);
        plot_bbx(bbx2);
        view(3)
        axis equal
        axis(2*[-1,1,-1,1,-1,1])                
        subplot(1,2,2)
        bbx1
        bbx2
        [v, bbxi] = df_bbx3_intersection([bbx1; bbx2])
        plot_bbx(bbxi);
        view(3)
        axis equal
        axis(2*[-1,1,-1,1,-1,1])        
end

end



function plot_bbx(bbx)

% 8 Corners
V = [bbx(1), bbx(3), bbx(5) ; % top layer, low x
    bbx(1), bbx(3), bbx(6) ;
    bbx(1), bbx(4), bbx(5) ;
    bbx(1), bbx(4), bbx(6) ;
    bbx(2), bbx(3), bbx(5) ; % bottom layer, high x
    bbx(2), bbx(3), bbx(6) ;
    bbx(2), bbx(4), bbx(5) ;
    bbx(2), bbx(4), bbx(6)];

% 6 sides, 2 triangles each
F = [ ...
    1, 2, 4; % top - 1 2 3 4
    1, 4, 3;
    5, 6, 8; % bottom 5 6 7 8
    5, 8, 7
    1, 5, 7 % left 1 3 5 7
    1, 3, 7
    2, 6, 8 % right 2 4 6 8
    2, 8, 4
    1, 2, 5
    2, 6, 5
    3, 4, 7
    4, 8, 7];

patch('Faces', F, 'Vertices', V, 'EdgeColor', 'none', 'FaceColor', 'c');
camlight


end