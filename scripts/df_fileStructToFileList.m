function flist = df_fileStructToFileList(files)

for kk = 1:numel(files)
    flist{kk} = files(kk).name;
end

end