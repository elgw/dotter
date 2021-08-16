function dotFitting_ut()

disp('-> dotFitting')
t = zeros(101,102,103);
t(14,15,16) = 1;
tic
F = dotFitting(t, [14,15,16]);
assert(eudist(F(1,1:3), [14,15,16])<.5);
t = toc;
fprintf('  Took %f s\n', t);


test_precision()
test_speed()

end

function test_precision()
% P: some positions
P = linspace(50,200.5,11)';
P = [P,P];
P(:,3) = ones(size(P,1),1);

W = zeros(212,212);
for kk = 1:size(P,1)
    W = blitGauss(W, P(kk,1:2), 1);
end

W = 100*W;

F = dotFitting(W, round(P));
E = F(:,1:2) - P(:,1:2);
E = (sum(E.^2,2).^(1/2));
assert(max(E)<0.1);
end

function test_speed()

disp('Some timing ...')
I = rand(1024, 1024, 60);
N = 1000;
D = [randi(size(I,1), N, 1), randi(size(I,2), N, 1), randi(size(I,3), N, 1)];
I(sub2ind(size(I), D(:,1), D(:,2), D(:,3))) = 2;
tic
s = dotFitting(I, D);
t = toc;
fprintf(' - %.2f dots per second\n', N/t);

end