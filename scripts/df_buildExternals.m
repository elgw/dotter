%% Purpose: build the routines written in C required to run DOTTER

DOTTER_PATH = getenv('DOTTER_PATH');
if strcmp(DOTTER_PATH, '')
    DOTTER_PATH = '~/code/';
end

if isunix || ismac
    
    disp('Removing .o files')
    !rm *.o
    
    cd([DOTTER_PATH  'volBucket'])
    mex CFLAGS='$CFLAGS -std=c99 -march=native' COPTIMFLAGS='-DNDEBUG -O3' df_bcluster.c volBucket.c
    
    cd([DOTTER_PATH 'cluster3e'])
    mex CFLAGS='$CFLAGS -std=c99 -march=native' COPTIMFLAGS='-DNDEBUG -O3' cluster3ec.c
    
    cd([DOTTER_PATH 'piccs/'])
    mex CFLAGS='$CFLAGS -std=c99 -march=native' COPTIMFLAGS='-DNDEBUG -O3' ccum_mex.c
    
    cd([DOTTER_PATH 'common/mex'])
    mex CFLAGS='$CFLAGS -std=c99 -march=native' COPTIMFLAGS='-O3' df_histo16.c
    mex CFLAGS='$CFLAGS -std=c99 -march=native' COPTIMFLAGS='-O3' df_com2.c
    
    mex CFLAGS='$CFLAGS -std=c99 -march=native -Wall `pkg-config gsl --cflags --libs`' gaussianInt2.c COPTIMFLAGS='-DNDEBUG -O3' -c
    mex CFLAGS='$CFLAGS -std=c99 -march=native -Wall `pkg-config gsl --cflags --libs`' df_gaussianInt2.c COPTIMFLAGS='-DNDEBUG -O3' 
    mex CFLAGS='$CFLAGS -std=c99 -march=native -Wall `pkg-config gsl --cflags --libs`' df_com3.c COPTIMFLAGS='-DNDEBUG -O3' ...
        LINKLIBS='$LINKLIBS -lgsl -lgslcblas'
    mex mlfit.c gaussianInt2.o CFLAGS='$CFLAGS -std=c99 -march=native `pkg-config gsl --cflags --libs`' COPTIMFLAGS='-O3 -D verbose=0' ...
        LINKLIBS='$LINKLIBS -lgsl -lgslcblas -v' -c
    mex blit3.c gaussianInt2.o CFLAGS='$CFLAGS -std=c99 -march=native `pkg-config gsl --cflags --libs`' COPTIMFLAGS='-O3 -D verbose=0' ...
        LINKLIBS='$LINKLIBS -lgsl -lgslcblas' -c
    mex df_mlfit1.c CFLAGS='$CFLAGS -std=c99 -march=native `pkg-config gsl --cflags --libs`' COPTIMFLAGS='-O3 -D verbose=0' ...
        LINKLIBS='$LINKLIBS -lgsl -lgslcblas' mlfit.o blit3.o gaussianInt2.o
    mex  df_mlfit1sn.c CFLAGS='-g $CFLAGS -std=c99 -march=native `pkg-config gsl --cflags --libs`' COPTIMFLAGS='-g -O3 -D verbose=0' ...
        LINKLIBS='$LINKLIBS -lgsl -lgslcblas' mlfit.o gaussianInt2.o
    mex  df_mlfitN.c CFLAGS='-g $CFLAGS -std=c99 -march=native `pkg-config gsl --cflags --libs`' COPTIMFLAGS='-g -O3 -D verbose=0' ...
        LINKLIBS='$LINKLIBS -lgsl -lgslcblas' mlfit.o blit3.o gaussianInt2.o
    % conv1
    mex  conv1.c CFLAGS='-g $CFLAGS -std=c99 -march=native `pkg-config gsl --cflags --libs`' COPTIMFLAGS='-g -O3 -D verbose=0' ...
        LINKLIBS='$LINKLIBS -lgsl -lgslcblas -lpthread' -c    
    mex  df_conv1.c CFLAGS='$CFLAGS -g -std=c99 -march=native `pkg-config gsl --cflags --libs`' COPTIMFLAGS=' -O3 -D verbose=0' ...
        LINKLIBS='$LINKLIBS -lgsl -lgslcblas' conv1.o
    % imshift
    mex  imshift.c CFLAGS='-g $CFLAGS -std=c99 -march=native `pkg-config gsl --cflags --libs`' COPTIMFLAGS='-g -O3 -D verbose=0' ...
        LINKLIBS='$LINKLIBS -lgsl -lgslcblas' -c conv1.o
    
    mex df_blit3.c CFLAGS='$CFLAGS -std=c99 -march=native -Wall `pkg-config gsl --cflags --libs`' COPTIMFLAGS='-O3 -D verbose=0' ...
        LINKLIBS='$LINKLIBS -lgsl -lgslcblas' imshift.o conv1.o
    mex CFLAGS='$CFLAGS -std=c99 -march=native -Wall `pkg-config gsl --cflags --libs`' COPTIMFLAGS='-DNDEBUG -O3' df_gaussianInt3.c
    mex CFLAGS='$CFLAGS -std=c99 -march=native' COPTIMFLAGS='-DNDEBUG -O3' trilinear.c 

    % df_imshift
    mex  df_imshift.c CFLAGS='-g $CFLAGS -std=c99 -march=native `pkg-config gsl --cflags --libs`' COPTIMFLAGS='-g -O3 -D verbose=0' ...
        LINKLIBS='$LINKLIBS -lgsl -lgslcblas' imshift.o conv1.o
    %
    
    disp('fwhm')
    mex CFLAGS='$CFLAGS -std=c99 -march=native -Wall `pkg-config gsl --cflags --libs`' COPTIMFLAGS='-DNDEBUG -O3' LINKLIBS='$LINKLIBS -lgsl -lgslcblas' df_fwhm1d.c    
    
    cd(DOTTER_PATH)
else
    disp('Platform not supported.')
end
