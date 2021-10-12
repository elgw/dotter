function info = dw_parseLog(file)
% Parse a log from deconwolf
% info = dw_parseLog('dw_a594.tif.log.txt')
% 

info.file = file;
fid = fopen(file, 'r');

% Scaling
pat='scaling: (?<scale>[0-9\.]+)';
while ~feof(fid)
    line = fgetl(fid);
    names = regexp(line, pat, 'names');
    if numel(names) == 1
        info.scale = str2num(names.scale);
    end
end

% Time
fseek(fid, 0, -1);
pat='Took: (?<grp>[0-9\.]+) s';
while ~feof(fid)
    line = fgetl(fid);
    names = regexp(line, pat, 'names');
    if numel(names) == 1
        names.grp;
        info.time = str2num(names.grp);
    end
end

% Error
fseek(fid, 0, -1);
pat = '(?<name>\w+)=(?<value>[^,]+)';
while ~feof(fid)
    line = fgetl(fid);
    names = regexp(line, pat, 'names');
    if numel(names) == 1        
        info.error = str2num(names.value);
    end
end

fclose(fid);

end