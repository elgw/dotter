function df_snr_ut()

disp('Coordinates ok');
I = zeros(100,200,300);
I(11,22,33)=10;

snr = df_snr(I, [11,22,33]);
assert(isinf(snr));

for kk = 0:1
    snr(kk+1) = df_snr(I+0.01*rand(size(I)), [11+kk,22+kk,33+kk]);
end
assert(snr(1)>snr(2));
% The snr should decrease when moving away from the set point.


disp('Increasing noise')
sigmas = [1,2,5];
for kk = 1:numel(sigmas)
    s = sigmas(kk);
    snr(kk) = df_snr(I + s*randn(size(I)), [11,22,33]);
    if(kk>1) % The SNR should decrease with increasing noise.
        assert(snr(kk)<snr(kk-1));
    end
end


disp('All dots get a value, no ''NaN''s')
I = ones(100, 100, 100);
D = randi(100, 200, 3);
I(sub2ind(size(I), D(:,1), D(:,2), D(:,3))) = 2;
sum(I(:) == 2);
s = df_snr(I, D);
assert(sum(isnan(s)) == 0);


end
