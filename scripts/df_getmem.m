function kb = getmem()
pid = feature('getpid');
statusfile = sprintf('/proc/%d/status', pid);
fid = fopen(statusfile, 'r');
while 1
    line = fgetl(fid);
    if ~ischar(line), break, end
    if contains(line, 'VmPeak')
        kb = line;
        fclose(fid);
        return;
    end
end
fclose(fid);
kb = 'unknown'
end