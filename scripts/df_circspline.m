function [X, Y] = circspline(x, y, F)
% https://mathworld.wolfram.com/CubicSpline.html

x = x(:);
y = y(:);

R = [1 4 1 zeros(1, numel(y) -3)];
R = circshift(R, -1);
M = zeros(numel(R));
for kk = 1:numel(R)
    M(:, kk) = R;
    R = circshift(R, 1);
end
Y = 3*(circshift(y, -1) - circshift(y, 1));
% M*D=Y; M*D - Y = 0;
D = M\Y;

a = y;
b = D;
c = 3*(circshift(y,-1) - y) - 2*D - circshift(D,-1);
d = 2*(y-circshift(y,-1)) + D + circshift(D,-1);

X = [];
Y = [];

for kk = 1:numel(y)
    xx = linspace(0,1, F);
    yy = a(kk) + b(kk)*xx + c(kk)*xx.^2 + d(kk)*xx.^3;    
    X = [X, xx+kk-1];
    Y = [Y, yy];
end

if 0
figure
hold on
for kk = 1:numel(y)
    xx = linspace(0,1);
    yy = a(kk) + b(kk)*xx + c(kk)*xx.^2 + d(kk)*xx.^3;    
    plot(kk+xx, yy);
end
end
end