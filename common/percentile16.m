function p = percentile16(I, v)
%% p = percentile16(I, at)
% Returns the percentiles at v

assert(isa(I, 'uint16'))
assert(min(v)>=0);
assert(max(v)<=1);
p = zeros(size(v));

h = histo16(I);
h=double(h);

s = cumsum(h);
s=s/s(end);

for kk = 1:numel(v)
    p(kk) = find(s>=v(kk),1);    
end
end
