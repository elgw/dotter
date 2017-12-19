function I = imnorm(I)
    I = double(I);
    I = I - min(I(:));
    I = I./max(I(:));
end