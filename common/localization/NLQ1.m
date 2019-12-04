function L=NLQ1(signal, sigma, x)
%x: x, y, Nphotons, 
mu = x(1);
Nphotons = x(2);
BG = x(3);

%[X,Y] = meshgrid(1:size(patch,1), 1:size(patch,2));
%s = round(B*mvnpdf([Y(:), X(:)], [mux, muy], sigma*eye(2)));
s = BG+(Nphotons*normpdf(1:numel(signal), mu, sigma));

if 0
figure(1)
plot(s)
hold on
plot(signal)
hold off
pause
end

res = signal(:)-s(:)-BG;
L = sum(res.^2);

if Nphotons<0
    L = 10^9;
end

end