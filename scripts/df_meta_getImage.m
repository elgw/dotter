function I = df_meta_getImage(M, channel)

% If numeric, 0 = dapi, 1, ... are the other channels
if isnumeric(channel)
    if channel == 0
        channelName = 'dapi';
    else
        channelName = M.channels{channel};
    end
    imName = strrep(M.dapifile, 'dapi', channelName);
end

% If channel name was given as string
if ischar(channel)
    imName = strrep(M.dapifile, 'dapi', channel);
end

% Read the image to be returned
I = df_readTif(imName);

end