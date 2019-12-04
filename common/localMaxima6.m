function M = localMaxima26(I)

C = I(2:end-1, 2:end-1, 2:end-1);

Xp = I(3:end,   2:end-1,2:end-1);
Xm = I(1:end-2, 2:end-1,2:end-1);

Yp = I(2:end-1, 3:end,  2:end-1);
Ym = I(2:end-1, 1:end-2,2:end-1);

Zp = I(2:end-1, 2:end-1, 3:end  );
Zm = I(2:end-1, 2:end-1, 1:end-2);


M = C> max(max(max(Xp,Xm), max(Yp, Ym)), max(Zp,Zm));

end