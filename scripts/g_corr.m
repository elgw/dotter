function c = corr(A,B)
% function c = corr(A,B)
% correlation between A and B

A = double(A(:)); B = double(B(:));
A = A-mean(A(:));
B = B-mean(B(:));

c = sum(A.*B)/sqrt(sum(A.*A)*sum(B.*B));