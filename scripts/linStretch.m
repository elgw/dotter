function V = linStretch(V, interval)
%% function linStretch(V, [minVal, maxVal])
% Stretch the values in V in 
% [minVal, maxVal] to [0,1] and clip everything outside

minVal = interval(1);
maxVal = interval(2);

    V = double(V);
    V = (V-minVal)/(maxVal-minVal);
    V(V<0)=0;
    V(V>1)=1;
    
end