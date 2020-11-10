function df_nm_save(M, N, filename)
% function df_nm_save(M, N, filename)
% Save M and N to filename
% First writes to <filename>.tmp
% Upon success it moves <filename>.tmp to <filename>

if ~isa(filename, 'char')
    error('The file name has to be of class ''char''');
end

if ~contains(filename, '.NM')
    warning('File name does not contain ''.NM''');
end

if ~isa(M, 'struct')
    error('M has to be a struct')
end

if ~isa(N, 'cell')
    error('N as to be a cell')
end

tempfile = [filename '.tmp'];
save(tempfile, 'M', 'N');
[status,msg,msgID] = movefile(tempfile, filename);
if(status ~= 1)
    error('Failed to move %s to %s\n msgID: %s, msg: %s', tempfile, filename, msg, msgID);
end

end