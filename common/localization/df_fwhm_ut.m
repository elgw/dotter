function df_fwhm_ut()

V = zeros(1024,1024,60);

p1 = {100,100,10};
p2 = {120,100,10};

V(p1{:})=1;

disp('  Reasonable estimation for a delta function')
w0 = df_fwhm(V, cell2mat(p1));
assert(w0>0);
assert(w0<2);

disp('  No estimation for flat data')
w1 = df_fwhm(V, cell2mat(p2));
if (w1~=-1)
    error('Didn''t handle flat data')
end

V = zeros(100,100,100);
V(50,50,:) = 1;

disp('  Dot a first plane')
w = df_fwhm(V, [50,50,1]);
assert(w==w0); 

disp('  Dot at last plane')
w = df_fwhm(V, [50,50,size(V,3)]);
assert(w==w0); 

V(1,50,50) = 1;
w = df_fwhm(V, [1,50,50]);

if(w==-1)
    warning('Boundary case not implemented')
end

disp('  Timings')
N = 60;
V = zeros(1024,1024,60);
P = rand(N,3);

P(:,1) = 1024*P(:,1);
P(:,2) = 1024*P(:,2);
P(:,3) =   60*P(:,3);
P(P<1) = 1;
P = round(P);

for kk =1:size(P,1)
    V(P(kk,1), P(kk,2), P(kk,3)) = 1;
end
tic
w = df_fwhm(V, P);
t = toc;

fprintf('  %.2d dots per second\n', N/t);

disp(' -- done');
end