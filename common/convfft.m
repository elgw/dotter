function y=convfft(x, h)
%% function y=convfft(x, h)
% computes the convolution y = x*h using fft

    y = ifftn(fftn(x).*fftn(h));

end
