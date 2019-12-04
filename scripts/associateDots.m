function [nuclei] = associateDots(mask, dots)
%% function nuclei = associateDots(mask, dots)
% add as a third column the 
nuclei = zeros(size(dots,1), 1);

for ll = 1:size(dots,1)
        nuclei(ll)=mask(dots(ll,1), dots(ll,2));
end

end