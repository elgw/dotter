function df_printstruct(s, fid, varargin)
% df_printstruct(struct s, file descriptor fid)
% prints the content of s on in the terminal or to
% an optional file descriptor.
% Please extend me to support more complex structs!
%
% Example:
% s.name = 'John Doe'
% s.age = 52
% s.data = [5, 7, 3.14]
% df_printstruct(s)
% 'name'	'John Doe'
% 'age'	[52.000000]
% 'data'	[5.000000, 7.000000, 3.140000]
Sep = '\t';

if ~exist('fid', 'var')
    fid = 1; % stdout
end

names = fieldnames(s);

method = 0; 

for kk = 1:numel(varargin)
    if(strcmpi(varargin{kk}, 'row') == 1)
        method = 1;
    end
	if(strcmpi(varargin{kk}, 'header') == 1)
        method = 2;
    end
end

if method == 0
for kk = 1:numel(names)
    printcontent(names{kk}, Sep, s.(names{kk}), fid);
end
end

if method == 1
    printrow(names, Sep, s, fid);
end

if method == 2
    printheader(names, Sep, s, fid)
end

end

function printrow(names, Sep, s, fid)
for kk = 1:numel(names)
    printcell(s.(names{kk}), fid);
    if kk == numel(names)
        fprintf(fid, '\n');
    else
        fprintf(fid, Sep);
    end
end
end

function printheader(names, Sep, s, fid)
for kk = 1:numel(names)
    printcell(names{kk}, fid);
    if kk == numel(names)
        fprintf(fid, '\n');
    else
        fprintf(fid, Sep);
    end
end
end

function printcell(value, fid)
if isa(value, 'char')
    fprintf(fid, '''%s''',  value);
end
if isnumeric(value)
    fprintf(fid, '%f', value);
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
    