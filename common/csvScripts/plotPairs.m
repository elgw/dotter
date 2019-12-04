function plotPairs(D)
% Plot distribution of pairs from D, a cell structure with pairwise distances
% Follow by: generateParalellBeamer

disp('Enter a name for the folder to contain the plots')
folder = input('? ', 's')
mkdir(folder);

probenames = [1 2 13 14 3 4 5 6 7 8 9 10 11 12];
cprobenames = num2cell(probenames);
for kk=1:numel(cprobenames)
    cprobenames{kk} = ['p' num2str(cprobenames{kk})];
end

normstring = '';

for kk=1:size(D,1)
    for ll= kk+1:size(D,2)
        
        d = cell2mat(D(ll,kk));
        if numel(d)>0
            
            [ke, do] = kdeParzen(d, [], [0,4000], []);
            close all
            figure,
            plot(do, ke, 'k', 'LineWidth', 2)
            hold on
            plot(d, 0*d, 'ko')
            title([cprobenames{kk} ' -- ' cprobenames{ll} ' mean=' num2str(round(mean(d))) ' std=' num2str(round(std(d)))  ' n=' num2str(numel(d))])
            xlabel('distance [nm]')
            
            ax = axis;
            ax(1)=0; ax(2)=4000;
            axis(ax)
            
            set(gcf,'Units','centimeters',...
                'PaperUnits', 'centimeters', ...
                'PaperSize',[15 15], ...
                'PaperPosition', [0,0,15,15], ...
                'PaperPositionMode', 'Manual')
            pause(1)
            print('-dpdf', [folder '/distNorm_' cprobenames{kk} '_' cprobenames{ll} '_' normstring '.pdf'])
            
        end
    end
end
end