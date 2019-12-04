function [J, CxB, CyB, dzB, E] = cCorrI(I, from, to, dbfile, maxDist)
%% function Q = cCorrI(P, from, to, dbfile)
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
% To do:
% - Volume correction, including z-shift
% - Iteratively remove outliers and set up transformation matrices again
%     (exclude 10% worst or similar)
% - What to do when there are to few dots in a channel? Output identity
% transform?
%
% Erik W, 19 Oct 2015

% Maximum displacement given in pixels
% 3 is usually good but for really large displacements some other strategy
% might be required

% Polynomial order
s.polyorder = 1; % 1, 2 and 3 supported
s.verbose = 0;
s.useDimensions = 2;
s.debug = 1; % !!! Set to 0 
s.maxDist = 10;

if nargin<4 % if no input, just run an example
    disp('No input given, running some tests')
    dbfile = '~/code/cCorr/cc_20151216.mat';
    % From cy5 to alexa
    ccd = load(dbfile);
    F1 = ccd.F{1}; F1 = F1(1:ccd.N, 1:3); % From, channel that the dots are in
    F2 = ccd.F{2}; F2 = F2(1:ccd.N, 1:3); % To, i.e. reference channel
else
    ccd = load(dbfile, '-mat');    
    F1 = ccd.F{find(strcmp(from, ccd.chan))};    
    F2 = ccd.F{find(strcmp(to, ccd.chan))};    
    
    if 0
        F2 = F1;
        F2(:,2) = F2(:,2)+.2; % DBG
        F2(:,1) = F2(:,1)+.3; % DBG
        F2 = F2 + 0.01*rand(size(F2));
    end
end

if size(I,2)<4
    inputIsDots = 1;
    inputIsImage = 0;
else
    inputIsDots = 0;
    inputIsImage = 1;
    t = F1;
    F1 = F2;
    F2 = t;
end


if inputIsDots && s.verbose == 1
    disp('Treating input as dots')
else
    disp('Treating input as image')
end

F1 = F1(:,1:3);
F2 = F2(:,1:3);

% Three dimensions were unstable in the first experiments that i performed,
% a linear model might be enought in 3D


debugFigures = 0;

if debugFigures
    figure
    for kk = 1:2 %numel(ccd.chan)
        plot3(ccd.F{kk}(1:ccd.N,1), ccd.F{kk}(1:ccd.N,2), ccd.F{kk}(1:ccd.N,3), 'o', 'MarkerSize', 2+2*kk)
        hold all
    end
    axis equal
end

infostring = sprintf('D: %d, Order: %d', s.useDimensions, s.polyorder);


%% Associate dots to each other
% For each dot in F1, see if there is a correspondence in F2,
% if, put the dot in F2 at the same index,
% if not, remove the dot from F1
[F1, F2] = associateDots(F1,F2, s);
    
if s.debug
    MSE = eudist(F1, F2);
    MSE = mean(MSE.^2);
    fprintf('MSE between F1 and F2: %f\n', MSE);
end

