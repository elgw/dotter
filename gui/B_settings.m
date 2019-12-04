function sout = B_settings(s)
%% function sout = B_settings(s)
% Presents a gui for some of the settings in B_cells_global.m

gui.win = figure('Position', [300,200,350,650], 'Menubar', 'none', ...
    'NumberTitle','off', ...
    'Name', 'B_cells_global - settings');

gui.cUse = []; % Use channel or not
gui.cNdots = []; % Number of dots
gui.cName = []; % name of channel
sout = [];

gui.FWHM = uicontrol('Style', 'checkbox', 'String', 'FWHM', ...
    'Position', [30,600,100,20], ...
    'Value', s.calculateFWHM);

uicontrol('Style', 'pushbutton', ...
    'String', 'Ok', ...
    'Position',[200 450 60 20], ...
    'Callback', @ok);

    function ok(varargin)
        sout=s;
        sout.calculateFWHM = get(gui.FWHM, 'value');
        uiresume(gcbf); 
    end

    function cancel(varargin)
        uiresume(gcbf);
    end

uiwait(gcf);
close(gui.win);
end

