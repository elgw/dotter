function gm = ggm(I, s)
%% function gm = ggm(I, s)
% Gradient magnitude using gaussian derivative filters
% I: 2D image, s: sigma
% uses gpartial for derivatives

dx = gpartial(I, 1, s);
dy = gpartial(I, 2, s);
gm = (dx.^2+dy.^2).^(1/2);

