function [basic_image,basic_label,sampledp]=randcrop_image(Given_infor,sampledpoints_id,selected_boxb,curfill_class,curclass_area)
%Given_infor,sampledpoints_id,selected_boxb=statscurclass_boundingbox,curfill_class,curclass_area
imagepath=Given_infor.imagepath;
labelpath=Given_infor.labelpath;
s=Given_infor.s;
labelDir=dir([labelpath '*.png']);
original_image = imread([imagepath labelDir(sampledpoints_id).name]);
original_label = imread([labelpath labelDir(sampledpoints_id).name]);
rawbasic_image = imcrop(original_image,selected_boxb);
rawbasic_label = imcrop(original_label,selected_boxb);
rawbasic_label_copy = rawbasic_label;
rawbasic_label(rawbasic_label~=curfill_class)=0;
[curbasic_row,curbasic_col,~]=size(rawbasic_image);
if curbasic_row>s || curbasic_col>s
    if curbasic_row>s && curbasic_col<=s
        window_size=[s,curbasic_col];
    elseif curbasic_row<=s && curbasic_col>s
        window_size=[curbasic_row,s];
    elseif curbasic_row>s && curbasic_col>s
        window_size=[s,s];
    end
    fill_pixelpoints=subrandcrop_image(rawbasic_label,window_size,curclass_area);
    basic_image=imcrop(rawbasic_image,[fill_pixelpoints(2) fill_pixelpoints(1) window_size(2)-1 window_size(1)-1]);
    basic_label=imcrop(rawbasic_label_copy,[fill_pixelpoints(2) fill_pixelpoints(1) window_size(2)-1 window_size(1)-1]);
    sampledp=2;
else
    basic_image=rawbasic_image;
    basic_label=rawbasic_label_copy;
    sampledp=1;
end
    
    