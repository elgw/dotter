function df_image_focus_ut()
disp('Finds the correct slice with most gm content');
I = zeros(100,100,100);
slice = 27;
I(51,51,slice) = 1;
F = df_image_focus('image', I, 'method', 'gm');
assert(numel(F) == size(I,3));
assert(F(slice) == max(F(:)));
end