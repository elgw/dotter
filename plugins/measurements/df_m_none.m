function t = df_m_none(varargin)
% This function returns nothing.
%
% When trying to plot against this function an Histogram is usually created
% instead of a plot.

if numel(varargin)==1
    if strcmpi(varargin{1}, 'getSettings')
        t.string = '- None/Histogram';
        t.selChan = 0;
        t.features = '0';
        return
    end
end

t=[];

end