function dotterDotsSelect(folder)
%% Select how the dots should be ordered for a certain _calc folder
%
% Intented use:
%  dotterDots
%  dotterDotsSelect
%  selectUserDots
%

if ~exist('folder', 'var')
    %folder = uigetdir();
    folder = '/home/erikw/Desktop/iXL34_35_36/iXL034_100816_001_calc2/';
    files = dir([folder '/*.NM']);
end

if numel(files)<1
    fprintf('No NM files in %s\n', folder)
    return
end

NM = load([folder '/' files(1).name], '-mat');
N= NM.N;
M= NM.M;

%uiwa

dotTypes = {};

if ~isfield(M, 'dotTypes')
    disp('No M.dotTypes available')
    disp('Run dotterDots on this data set first');
    return
end

for kk = 1:numel(M.dotTypes)
    fprintf('%d %s\n', kk, M.dotTypes{kk}.desc);
    dotTypes{kk} = M.dotTypes{kk}.desc;
end

[dotTypeNo,~] = listdlg('PromptString', 'Select Default Dot Measurement:', ...
    'SelectionMode', 'single', ...
    'ListString', dotTypes);

if numel(dotTypeNo)==0
    disp('No type was selected. Aborting.')
    return
end

dotType = M.dotTypes{dotTypeNo}
fprintf('Changing default dot type to %s\n', dotType.desc);
fprintf('Will clear userDots\n');

for ff = 1 %:numel(files)
    NM = load([folder '/' files(ff).name], '-mat');
    M = NM.M;
    N = NM.N;
    if isfield(M, 'dotTypes')       
        for cc = 1:numel(M.channels)
            D = M.dots{cc};
            DS = getfield(M, dotType.field);
            DS = DS{cc};
            DS = DS(:,dotType.column);
            
            if ~isfield(dotType, 'ordering')
                dotType.ordering = 'descend';
            end
            [~, idx] = sort(DS, dotType.ordering);
            D(:,4) = DS;
            D = D(idx,:);
            
            %assert(D(1,4)>= D(2,4));
            
            M.dots{cc} = D;            
        end
        
        % Clear userDots
        for nn = 1:numel(N)
            if isfield(N{nn}, 'userDots')
                N{nn} = rmfield(N{nn}, 'userDots');
            end

            if isfield(N{nn}, 'userDotsExtra')
                N{nn} = rmfield(N{nn}, 'userDotsExtra');
            end
        end
                
        save([folder '/' files(ff).name], 'N', 'M');
    else
        warningstring = sprintf('Error for field %d\n', ff);
        warning(warningstring);
        disp('No dot types in Meta Data, run dotterDots first')
        return
    end
end

end