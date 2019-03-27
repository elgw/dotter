function cCorrMeasure_showDots(s)
% Show dots from CC analyzer and allow toggle dots on/off.

f2 = figure('Name', sprintf('Dots for CC. %d per channel', s.N));
ax = axes('Units', 'Normalized', 'Position', [.2,.1,.7,.8]);

markers = 'ox+*sdv^<>ph';
%N = str2num(get(GUI.setN, 'String'));
N = s.N;
for kk = 1:numel(s.chan)
    D = s.D{kk};
    D = D(D(:,4)>s.th(kk), :);
    Nk = min(size(D,1), N);    
    p(kk) = plot(D(1:Nk,1), D(1:Nk,2), markers(kk));
    hold all
    uicontrol(f2, ...
        'Style', 'checkbox', ...
        'Units', 'Normalized', ...
        'Position', [0,.1*kk-.05, .1, .1], ...
        'String', s.chan{kk}, ...
        'Callback', @toggleChannel, ...
        'Value', 1);
end
legend(s.chan);
axis equal

    function toggleChannel(varargin)        
        for kk = 1:numel(s.chan)
            if strcmpi(varargin{1}.String, s.chan{kk})
                if varargin{1}.Value == 0
                    p(kk).Visible = 'off';
                else
                    p(kk).Visible = 'on';
                end
            end
        end
        
    end


end