if debugFigures
    figure
    imshow(I)
    hold on
    for kk = 1:size(F1,1)
        plot([F1(kk,2), F2(kk,2)], [F1(kk,1), F2(kk,1)], 'r');
    end
    %quiver(F1(:,2), F1(:,1), F1(:,2)-F2(:,2), F1(:,1)-F2(:,1))
    text(F1(:,2), F1(:,1), num2str((1:size(F1,1))'), 'Color', 'r', 'FontSize', 14)
    pause    
end


%% Set up transformation matrices

if s.useDimensions == 2
    % Model
    % F2x = [ones(size(F1,1),1), F1(:,1), F1(:,2), F1(:,1).*F1(:,2), F1(:,1).^2, F1(:,2).^2)]*C
    % F2x = MXY1*C, i.e., C = F2x\MYX1
    
    excluded = 1;
    iter = 1;
    % Exclude points with bad fit until convergence (or failure)
    while(excluded == 1)        
        fprintf('Iter %d : %d points\n', iter, size(F1,1));
        iter = iter+1;
        MXY1 = poly2mat(F1, s.polyorder);
        
        Cx = MXY1\F2(:,1);
        Cy = MXY1\F2(:,2);
        
        MXY1B = poly2mat(F2, s.polyorder);
        
        CxB = MXY1B\F1(:,1);
        CyB = MXY1B\F1(:,2);
        
        if s.verbose
            Cx
            Cy
            CxB
            CyB
        end
        
        % Study residuals, exclude outliers....
        Ft = F1;
        Ft(:,1)=MXY1*Cx;
        Ft(:,2)=MXY1*Cy;
        D2 = eudist(Ft(:,1:2), F2(:,1:2));
        MSE = mean(D2.^2);
        maxD = .5;

        % For iterative fitting, do something like
        F1 = F1(D2<maxD, :);
        F2 = F2(D2<maxD, :);
        
        if sum(D2>=maxD)==0
            excluded = 0;
        end
        
        if size(F1,1)<10
            warning('Convergence failed. Aborting. Please try using more dots!')
            J = F1;
            CxB = [0,1,0,0,0,0];
            CyB = [0,0,1,0,0,0]
            dzB = 0;
            E = nan(size(F1,1),1);
            return
        end
    end
    
    % Euclidean distance in x-y. Given in pixels.
    E = D2;
    
    
    
    %fprintf('Fitted MSE: %f\n', MSE);
    if debugFigures
        figure,
        quiver(F2(:,1), F2(:,2), F2(:,1)-Ft(:,1), F2(:,2)-Ft(:,2))
    end
    
    if inputIsImage
        % Dense representation
        [Y,X] = meshgrid(1:1024,1:1024);
        PD = [X(:) Y(:)];
        
        QD(:,1) = poly2mat(PD, s.polyorder)*Cx;
        QD(:,2) = poly2mat(PD, s.polyorder)*Cy;
        
        if debugFigures
            figure,
            imagesc(X-reshape(QD(:,1), size(X)))
            title('delta x')
            hold on
            plot(F1(:,2), F1(:,1), 'o')
            figure,
            imagesc(Y-reshape(QD(:,2), size(Y)))
            title('delta y')
        end
        J = interpn(double(I), QD(:,1), QD(:,2), 'linear');
        J = reshape(J, size(I));
    end
    
    if inputIsDots
        J = I;
        J(:,1) = poly2mat(I(:,1:2), s.polyorder)*Cx;
        J(:,2) = poly2mat(I(:,1:2), s.polyorder)*Cy;
    end
end

if s.useDimensions == 3
    % Model
    % F2x = [ones(size(F1,1),1), F1(:,1), F1(:,2), F1(:,1).*F1(:,2), F1(:,1).^2, F1(:,2).^2)]*C
    % F2x = MXY1*C, i.e., C = F2x\MYX1
    
    MXYZ1= poly3mat(F1, s.polyorder);
    
    Cx = MXYZ1\F2(:,1);
    Cy = MXYZ1\F2(:,2);
    Cz = MXYZ1\F2(:,3);
                    
    % Study residuals, exclude outliers....
    
    Q(:,1) = poly3mat(P, s.polyorder)*Cx;
    Q(:,2) = poly3mat(P, s.polyorder)*Cy;
    Q(:,3) = poly3mat(P, s.polyorder)*Cz;
    
    figure,
    plot3(P(:,1), P(:,2),P(:,3), 'ro')
    hold on
    plot3(Q(:,1), Q(:,2),Q(:,3), 'ko');
    axis equal
    legend({'P: input', 'Q: output'})
    
    if inputIsImage
        % Dense representation
        [X,Y, Z] = meshgrid(1:1024,1:1024, 1:51);
        PD = [X(:) Y(:), Z(:)];
        QD(:,1) = poly3mat(PD, s.polyorder)*Cx;
        QD(:,2) = poly3mat(PD, s.polyorder)*Cy;
        QD(:,3) = poly3mat(PD, s.polyorder)*Cz;
        
        delta = ((QD(:,1) - X(:)).^2+(QD(:,2)-Y(:)).^2+(QD(:,3)-Z(:)).^2).^(1/2);
        delta = reshape(delta, [1024,1024, 51]);
        volumeSlide(delta);
    end
    
    if inputIsDots
        J = I;
        J(:,1) = poly2mat(I(:,1:3), s.polyorder)*Cx;
        J(:,2) = poly2mat(I(:,1:3), s.polyorder)*Cy;
        J(:,3) = poly2mat(I(:,1:3), s.polyorder)*Cz;
    end
end

fprintf('z-shift: %f pixels\n', mean(F2(:,3)-F1(:,3)));
if inputIsDots
    fprintf('correcting for z-shift\n');
    dz = mean(F2(:,3)-F1(:,3));
    dzB = dz;
    J(:,3) = J(:,3)+dz;
else
    fprintf('Not correcting for the z-shift\n');
    dz = [];
end


fprintf('\n>>> From %s to %s\n', from, to);
dx =  F1(:,1)-F2(:,1); dy = F1(:,2)-F2(:,2);
dxAvg = mean(dx); dyAvg = mean(dy);
fprintf('Mean displacement |(%.2f, %.2f)|=%.2f pixels\n', dxAvg, dyAvg, norm([dxAvg, dyAvg]));
figure, quiver(zeros(size(F1,1),1), zeros(size(F1,1),1),dx, dy, 'k')
hold on
mid = [512.5, 512.5];
cdelta = mid - poly2mat(mid, s.polyorder)*[Cx, Cy];
fprintf('Poly shift at (512.5, 512.5): (%.2f, %.2f)=%.2f pixels\n', cdelta(1), cdelta(2), norm(cdelta))

quiver(0,0, cdelta(1), cdelta(2), 'r', 'LineWidth', 2)
quiver(0*dxAvg, 0*dyAvg, dxAvg, dyAvg, 'g')
legend({'each dot', '0th order', 'avg delta'});
axis([-2,2,-2,2])
grid on
title(sprintf('From %s to %s\n', from, to));
fprintf('/ cCorrI');

end

function [F1, F2] = associateDots(F1, F2, s)
fprintf('Got %d points\n', size(F2,1));

pos = 1;
while(pos<=size(F1,1)) % While dots left
    p = F1(pos,:);
    d = F2-repmat(p, size(F2,1), 1);
    d(:,3)=0; % Exclude z coordinate in association
    d = d.^2;
    d = sum(d,2);
    md = min(d(:));
    pp = find(d == md); pp = pp(1);
    if md<s.maxDist^2 && pp>=pos %&& p(1)<256 && p(2)<256% Swap data
        t = F2(pos,:);
        F2(pos,:)=F2(pp,:); F2(pp,:)=t;
        pos = pos+1;
    else % No corresponding point found
        F1 = [F1(1:pos-1, :);F1(pos+1:end,:)];
    end
end
F2 = F2(1:size(F1,1), :);

fprintf('Using %d points\n', size(F2,1));

if size(F2,1)<10
    fprintf('WARNING: using very few dots! (cCorrI.m)\n');
end
end