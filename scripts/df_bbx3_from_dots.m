function bbx = df_bbx3_from_dots(D, radius)
% Create a bounding box based on a set of dots and a radius

bbx = zeros(1,6);
for kk = 0:2
    bbx(2*kk+1) = min(D(:,kk+1)) - radius;
    bbx(2*kk+2) = max(D(:,kk+1)) + radius;
end

end