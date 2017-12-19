function vsize = df_getVoxelSize()
% function vsize = df_getVoxelSize()
% asks for the voxel size

vsize = df_getConfig('getVoxelSize', 'vsize', [120,120,300]);

answer = {};
while(numel(answer) == 0)
    prompt = {sprintf('Set the voxel size for proper dot detection.\nCheck the nd2 file if you are unsure!\n\nXY:'),'Z:'};
    dlg_title = 'Input voxel size';
    num_lines = 1;
    defaultans = {num2str(vsize(1)),num2str(vsize(3))};
    answer = inputdlg(prompt,dlg_title,num_lines,defaultans);
end

vsize(1) = str2num(answer{1});
vsize(2) = vsize(1);
vsize(3) = str2num(answer{2});

df_setConfig('getVoxelSize', 'vsize', vsize);

end