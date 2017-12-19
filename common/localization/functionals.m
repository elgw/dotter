%% Compares functionals used for estimation of dot location

% To be clear, the functional as a function of error between model and
% observation for a single pixel will be studied.
figure,
for model = [1000, 1500, 2000];
measured = linspace(model-100, model+100);
error = model-measured;

% Least squares
%lsq = (error).^2;

% Maximul Likelihood, no detector noise, the poissonian
% is approximated with a Gaussian
mlq = -(-(measured-model).^2./model - .5*log(model));

%figure,
%plot(error, lsq);
%hold on

plot(error, mlq);
hold on

end


