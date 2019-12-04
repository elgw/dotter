function P = getCell(T, startPos)
% Scans the table for a cell and returns it

if startPos>size(T,1)
    P = [];
    return;
end


s = 1;
cont = 1;
while cont && startPos+s <= size(T,1)
if T{startPos+s,1}==T{startPos,1} && ...
        T{startPos+s,2}==T{startPos,2}        
s = s+1;
else
    cont = 0;
end
end

P = T(startPos:startPos+s-1, :);    
end    
