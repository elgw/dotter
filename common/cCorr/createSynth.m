I = df_readTif('dapi_001.tif');
J = I;
J(4:end, 3:end, 2:end) = I(1:end-3, 1:end-2, 1:end-1);
write_tif_volume(J, 'synth_001.tif');
