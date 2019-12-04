function [M, N] = d_filter_dots(M, N)

% z-padding - remove dots within padding distance from the top and bottom
padding = 3;
for kk = 1:numel(N)
    for cc = 1:numel(N{kk}.dots) 
       dots = N{kk}.dots{cc};
       %fprintf('%d -- ', size(dots,1));
       dots = dots(dots(:,3)>padding, :);
       dots = dots(dots(:,3)<M.imageSize(3)-padding+1, :);
       N{kk}.dots{cc} = dots;
       %fprintf('%d\n', size(dots,1));
    end
end

end