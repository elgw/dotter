function fprintff(varargin)
%% function fprintff(fHandle, 'String')
%
% Directs output to both std output and a file
% for logging
%
% Example:
%  f = fopen([datestr(datetime) '.txt']);
%  fprintff(f, 'Hello world\n');
%  fclose(f);

fprintf(varargin{1}, varargin{2:end});
fprintf(varargin{2:end});
end