% Centre off mass
% Some preparation for writing com3

clear all

H = 128;
W = 128;
N = 3;

Px = rand(N,1)*(H-1)+1;
%Py = Px;
Py = rand(N,1)*(W-1)+1;

Lx = round(Px);
Ly = round(Py);

Px = Lx+.4;
Py = Ly;

%Px=round(Px); Py = round(Py);

V = zeros(H,W);

VG = blitGauss(V, [Py, Px], 1);

figure(1)
clf
imagesc(VG)
hold on
plot(Px, Py, 'gs');
plot(Lx, Ly, 'ro');

r = 1;

[Dx, Dy] = meshgrid(-r:r, -r:r);
k = fspecial('gaussian', [2*r+1,2*r+1], 1);
k = ones(size(k))/numel(k);

mx = convn(VG, -Dx.*k, 'same');
wx = convn(VG, ones(size(Dx)).*k, 'same');

my = convn(VG, -Dy.*k, 'same');
wy = convn(VG, ones(size(Dy)).*k, 'same');


Cx = Lx+ interpn(mx./wx, Ly, Lx, 'nearest');
Cy = Ly+interpn(my./wy, Ly, Lx, 'nearest');

plot(Cx, Cy, 'r+');

P = [Ly, Lx, ones(size(Lx))];
[F] = dotFitting(VG, P);
Fx = F(:,2);
Fy = F(:,1);

plot(Fx, Fy, 'g<');

axis image
colormap gray

legend({'True', 'Local max', 'Centre of mass', 'ML'})

% In most of the cases this gives a good approximation of the location
% BUT give really bad estimates when there are other dots in close
% proximity

figure(2)
clf
binE = linspace(0,2,20);
eLmax = eudist([Px, Py], [Lx, Ly]);
eCoM  = eudist([Px, Py], [Cx Cy]);
eML   = eudist([Px, Py], [Fx Fy]);
histogram(eLmax, binE)
hold on
histogram(eCoM, binE)
histogram(eML,  binE)
legend({'Local maxima', 'centre of mass', 'Maximum Likelihood'})
