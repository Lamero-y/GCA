function [Withcontain_classinfor,basic_label_update]=acquire_conclassinfor(basic_label,curfill_class,contain_toclass,car_class,clutter)
basic_label_copy=basic_label;
basic_label(basic_label~=curfill_class)=0;
% Step: 扩展道路区域边界以捕捉道路与相邻区域的接触（膨胀操作）
se = strel('disk', 15);  % 选择合适的结构元素，这里使用半径为10的圆形结构元素
expanded_road = imdilate(basic_label, se);  % 膨胀道路区域
if ismember(curfill_class,contain_toclass)
    %filled_basic_label = imfill(basic_label, 'holes');
    hole_infor=expanded_road~=0 & basic_label==0;
    hole_image=basic_label_copy.*uint8(hole_infor);
    hole_classvalue=unique(hole_image);
    % 保留路上的车
    if sum(ismember(hole_classvalue,car_class))>0
       contain_carclass_logits=zeros(size(hole_image));
       for k_car=1:length(car_class)
           con_carclass_logits=hole_image==car_class(k_car);
           contain_carclass_logits=contain_carclass_logits+con_carclass_logits;
       end
       basic_label_updatelogits= contain_carclass_logits | basic_label_copy==curfill_class;
       basic_label_update= basic_label_copy.*uint8(basic_label_updatelogits);
    else
       basic_label_update=basic_label;
    end
    % 确定包含的其他类的信息：大小，类别
    red_classinfor=setdiff(hole_classvalue,[clutter;unique(basic_label_update)]);
    Withcontain_classinfor=[];
    for k_hole=1:length(red_classinfor)
        cur_classhole= hole_image==red_classinfor(k_hole);
        curclass_stat=regionprops(cur_classhole);
        delete_idx=[curclass_stat.Area]<50;
        curclass_stat(delete_idx)=[];
        if isempty(curclass_stat)
            continue
        end
        %包含类别三个信息便于获取包含与被包含的关系信息
        withcontain_classinfor=struct('classinfor',red_classinfor(k_hole),...
                                      'containclass',curfill_class,...
                                      'Area_num',length(curclass_stat),...
                                      'Areasum',sum([curclass_stat.Area]),...
                                      'Area',[curclass_stat.Area]);
        Withcontain_classinfor=[Withcontain_classinfor;withcontain_classinfor];
    end
else
    Withcontain_classinfor=[];
    basic_label_update=basic_label;
end