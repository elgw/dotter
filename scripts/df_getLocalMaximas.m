function [PX, PY, PZ, Pos] = df_getLocalMaximas(Image, conn)
% function [PX, PY, PZ,  Pos] = df_getLocalMaximas(Image, conn)
% Get local maximas in the 3D Image using connectivity (conn)
% 6  -- faces connected to the centre)
% 18 -- no corners
% 26 -- all surrounding pixels (default)

if ~exist('conn', 'var')
    conn = 26;
end

assert(ismember(conn, [6, 18, 26]))

switch(conn)
    case 26
        sel = ones(3,3, 3);
    case 18
        sel = ones(3, 3, 3);
        for a = [1,3]
            for b = [1,3]
                for c = [1,3]
                    sel(a, b, c) = 0;
                end
            end
        end
    case 6
        sel = zeros(3,3, 3);
        sel(:, 2, 2) = 1;
        sel(2, :, 2) = 1;
        sel(2, 2, :) = 1;        g
end

sel(2, 2, 2) = 0; % exclude centre
assert(sum(sel(:)) == conn);

D = imdilate(Image, strel('arbitrary', sel));
D = clearBoarders(D, 1, Inf);
Pos = find(Image>D);
[PX, PY, PZ]=ind2sub(size(Image), Pos);

end