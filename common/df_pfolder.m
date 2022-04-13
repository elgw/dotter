function f = df_pfolder(file)
% function f = df_pfolder(file)
% Return the parent folder name of a file
% I.e. returns c for '/a/b/c/file'

f = dir(file);
f = strsplit(f.folder, filesep());
f = f{end};

end