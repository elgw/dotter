function l = df_getEmission(varargin)
%% function l = df_getEmission(cName)
% Return the emission maxima for channel cName [nm]
% Ask for it if not exist
%
% Can also be used as a setter,
% function df_getEmission(cName, lambda)
% Set it directly by getEmisson('dapi', 500);
%
% Two channel names are reserved for special use, 'unknown' and 'show'
%
% The channel UNKNOWN is special in the sense that the value is never
% stored
%
% df_getEmission('show') will show all stored information
%

if numel(varargin) == 0
    help('df_getEmission')
    return
end

for kk = 1:numel(varargin)
    if strcmp(upper(varargin{1}), 'SHOW');
        showAll()
        return
    end
end

cName = upper(varargin{1});

if numel(varargin) == 1

l = df_getConfig('getEmission', cName, []);
if numel(l) == 0 || l<0 || l>10000
    l = -1;
    while l<1 || l>10000
        l = inputdlg(sprintf('Emission maxima for %s? [nm]', cName));
        if numel(l)>0
            l = str2num(l{1});
        else
            l = 0;
        end
    end
end

else
    l = varargin{2};
end

if ~strcmp(upper(cName), 'UNKNOWN')
    df_setConfig('getEmission', cName, l);
end

%fprintf('Emission for %s: %d nm.\n', cName, l);

    function showAll()
       disp('Emission information that you have stored:');
       df_getConfig('getEmission');
    end

end