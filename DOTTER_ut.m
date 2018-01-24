function DOTTER_ut()

hasJava = usejava('jvm');
if hasJava
    disp('-> Open and close DOTTER main GUI')
    % should produce no errors
    DOTTER();
    h = findall(0,'tag','DOTTER');
    close(h);
end

end