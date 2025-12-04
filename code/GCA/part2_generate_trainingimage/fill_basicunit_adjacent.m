function [fill_pixelpoints,curvalid]=fill_basicunit_adjacent(label_micro,Curbasic_unit,k4,minbox_diffclass,basic_cen,k)
%[fill_pixelpoints]=fill_basicunit_adjacent(label_micro,Curbasic_unit, k4=willfill_basicid,minbox_diffclass);
%mask_label_micro表示上个区域的填充位置,判断相邻相离包含关系的
%pick_submatrix(rotated_region_info,image_rotated_region_info,mask_label_micro_c,gray_currentfill,areawfill_infor,willfill_area);
current_basiclabel=Curbasic_unit{k4,1};
current_basiclabel(all(current_basiclabel==0,2),:)=[];
current_basiclabel(:,all(current_basiclabel==0,1))=[];
curclass=Curbasic_unit{k4,3};%填充basic unit的类别
adjacent_class=Curbasic_unit{k4,6};%填充的basicunit的邻接类别
curbasic_validpixels=sum(current_basiclabel(:)~=0);
window_size=size(current_basiclabel); %mask_label_micro上当前需填充的区域尺寸信息
window_minsize=minbox_diffclass{curclass,1};
step_row=window_minsize(1);
step_col=window_minsize(2);
% 对每一列进行处理，columns 的列数即为窗口的数量
s = size(label_micro, 1) ;
% 获取当前类别已填充basic unit的中心
all_fillclass_equalcurclass=[basic_cen{:,1}]==curclass;
all_stats_centroid = cell2mat(basic_cen(all_fillclass_equalcurclass,2));
%记录当前切块的起始坐标以及有效特征数值
Cal_adjacentnum=[]; Cal_valid_features= [];Cal_exitsamebasic=[];
StartRow=[]; StartCol=[];
curexit_class=setdiff(unique(label_micro),0)';
if ismember(adjacent_class,curexit_class) & length(adjacent_class)==1%影像中存在basic unit的邻接关系
    for row=1: step_row:s-window_size(1)+1
        for col = 1: step_col:s-window_size(2)+1
            currentl_fillblock = label_micro(row:(row + window_size(1) - 1), col:(col + window_size(2) - 1));
            already_allcurclasspixels=sum(currentl_fillblock(:)==curclass);
            fillimage_info=double(currentl_fillblock)+double(current_basiclabel);
            Cal_valid_features= [Cal_valid_features sum(fillimage_info(:)==curclass)-already_allcurclasspixels];
            %结合currentl_fillblock 与current_basiclabel，计算其是否存在相邻信息
            cal_valid_adjacent = (currentl_fillblock==adjacent_class) & (current_basiclabel==curclass);
            Cal_adjacentnum=[Cal_adjacentnum sum(cal_valid_adjacent(:)==1)];
            %获取当前类别是否与同类像素重叠，若重叠则剔除
            cal_exitsamebasic= (currentl_fillblock==curclass) & (current_basiclabel==curclass);
            Cal_exitsamebasic=[Cal_exitsamebasic sum(cal_exitsamebasic(:)==1)];
            StartRow=[StartRow row];
            StartCol=[StartCol col];
        end
    end
    %剔除存在相同类别重叠的区域信息
    bestfound_choose=find(Cal_exitsamebasic==0);
    [ad_value,ad_id]=sort(Cal_adjacentnum(bestfound_choose));
    [valid_value,valid_id]=sort(Cal_valid_features(bestfound_choose),'descend');
    ad_valid_infor=ad_id(ad_value<curbasic_validpixels*0.2);
    valid_infor=valid_id(valid_value>curbasic_validpixels*0.8);
    third_statscon=intersect(ad_valid_infor,valid_infor);
    
    if ~isempty(third_statscon)
       selected_id=valid_id(valid_value==max(Cal_valid_features(bestfound_choose(third_statscon))));
       rng( 406 + k, 'twister');
       selected_id=selected_id(randperm(length(selected_id),1));
       curvalid=Cal_valid_features(bestfound_choose(selected_id));
       cropRow=StartRow(bestfound_choose(selected_id));
       cropCol=StartCol(bestfound_choose(selected_id));
       fill_pixelpoints=[cropRow cropCol];
       
    elseif ~isempty(valid_infor)
       choose_idx=bestfound_choose(valid_infor);
       [~,valid_id]=sort(Cal_valid_features(choose_idx),'descend');
       rng( 406 + k, 'twister');
       selected_id= bestfound_choose(valid_id(randperm(length(valid_id),1)));
       curvalid=Cal_valid_features(selected_id);
       cropRow=StartRow(selected_id);
       cropCol=StartCol(selected_id);
       fill_pixelpoints=[cropRow cropCol];
    elseif isempty(valid_infor)
        [~,valid_id]=sort(Cal_valid_features,'descend');
        selected_id= valid_id(1);
        curvalid=Cal_valid_features(selected_id);
        cropRow=StartRow(selected_id);
        cropCol=StartCol(selected_id);
        fill_pixelpoints=[cropRow cropCol];
    end
