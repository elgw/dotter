close all

load iEG120_values.mat
n = 96; % kmers per probe

v = [values(1:59,1); values(61:end,1)];
v = [v; values(:,2)];

% Exclude the strongest dot

[y,x] = kdeParzen(v);
figure,
plot(x,y);

% Use optimization to find, p as well as the scaling/conversion
% from observed intensity to n kmers.


%% Simulations

vs = randn(size(values,1),2)*5+10;
vs = sort(vs, 2, 'descend');
xa = [min(vs(:)), max(vs(:))];

% No noise

figure,
subplot(1,3,1)
histogram(vs), title('all')
xaxis(xa);
subplot(1,3,2)
histogram(vs(:,1)), title('strongest')
xaxis(xa);
subplot(1,3,3)
histogram(vs(:,2)), title('2nd')
xaxis(xa);

% with noise
p = .02;
v = binornd(96*ones(size(values,1),2), p);
v = v + rand(size(v));
v = 3*v;

figure,
subplot(2,2,1)
histogram(v(:,3:end),D), hold on
histogram(v(:,1:2),D)
title('Probes - no noise')
xaxis(xa);
set(gca, 'YScale', 'log')
subplot(2,2,2)
histogram(v(:,1:2),D)
title('Probes')
xaxis(xa);
subplot(2,2,3)
histogram(vs(:,1),D), title('1st')
xaxis(xa);
subplot(2,2,4)
histogram(vs(:,2),D), title('2nd')
xaxis(xa);
dprintpdf('probes_no_noise.pdf');


v = [v, randn(size(values,1), 1000)];
vs = sort(v, 2, 'descend');
xa = [min(vs(:)), max(vs(:))];
D = linspace(xa(1), xa(2), 40);

figure,
subplot(2,2,1)
histogram(v(:,3:end),D), hold on
histogram(v(:,1:2),D)
title('Probes and noise')
xaxis(xa);
set(gca, 'YScale', 'log')
subplot(2,2,2)
histogram(v(:,1:2),D)
title('Probes')
xaxis(xa);
subplot(2,2,3)
histogram(vs(:,1),D), title('1st')
xaxis(xa);
subplot(2,2,4)
histogram(vs(:,2),D), title('2nd')
xaxis(xa);
dprintpdf('probes_noise.pdf');

N = 96;
H = [];
for kk = 1:500
    p = .02;
    s = rand(N,1);
    H(kk) = sum(s>(1-p));
end

figure, histogram(H, 'normalization', 'pdf')
hold on
bar(0:N, binopdf(0:N, N, p))
