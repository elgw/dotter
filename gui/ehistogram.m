function h = ehistogram(varargin)
% function h = ehistogram(varargin)
% Plot histogram and allow saving of the underlying data.

xlabelString = '';
ylabelString = '';
titleString = '';
legendString = '';
D = [];

domain = [];

for kk = 1:numel(varargin)
    if strcmp(varargin{kk}, 'data')
        D = varargin{kk+1};
    end
    
    if strcmp(varargin{kk}, 'xlabel')
        xlabelString = varargin{kk+1};
    end
    
    if strcmp(varargin{kk}, 'ylabel')
        ylabelString = varargin{kk+1};
    end
    
    if strcmp(varargin{kk}, 'title')
        titleString = varargin{kk+1};
    end
    
    if strcmp(varargin{kk}, 'legend')
        legendString = varargin{kk+1};
    end        
    
    if strcmp(varargin{kk}, 'domain')
        domain = varargin{kk+1};
    end
end

if numel(domain) == 0
    domain = (0:max(D(:))+1)-.5; % 
end


h = histogram(D, domain);

c = uicontextmenu();
m1 = uimenu(c,'Label','Save data','Callback',@exportData);

h.Parent.UIContextMenu = c;

%set(h, 'Position', [0, 0.1, 1, 0.9]);
title(titleString, ...
    'Interpreter', 'None')
xlabel(xlabelString)
ylabel(ylabelString)
if numel(legendString)>0
    legend(legendString)
end

    function exportData(varargin)
        %m = msgbox('Please say where the data should be stored. Note that the first row says how many nuclei that has 0 dots.');
        %uiwait(m);
        [fileName, folder] = uiputfile([titleString '.csv']);
        if ~isnumeric(folder)
            csvwrite([folder fileName], D(:));
        end
        
    end

end