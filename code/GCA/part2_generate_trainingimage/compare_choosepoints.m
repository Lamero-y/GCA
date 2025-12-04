function [choosepoints,theta]=compare_choosepoints(label_micro,Curbasic_unit, willfill_basicid,minbox_diffclass,basic_cen,k)
[fill_pixelpoints,calvalid_sort]=fill_basicunit_adjacent(label_micro,Curbasic_unit, willfill_basicid,minbox_diffclass,basic_cen,k);
[fill_pixelpoints_r,calvalid_sort_r,angle]=fill_basicunit_adjacent_r(label_micro,Curbasic_unit,willfill_basicid,minbox_diffclass,basic_cen,k);
if calvalid_sort(1)>calvalid_sort_r(1)
    choosepoints=fill_pixelpoints;
    theta=0;
else
    choosepoints=fill_pixelpoints_r;
    theta=angle;
end