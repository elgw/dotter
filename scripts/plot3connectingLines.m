function plot3connectingLines(X, Y, Z, bbx)

for kk=1:numel(X)
    % connect to X, Y and Z    
    %plot3([X(kk), bbx(3)], [Y(kk), Y(kk)], [Z(kk), Z(kk)], 'r:')
    %plot3([X(kk), X(kk)], [Y(kk), bbx(2)], [Z(kk), Z(kk)], 'r:')
    plot3([X(kk), X(kk)], [Y(kk), Y(kk)], [Z(kk), 1], 'w:')
    
end
