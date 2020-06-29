function df_writeTable(tab, fname)
% Similar like writetable but overcomes the issue that
% values sometimes are rounded
% However this function is more limited in terms of functionality
% Only supports {'char'} and 'double' cells.

props = tab.Properties.VariableNames;

fid = fopen(fname, "w");
for kk = 1:numel(props)-1
    fprintf(fid, '%s,', props{kk});
end
fprintf(fid, '%s\n', props{end});


propsClass = {};
for kk = 1:size(tab, 2)
    pcell = tab{1,kk};
    if isa(pcell, 'cell')
        propsClass{kk} = class(pcell{1});
    else
        propsClass{kk} = class(pcell);
    end
end

nCols = numel(propsClass);
for kk = 1:size(tab,1)
    for pp = 1:nCols-1
        writeCell(fid, tab{kk,pp}, propsClass{pp});
        fprintf(fid, ',');
    end
    writeCell(fid, tab{kk,nCols}, propsClass{nCols});
    fprintf(fid, '\n');    
end

fclose(fid);

end

function writeCell(fid, acell, pclass)
if( strcmp(pclass, 'char') )
    fprintf(fid, '%s', acell{1});
end
if( strcmp(pclass, 'double') )
    if iscell(acell)
        fprintf(fid, '%.3f', acell{1});
    else
        fprintf(fid, '%.3f', acell);
    end
end

end