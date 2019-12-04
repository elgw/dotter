function dotter_patch_20171124()

[a,b] = uigetfile('*.NM');

if isnumeric(a)
    return
end

fname = [b,a];

load(fname, '-mat');

for kk = 1:numel(N)
	seg = double(M.mask == kk);
    nuclei.bbx = bbox(seg);
    nuclei = N{kk};
    nuclei.bbx(1)=max(1, nuclei.bbx(1)-5);
    nuclei.bbx(2)=min(size(seg,1), nuclei.bbx(2)+5);
    nuclei.bbx(3)=max(1, nuclei.bbx(3)-5);
    nuclei.bbx(4)=min(size(seg,2), nuclei.bbx(4)+5);
    N{kk} = nuclei;
end

save(fname);

end