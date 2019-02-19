file = 'UserDots_IEG364_004_ml.csv';
file = 'UserDots_iEG408_003.csv';
file = 'UserDots_iEG458_003.csv';
file = 'UserDots_iEG458_004.csv';
pwd

s.channel = 'tmr'; % a594 cy5, tmr, a647, ir800

s.translate = 0; % Center each nuclei to (0,0,0)
s.scale = 1;     % Scale by pixel size
s.voxelSize = [132,132,300];
s.plot = 0;

s.disrupt = 0;   % Disturb the positions? (For debugging)
s.randV = [200, 200, 200];


if(s.disrupt)
    warning('Will disrupt the positions of the dots (s.disrupt==1)')
end

outFolder = sprintf('%s_d%d_%s/', file(1:end-4), s.disrupt, s.channel);
fprintf('Out folder: %s\n', outFolder);
mkdir(outFolder)

T = readtable(file);
D = table2cell(T);

channels = unique(D(:,2));
assert(sum(strcmp(s.channel, channels))==1)

A = zeros(size(D,1), 6);

col_channel = 2;
col_file = 1;
col_nuclei = 3;
col_label = 9;

for kk = 1:size(D,1) % For each line in D, construct A
    if(strcmpi(D{kk,col_channel}, s.channel));
        field = D{kk,col_file};
        field = field(end-5:end-3);
        A(kk,1) = str2num(field);
        A(kk,2) = D{kk, col_nuclei};
        A(kk,3) = D{kk, col_label};
        A(kk,4) = D{kk, 4};
        A(kk,5) = D{kk, 5};
        A(kk,6) = D{kk, 6};
    end
end

if s.plot
    figure
end

for ff = 1:max(A(:,1)) % field
    F = A(A(:,1) == ff, 2:end);
    
    if s.plot
        clf
    end
    
    
    
    for nn = unique(A(:,1))'; % nuclei
        N = F(F(:,1) ==nn, 2:end);
        for aa = 1:2
            CL = N(N(:,1)==aa, 2:end);
            if numel(CL)>0
                outName = sprintf('%03d_%03d_%d.csv', ff, nn, aa);
                % Put at (0,0,0)
                
                CL(:,1:3)
                if s.plot
                    hold on
                    plot3(CL(:,1), CL(:,2), CL(:,3), 'o')
                end
                
                if s.translate
                    CL(:,1) = CL(:,1) - mean(CL(:,1));
                    CL(:,2) = CL(:,2) - mean(CL(:,2));
                    CL(:,3) = CL(:,3) - mean(CL(:,3));
                end
                if s.scale
                    CL(:,1) = CL(:,1)*s.voxelSize(1);
                    CL(:,2) = CL(:,2)*s.voxelSize(2);
                    CL(:,3) = CL(:,3)*s.voxelSize(3);
                end
                if s.disrupt
                    for kk = 1:size(CL,1)
                        CL(kk,1) = CL(kk,1) + (1-2*rand(1))*s.randV(1);
                        CL(kk,2) = CL(kk,2) + (1-2*rand(1))*s.randV(2);
                        CL(kk,3) = CL(kk,3) + (1-2*rand(1))*s.randV(3);
                    end
                end
                
                writetable(array2table(CL), [outFolder outName], 'WriteVariableNames', 0); % gives more decimals
            end
        end
    end
    if s.plot
        pause
    end
end
