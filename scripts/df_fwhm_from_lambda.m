function fwhm = df_fwhm_from_lambda(lambda, numerical_aperture)
        % Return the THEORETICAL fwhm of the zeroth-order diffraction spot.
        %
        % https://www.microscopyu.com/techniques/super-resolution/the-diffraction-barrier-in-optical-microscopy
        % - Abbe resolution:
        %   xy: lambda/(2*NA)
        %   z: 2*lambda/(NA^2)
        %
        % - Rayleigh Resolution (equal to FWHM)
        %    xy = 0.61λ/NA
        %
        % FWHM of a gaussian:
        % 2*sqrt(2*log(2))*sigma
        % ~ 2.355*sigma
        
        if ~exist('numerical_aperture', 'var')
           numerical_aperture = df_getConfig('df_fwhm_from_lambda', 'NA', 0);
           if numerical_aperture == 0
            qna = inputdlg('What Numerical Aperture was used?', 'df_fwhm_from_lambda', 1, {'1.45'});
            if numel(qna) == 1
                numerical_aperture = str2num(qna{1});
            end       
            if isnumeric(numerical_aperture)
                df_setConfig('df_fwhm_from_lambda', 'NA', numerical_aperture);
            end
           end           
        end
        
        fwhm(1) = 0.61*lambda/numerical_aperture;
        fwhm(2) = 0.61*lambda/numerical_aperture;
        fwhm(3) = 0.61/0.5 * 2*lambda/(numerical_aperture^2);
end