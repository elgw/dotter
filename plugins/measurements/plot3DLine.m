function plot3DLine(L, radius, color)
for kk=1:size(L,1)
    hold on
    drawCylinder([L(kk,1:3) L(kk,4:6) radius], 16, 'FaceColor', color);% , 'FaceAlpha', 0.5);    
    drawSphere([L(kk,1:3), radius], 'FaceColor', color);
    drawSphere([L(kk,4:6), radius], 'FaceColor', color);
    plot3([L(kk,1), L(kk,4)], [L(kk,2), L(kk,5)], [L(kk,3), L(kk,6)]);
end
view(3)
axis equal
end