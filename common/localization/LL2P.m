function L=LL2P(patch, sigma, x)

%x: x, y, lambda, N
%mux = x(1);
%muy = x(2);
%bg = x(3);
%N = x(4);

%x(3)=max(0.1, x(3));
%x(4)=max(0, x(4));

%[X,Y] = meshgrid(1:size(patch,1), 1:size(patch,2));
%s = round(N*mvnpdf([Y(:), X(:)], [mux, muy], sigma*eye(2)));
%s = reshape(s, size(patch));
%side = (size(patch, 1)-1)/2;
%mux, muy, sigma
model = x(3)+x(4)*df_gaussianInt2([x(1), x(2)], sigma, (size(patch, 1)-1)/2);

%figure(8)
%hold on
%plot(mux, muy, 'x')
%drawnow

%res = round(res);
%min(patch(:))

%L = -sum(sum( (-s*log10(exp(1)) +patch.*log10(s)) -logfactorial(patch)));
% Faster alternative, in twod.m:
% global lf, lf = logfactorial(1:2^16);
global lf
L = -sum(sum( (-model*log10(exp(1)) +patch.*log10(model)) -lf(patch)));

% Based on Gaussian approximation of Poissonian, ok for FISH since high
% number of photons
%L = -sum(sum( -(patch-model).^2./model - .5*log(model)));
%assignin('base', 'model', model)
%pause
end