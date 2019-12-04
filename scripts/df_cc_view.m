function df_cc_view(filename)
% Present a summary of the cc-correction
% publish('df_cc_view.m', struct('codeToEvaluate', 'df_cc_view(''/tmp/test.cc'')', 'showCode', false))

% More statistics could be added, for example some measure on the
% homogeity of dots, i.e., number of cells that has at least a dot
% when the image field is split into 10x10 cells.

fprintf('df_cc_view(''%s'')\n', filename);

cc = load(filename, '-mat');

M = cc.M;
Cx = cc.Cx;
Cy = cc.Cy;
channels = cc.channels;
E = cc.E;



fprintf('\ncc file: %s\n', filename);
fprintf('created %s with DOTTER %s\n', M.creationDate, M.dotterVersion);

fprintf('\n\n2D MSE Errors after correction (pixels):\n\n')
TE = array2table(E, 'VariableNames', channels, 'RowNames', channels);
disp(TE);


if isfield(cc, 'E3')
fprintf('\n\n3D MSE Errors after correction (pixels):\n\n')
TE = array2table(cc.E3, 'VariableNames', channels, 'RowNames', channels);
disp(TE);
end

if isfield(cc, 'E0')
    fprintf('\n\nErrors before correction:\n\n');
    E0 = cell2table( mat2cell(cc.E0, ones(size(cc.E0,1),1), ones(size(cc.E0,1),1)),...
        'VariableNames', channels, 'RowNames', channels);
    disp(E0);
end


D = cell(size(E));
VD = cell(size(E));
for kk = 1:size(Cx,1)
    for ll = 1:size(Cx,2)
        m = [512.5, 512.5, 0];
        mc = df_cc_apply_dots('dots', m, 'from', channels{kk}, 'to', channels{ll}, 'ccFile', filename);
        delta = m-mc;
        D{kk,ll} = sprintf('%.2f', norm(delta));
        VD{kk,ll} = sprintf('[%.2f, %.2f]', delta(1), delta(2));
        if isnan(E(kk,ll))
            D{kk,ll} = '?';
            VD{kk,ll} = '?';
        end
    end
end

fprintf('\n\nDisplacement length in centre (pixels):\n\n')
TD = cell2table(D, 'VariableNames', channels, 'RowNames', channels);
disp(TD);

fprintf('\n\nDisplacement in centre (pixels):\n\n')
TVD = cell2table(VD, 'VariableNames', channels, 'RowNames', channels);
disp(TVD);

if isfield(cc, 'dz')
    fprintf('\n\nAxial displacement (z, in pixels):\n\n');
    TVD = cell2table(cc.dz, 'VariableNames', channels, 'RowNames', channels);
    disp(TVD);
end

if isfield(cc, 'N')
    fprintf('\n\nNumber of dots:\n\n');
    ND = cell2table( mat2cell(cc.N, ones(size(cc.E0,1),1), ones(size(cc.E0,1),1)),...
        'VariableNames', channels, 'RowNames', channels);
    disp(ND);
end


end