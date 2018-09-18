function df_volumesSpheresIntersection_ut()
% df_volumesSpheresSampling calculates the overlap between two sets of
% spheres.

s.plot = 0;
s.compile = 0;

if s.compile
    compile()
end

test_arguments();

% Tests with one sphere in each set

test_self_intersect();
test_no_intersect();
test_rotational_invariance();
test_precision();
test_performance();

visplot();

    function test_performance()
        nsamples = 10e5;
        A = rand(17, 3);
        B = rand(21, 3);
        tic
        V = df_volumesSpheresIntersection(1, A, B, nsamples);
        t= toc;
        fprintf('%f s for %d + %d dots and %d sample points\n', ...
            t, size(A,1), size(B,1), nsamples);
    end


    function test_precision()
        
        nsamples = 10.^(linspace(3,7,15));
        error = zeros(numel(nsamples),1);
        for kk = 1:numel(nsamples)
            error(kk) = 4/3*pi - df_volumesSpheresIntersection(1, [1,1,1], [1,1,1], nsamples(kk));
        end
        
        if s.plot
            figure
            semilogx(nsamples, abs(error));
            hold on
            semilogx(nsamples, abs(error), 'o');
            xlabel('Number of sample points')
            ylabel('absolute error')
        end
        
    end

    function test_arguments()
        
        gotError = 0;
        try
            df_volumesSpheresIntersection()
        catch e
            gotError = 1;
        end
        assert(gotError == 1);
        
        gotError = 0;
        try
            df_volumesSpheresIntersection(2, [1,1,1], [2,2,2], -2)
        catch e
            gotError = 1;
        end
        assert(gotError == 1);
        
    end

    function test_rotational_invariance()
        N = 100;
        ivolume = zeros(N,1);
        A = rand(1,3);
        for kk = 1:N
            delta = rand(1,3);
            B = A + .5*delta/norm(delta); % B in random direction from A
            radius = 1;
            ivolume(kk) = df_volumesSpheresIntersection(radius, A, B);
        end
        error = max(ivolume)-min(ivolume);
        assert(error<0.01);
    end

    function test_no_intersect()
        for kk = 1:100
            A = rand(1,3);
            B = rand(1,3);
            dist = norm(A-B);
            radius = dist/2;
            ivolume = df_volumesSpheresIntersection(radius, A, B);
            tvolume = 0;
            error = abs(ivolume-tvolume);
            assert(error<0.01);
        end
    end

    function test_self_intersect()
        % Intersection between a sphere and itself, for different radius and
        % locations.
        for kk = 1:100
            A = rand(1,3);  %
            B = A;
            radius = 1+2*rand(1);
            ivolume = df_volumesSpheresIntersection(radius, A, B);
            tvolume = 4/3*pi*radius^3;
            error = abs(ivolume-tvolume)/tvolume;
            assert(error<0.02);
        end
    end

    function visplot()
        if s.plot
            figure,
            hold on
            for kk = 1:10
                dists = linspace(0,2, 10);
                is = 0*dists;
                for kk = 1:numel(dists)
                    dist = dists(kk);
                    A = [0,0,0]; %rand(1,3);
                    delta = rand(1,3);
                    B = A + dist*delta/norm(delta);
                    is(kk) = df_volumesSpheresIntersection(1, A, B);
                    % Symmetric in the input sets
                    assert(abs(df_volumesSpheresIntersection(1, A, B) - df_volumesSpheresIntersection(1, B, A))<0.1);
                end
                plot(dists, is);
            end
        end
    end

    function compile()
        mex -v  df_volumesSpheresIntersection.c COPTIMFLAGS='-O3 -DNDEBUG' LDOPTIMFLAGS='-O3 -flto -DNDEBUG'
    end

end