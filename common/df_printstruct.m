function printstruct(s, fid)

Sep = '\t';

if ~exist('fid', 'var')
    fid = 1; % stdout
end

names = fieldnames(s);

for kk = 1:numel(names)
    printcontent(names{kk}, Sep, s.(names{kk}), fid);
end

end

function printcontent(Name, Sep, Value, fid)

fprintf(fid, ['''%s''' Sep], Name);
    
if isa(Value, 'char')
    fprintf(fid, '''%s''',  Value);
end

if isnumeric(Value)
    fprintf(fid, '[');
   for kk = 1:numel(Value)
       fprintf(fid, '%f', Value(kk));
       if kk < numel(Value)
           fprintf(fid, ', ');
       end
   end   
   fprintf(fid, ']');
end

fprintf(fid, '\n');
end
    