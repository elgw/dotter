%% Which tif compression works best?

% Compression time
% Unpacking time
% Compression

% original size 85987914
%
% bzip2, 6.6, 3.3,   58796251/85987914
% zip -6,   3.3, 0.6,   141631644/85987914
% zip -9,   3.8, 0.6,   70815837/85987914
% gzip,  3.0, 1.067, 70815694/85987914

%% conclusion
% only bzip2 does a good job in compressing 16 bit tifs at the cost of long
% a computational time.
% I.e., it does not make sense to compress the tif files.