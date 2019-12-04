function Q = cCorrP(P, from, to, dbfile)
%% function Q = cCorrP(P, from, to, dbfile)
%
% First, run cCorrMeasure to get some reference dots
%
% example :
%  Q = cCorrP(P, 'a594', 'tmr', 'cc_20151019.mat')
%  Aligns the dots in P:a594 to Q:tmr using a second order polynomial model
% Typically one channel would be used as a reference channel (true) and the
% others aligned to it. I.e., the script could be used to allign dots from
% both a594 and cy5 to tmr:
% Qa594  = cCorrP(Pa594, 'a594', 'tmr', 'cc_20151019.mat')
% Qcy5   = cCorrP(Pcy5,  'cy5',  'tmr', 'cc_20151019.mat')
%
% The available channels are given by the dbfile.
%
% Erik W, 19 Oct 2015

if nargin<4 % if no input, just run an example
    disp('No input given, running some tests')
    dbfile = 'cc_20151019.mat';
    % From cy5 to alexa
    ccd = load(dbfile);
    F1 = ccd.F{1}; F1 = F1(1:ccd.N, 1:3); % From, channel that the dots are in
    F2 = ccd.F{2}; F2 = F2(1:ccd.N, 1:3); % To, i.e. reference channel
    P = F1;
else
    F1 = from;
    F2 = to;
    ccd = load(dbfile);
end

useDimensions = 2;
% Three dimensions were unstable in the first experiments that i performed,
% a linear model might be enought in 3D

% Polynomial order
polyorder = 1; % 1 and 2 supported

figure
for kk = 1:2 %numel(ccd.chan)
    plot3(ccd.F{kk}(1:ccd.N,1), ccd.F{kk}(1:ccd.N,2), ccd.F{kk}(1:ccd.N,3), 'o', 'MarkerSize', 2+2*kk)
    hold all
end
axis equal


infostring = sprintf('D: %d, Order: %d', useDimensions, polyorder);


%% Associate dots to each other
% For each dot in F1, see if there is a correspondence in F2,
% if, put the dot in F2 at the same index,
% if not, remove the dot from F1
keyboard
pos = 1;
while(pos<=size(F1,1))
    p = F1(pos,:);
    d = F2-repmat(p, size(F2,1), 1);
    d = d.^2;
    d = sum(d,2);
    md = min(d(:));
    p = find(d == md); p = p(1);
    if md<4 && p>=pos % Swap data
        t = F2(pos,:);
        F2(pos,:)=F2(p,:); F2(p,:)=t;
        pos = pos+1;
    else % No corresponding point found
        F1 = [F1(1:pos-1, :);F1(pos+1:end,:)];
    end
end
F2 = F2(1:size(F1,1), :);

%sum((F1-F2).^2, 2)

%% Set up transformation matrices

if useDimensions == 2
    % Model
    % F2x = [ones(size(F1,1),1), F1(:,1), F1(:,2), F1(:,1).*F1(:,2), F1(:,1).^2, F1(:,2).^2)]*C
    % F2x = MXY1*C, i.e., C = F2x\MYX1
    
    if polyorder == 2
        MXY1= [ones(size(F1,1),1), F1(:,1), F1(:,2), F1(:,1).*F1(:,2), F1(:,1).^2, F1(:,2).^2];
    end
    if polyorder == 1
        MXY1= [ones(size(F1,1),1), F1(:,1), F1(:,2)];
    end
    
    Cx = MXY1\F2(:,1);
    Cy = MXY1\F2(:,2);
    
    
    % Study residuals, exclude outliers....
    
    if polyorder == 2
        Q(:,1) = [ones(size(P,1),1), P(:,1), P(:,2), P(:,1).*P(:,2), P(:,1).^2, P(:,2).^2]*Cx;
        Q(:,2) = [ones(size(P,1),1), P(:,1), P(:,2), P(:,1).*P(:,2), P(:,1).^2, P(:,2).^2]*Cy;
    end
    
    if polyorder == 1
        Q(:,1) = [ones(size(P,1),1), P(:,1), P(:,2)]*Cx;
        Q(:,2) = [ones(size(P,1),1), P(:,1), P(:,2)]*Cy;
    end
    
    Q(:,3)= P(:,1);
    figure,
    plot(P(:,1), P(:,2), 'ro')
    hold on
    plot(Q(:,1), Q(:,2), 'ko');
    
    
    % Dense representation
    [X,Y] = meshgrid(1:1024,1:1024);
    PD = [X(:) Y(:)];
    if polyorder == 2
        QD(:,1) = [ones(size(PD,1),1), PD(:,1), PD(:,2), PD(:,1).*PD(:,2), PD(:,1).^2, PD(:,2).^2]*Cx;
        QD(:,2) = [ones(size(PD,1),1), PD(:,1), PD(:,2), PD(:,1).*PD(:,2), PD(:,1).^2, PD(:,2).^2]*Cy;
    end
    if polyorder == 1
        QD(:,1) = [ones(size(PD,1),1), PD(:,1), PD(:,2)]*Cx;
        QD(:,2) = [ones(size(PD,1),1), PD(:,1), PD(:,2)]*Cy;
    end
    
    delta = ((QD(:,1) - X(:)).^2+(QD(:,2)-Y(:)).^2).^(1/2);
    delta = reshape(delta, [1024,1024]);
    figure
    imagesc(delta)
    title([infostring ' - absolute displacement'])
    axis image
    colorbar 
end

if useDimensions == 3
    % Model
    % F2x = [ones(size(F1,1),1), F1(:,1), F1(:,2), F1(:,1).*F1(:,2), F1(:,1).^2, F1(:,2).^2)]*C
    % F2x = MXY1*C, i.e., C = F2x\MYX1
    
    MXYZ1= poly3mat(F1, polyorder);
    
    Cx = MXYZ1\F2(:,1);
    Cy = MXYZ1\F2(:,2);
    Cz = MXYZ1\F2(:,3);
    
    % Study residuals, exclude outliers....
    
    Q(:,1) = poly3mat(P, polyorder)*Cx;
    Q(:,2) = poly3mat(P, polyorder)*Cy;
    Q(:,3) = poly3mat(P, polyorder)*Cz;
    
    figure,
    plot3(P(:,1), P(:,2),P(:,3), 'ro')
    hold on
    plot3(Q(:,1), Q(:,2),Q(:,3), 'ko');
    axis equal
    legend({'P: input', 'Q: output'})
    
    figure
    hist(eudist(P,Q),linspace(0,10,100));
    title(infostring)
    
    if 0
        % Dense representation
        [X,Y, Z] = meshgrid(1:1024,1:1024, 1:51);
        PD = [X(:) Y(:), Z(:)];
        QD(:,1) = poly3mat(PD, polyorder)*Cx;
        QD(:,2) = poly3mat(PD, polyorder)*Cy;
        QD(:,3) = poly3mat(PD, polyorder)*Cz;
        
        delta = ((QD(:,1) - X(:)).^2+(QD(:,2)-Y(:)).^2+(QD(:,3)-Z(:)).^2).^(1/2);
        delta = reshape(delta, [1024,1024, 51]);
        volumeSlide(delta);
    end
end
