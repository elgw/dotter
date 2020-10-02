function df_nm_save(M, N, filename)
% function df_nm_save(M, N, filename)
% Save M and N to filename
% First writes to <filename>.tmp
% Upon success it moves <filename>.tmp to <filename>

assert(isa(N, 'cell'))
assert(isa(M, 'struct'))

    tempfile = [filename '.tmp'];
    save(tempfile, 'M', 'N');
    [status,msg,msgID] = movefile(tempfile, filename);
    if(status ~= 1)
       error('Failed to move %s to %s\n msgID: %s, msg: %s', tempfile, filename, msg, msgID);        
    end
    
end