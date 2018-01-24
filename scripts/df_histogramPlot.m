function df_histogramPlot(varargin)
% A figure that plots a histogram, with some extra features
%
% Example: 
% df_histogramPlot('Data', A, ...
%    'xlabel', xlabelString, ...
%    'ylabel', ylabelString, ...
%    'title', '');


s.xlabelString = '';
s.ylabelString = '';
s.titleString = '';
gs.legendStrings = '';
s.nBins = 0;

for kk = 1:numel(varargin)
    if strcmpi(varargin{kk}, 'data')
        D = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'xlabel')
        s.xlabelString = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'ylabel')
        s.ylabelString = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'title')
        s.titleString = varargin{kk+1};
    end
    if strcmpi(varargin{kk}, 'legend')
        gs.legendStrings = varargin{kk+1};
    end
end

f = figure();

doPlot(f, D, s);


    function doPlot(fig, D, s)
        
        figure(fig)
        clf
        if s.nBins == 0;
            h = histogram(D);
        else
            h = histogram(D, s.nBins);
        end
        grid on
        xlabel(s.xlabelString);
        ylabel(s.ylabelString);
        if(numel(gs.legendStrings)>0)
            legend(gs.legendStrings);
        end
        title(s.titleString);
        
        
        ctx = uicontextmenu(fig);
        fig.UIContextMenu = ctx;
        h.UIContextMenu = ctx;
        set(gca(), 'UIContextMenu', ctx);
        uimenu(ctx,'Label','Save Data','Callback', @saveData);
        uimenu(ctx,'Label','Plot Settings','Callback', @settings);
        
    end

    function settings(varargin)
        snew = StructDlg(s);
        if numel(snew)>0            
            s = snew;
            doPlot(f, D, s)
        end
    end

    function saveData(varargin)
        
        T = array2table(D);
        vname = regexprep(s.xlabelString, ' ', '_');
        vname = regexprep(vname, '[^a-zA-Z_]', '');
        T.Properties.VariableNames = {vname};
        [folder, name] = uiputfile('.csv');
        if ~isnumeric(name)
            fname = [name folder];
            fprintf('Writing to %s\n', fname);
            writetable(T, fname);
        end
    end

end