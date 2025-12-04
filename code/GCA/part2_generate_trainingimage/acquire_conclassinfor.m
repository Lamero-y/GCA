function [Withcontain_classinfor,basic_label,curbasic_boxb]=acquire_conclassinfor(basic_label,curfill_class,contain_toclass,car_class,clutter)
basic_label_copy=basic_label;
basic_label(basic_label~=curfill_class)=0;
%%获取当前所有类别的区域信息
cur_classcol=setdiff(unique(basic_label_copy),[0 clutter curfill_class]);
State=[];Withcontain_classinfor=[]; curbasic_boxb=[];
for k1=1:length(cur_classcol)
    curclass=cur_classcol(k1);
    curclass_logits=basic_label_copy==curclass;
    stats_curclass=regionprops(curclass_logits,'Area', 'BoundingBox', 'PixelIdxList', 'Centroid');
    deleta_idx=[stats_curclass.Area]<50;
    stats_curclass(deleta_idx)=[];
    curclass_Area=[];curclass_Areasum=0;curclass_boxb=[];
    for k2=1:length(stats_curclass)
        regionk2_mask = false(size(basic_label_copy));
        % 使用 PixelIdxList 获取第 k2 个区域的像素索引
        regionk2_mask(stats_curclass(k2).PixelIdxList) = true;
        %判断该区域是否包围在当前填充类别区域
        both_regionmask=regionk2_mask+(basic_label~=0);
        stats_Determine=regionprops(both_regionmask);
        if size(stats_Determine,1)==1 && ~ismember(curclass,car_class)
            curclass_Area=[curclass_Area stats_curclass(k2).Area];
            curclass_Areasum=curclass_Areasum+sum([stats_curclass(k2).Area]);
            curclass_boxb=[curclass_boxb;stats_curclass(k2).BoundingBox];
        elseif size(stats_Determine,1)==1 && ismember(curclass,car_class)
            basic_label=uint8(both_regionmask).*basic_label_copy;
        end
    end 
    if ~isempty(curclass_Area)
        withcontain_classinfor=struct('classinfor',curclass,...
                                  'containclass',curfill_class,...
                                  'Area_num',numel(curclass_Area),...
                                  'Areasum',curclass_Areasum,...
                                  'Area',curclass_Area);
                                 % 'fill_boxb',curclass_boxb);
        Withcontain_classinfor=[Withcontain_classinfor;withcontain_classinfor];
        curbasic_boxb=[curbasic_boxb;curclass_boxb];
    else
        Withcontain_classinfor=[];
        curbasic_boxb=[];
    end
end