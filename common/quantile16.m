function QQ=quantile16(I, Q)
% function QQ=quantile16(I, Q)
% Q values in [0,1]

h = double(df_histo16(uint16(I)));
h = cumsum(h);
h = h/h(end);

for kk=1:numel(Q)
    q = find(h>=Q(kk));
    q = q(1);
    QQ(kk)=q-1;
end

if numel(QQ)==0
    QQ = [0,0];
end

end