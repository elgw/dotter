function r = disk2d(s)

[x,y]=meshgrid(-s:s, -s:s);
r = x.^2+y.^2;

r(r<=(s+1)^2)=1;
r(r>1)=0;
end