elseif length(adjacent_class)>=1%
    for row=1: step_row:s-window_size(1)+1
        for col = 1: step_col:s-window_size(2)+1
            currentl_fillblock = label_micro(row:(row + window_size(1) - 1), col:(col + window_size(2) - 1));
            already_allcurclasspixels=sum(currentl_fillblock(:)==curclass);
            fillimage_info=double(currentl_fillblock)+double(current_basiclabel);
            Cal_valid_features= [Cal_valid_features sum(fillimage_info(:)==curclass)-already_allcurclasspixels];
            %获取当前类别是否与同类像素重叠，若重叠则剔除
            cal_exitsamebasic= (currentl_fillblock==curclass) & (current_basiclabel==curclass);
            Cal_exitsamebasic=[Cal_exitsamebasic sum(cal_exitsamebasic(:)==1)];
            StartRow=[StartRow row];
            StartCol=[StartCol col];
        end
    end
    %剔除存在相同类别重叠的区域信息
    bestfound_choose=find(Cal_exitsamebasic==0 & Cal_valid_features>=curbasic_validpixels*0.8);
    if ~isempty(bestfound_choose)
        valid_infor=[];
        thres=1;
        while isempty(valid_infor)
            valid_infor=bestfound_choose(Cal_valid_features(bestfound_choose)>=curbasic_validpixels*thres);
            thres=thres-0.1;
        end
       rng(556 + k, 'twister');
       selected_id=valid_infor(randperm(length(valid_infor),1)); 
       curvalid=Cal_valid_features(selected_id);
       cropRow=StartRow(selected_id);
       cropCol=StartCol(selected_id);
       fill_pixelpoints=[cropRow cropCol];
    elseif isempty(bestfound_choose)
        valid_infor=[];
        thres=1;
        while isempty(valid_infor)
            valid_infor=find(Cal_valid_features>=curbasic_validpixels*thres);
            thres=thres-0.1;
        end
        rng(556 + k, 'twister');
        selected_id= valid_infor(randperm(length(valid_infor),1));
        curvalid=Cal_valid_features(selected_id);
        cropRow=StartRow(selected_id);
        cropCol=StartCol(selected_id);
        fill_pixelpoints=[cropRow cropCol];
    end
else
    %原图
    for row=1: step_row:s-window_size(1)+1
        for col = 1: step_col:s-window_size(2)+1
            currentl_fillblock = label_micro(row:(row + window_size(1) - 1), col:(col + window_size(2) - 1));
            already_allcurclasspixels=sum(currentl_fillblock(:)==curclass);
            fillimage_info=double(currentl_fillblock)+double(current_basiclabel);
            Cal_valid_features= [Cal_valid_features sum(fillimage_info(:)==curclass)-already_allcurclasspixels];
            %获取当前类别是否与同类像素重叠，若重叠则剔除
            cal_exitsamebasic= (currentl_fillblock==curclass) & (current_basiclabel==curclass);
            Cal_exitsamebasic=[Cal_exitsamebasic sum(cal_exitsamebasic(:)==1)];
            StartRow=[StartRow row];
            StartCol=[StartCol col];
        end
    end
    %剔除存在相同类别重叠的区域信息
    bestfound_choose=find(Cal_exitsamebasic==0 & Cal_valid_features>=curbasic_validpixels*0.5);
    if ~isempty(bestfound_choose)
        valid_infor=[];
        thres=1;
        while isempty(valid_infor)
            valid_infor=bestfound_choose(Cal_valid_features(bestfound_choose)>=curbasic_validpixels*thres);
            thres=thres-0.1;
        end
       rng(556 + k, 'twister');
       selected_id=valid_infor(randperm(length(valid_infor),1)); 
       curvalid=Cal_valid_features(selected_id);
       cropRow=StartRow(selected_id);
       cropCol=StartCol(selected_id);
       fill_pixelpoints=[cropRow cropCol];
    elseif isempty(bestfound_choose)
        valid_infor=[];
        thres=1;
        while isempty(valid_infor)
            valid_infor=find(Cal_valid_features>=curbasic_validpixels*thres);
            thres=thres-0.1;
        end
        rng(556 + k, 'twister');
        selected_id= valid_infor(randperm(length(valid_infor),1));
        curvalid=Cal_valid_features(selected_id);
        cropRow=StartRow(selected_id);
        cropCol=StartCol(selected_id);
        fill_pixelpoints=[cropRow cropCol];
    end
end


