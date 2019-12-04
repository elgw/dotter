function gm = ggm(I, s)
%% function gm = ggm(I, s)
% Gradient magnitude using gaussian derivative filters
% I: 2D or 3D image, s: sigma (default: 1)
% uses gpartial for derivatives

if ~exist('s', 'var')
    s = 1;
end

if size(I,3)==1
    dx = gpartial(I, 1, s);
    dy = gpartial(I, 2, s);
    gm = (dx.^2+dy.^2).^(1/2);
end

if size(I,3)>1
    dx = gpartial(I, 1, s);
    dy = gpartial(I, 2, s);
    dz = gpartial(I, 3, s);
    gm = (dx.^2+dy.^2+dz.^2).^(1/2);
end

end

