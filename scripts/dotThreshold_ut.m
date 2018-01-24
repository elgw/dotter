function dotThreshold_ut()

disp('-> dotThreshold');

% Should not crash
th = dotThreshold(zeros(100,1));
th = dotThreshold(ones(100,1));
th = dotThreshold(rand(100,1));

end