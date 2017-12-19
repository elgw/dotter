function msRegistrationRun(msFile)
%% function msRegistrationRun(msFile)
% Perform image registration using normalized cross correlation
% using settings in msFile, created by msRegistration

t = load(msFile);
s = t.s;

disp(s);

assert(s.scaling<=1);
assert(s.scaling>0);

%% Loading the target image
disp('Loading target image');
T = imread(s.targetImage);
T = double(T);
if s.scaling ~= 1
    T = imresize(T, s.scaling);
end

if s.invertTarget 
    disp('Inverting target image');
    T = max(T(:)) - T;
end

disp(' ')
for kk = 1:numel(s.subImages);    
    subImage = s.subImages{kk};
    
    fprintf('%d/%d\n %s\n', kk, numel(s.subImages),  subImage);
    
    try
        S = df_readTif(subImage);
    catch e
        fprintf(' Could not read with df_readTif, trying imread ... ');
        S = imread(subImage);
        disp('ok');
    end
                
    S = double(S);
    S = sum(S,3);
    
    S = imresize(S, s.scaling*s.targetResolution/s.subimageResolution);
    
    if s.flipVert
        S = flipud(S);
    end
    
    N = normxcorr2(S, T); 
    
    [ypeak, xpeak] = find(N==max(N(:)));
    peak = N(ypeak, xpeak);
    % Compute translation from max location in correlation matrix
    yoffset = ypeak-size(S,1);
    xoffset = xpeak-size(S,2);
    
    s.match{kk} = [xoffset, yoffset, peak];

    fprintf(' x: %d y: %d, nxc: %.2f\n', xoffset, yoffset, peak);    
end

disp(' ')
fprintf('Saving results to %s\n', msFile);
save(msFile, 's');
disp(' ')
fprintf('To visualize the results, try:\n');
fprintf('msRegistrationShow(''%s'')\n', msFile);