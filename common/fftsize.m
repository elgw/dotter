function h2 = fftsize(h, siz)
%% function h2 = fftsize(h)
% move a kernel centered in h so that it can be used with fft

    s1 = size(h);
    if sum(s1>siz)>0
        disp('PSF to large, please crop')
        return
    end

    h2 = zeros(siz);
    %whos
    h2(1:size(h,1), 1:size(h,1), 1:size(h,3)) = h;    
    [a,b,c] = ind2sub(size(h),find(h==max(h(:))));
    if numel(a)==0
        disp('Warning: No maxima found in the PSF');
    end
    if numel(a)>1
        disp('Warning: more than one maxima in the PSF');
        a = a(1);
        b = b(1);
        c = c(1);
    end
    
    h2 = circshift(h2,-a+1,1);
    h2 = circshift(h2,-b+1,2);
    h2 = circshift(h2,-c+1,3);        
    h2 = h2-min(h2(:));
    h2 = h2/sum(h2(:));    
end
