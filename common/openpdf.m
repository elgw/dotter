function openpdf(filename)
%% function openpdf(filename)
% extends matlab's open for files that end with .pdf

if isunix
    eval(['!evince ' filename])
end

if ismac
    eval(['!open ' filename])
end


end