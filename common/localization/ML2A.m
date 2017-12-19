function L = ML2A(I, l)
W = size(I,2); H = size(I,1);

[XX,YY]=meshgrid(1:W, 1:H);
XXYY = [XX(:) YY(:)];

pdf = l.N*mvnpdf(XXYY, [l.x,l.y], eye(2)*l.sigma);
pdf = reshape(pdf, size(I));
whos
L = sum(sum((pdf-I).^2));
end