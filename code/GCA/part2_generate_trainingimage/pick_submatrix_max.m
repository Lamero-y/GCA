function [fill_pixelpoints]=pick_submatrix_max(label_micro,current_basiclabel,k)
%mask_label_micro表示上个区域的填充位置,判断相邻相离包含关系的
%pick_submatrix(rotated_region_info,image_rotated_region_info,mask_label_micro_c,gray_currentfill,areawfill_infor,willfill_area);
window_size=size(current_basiclabel);%mask_label_micro上当前需填充的区域尺寸信息
% 对每一列进行处理，columns 的列数即为窗口的数量
row_submatrix = size(label_micro, 1) / window_size(1);
col_submatrix = size(label_micro, 2) / window_size(2);
row_subma=ceil(row_submatrix);
col_subma=ceil(col_submatrix);
%记录当前切块的起始坐标以及有效特征数值
Cal_adjacentnum=[]; 
StartRow=[]; StartCol=[];
Rowcol=[];Colcol=[];
for row=1: row_subma
    for col = 1: col_subma
        currentl_window=zeros(window_size);
        if row<row_subma && col<col_subma
            startRow = (row - 1) *  window_size(1)  + 1;
            startCol = (col - 1) * window_size(2)+ 1;
            currentl_fillblock = label_micro(startRow:(startRow + window_size(1) - 1), startCol:(startCol + window_size(2) - 1));
            cal_valid_features= (currentl_fillblock==0);
%             cal_valid_features= (currentl_fillblock==curfill_class) & (mask_label_micro~=0);
            Cal_adjacentnum=[Cal_adjacentnum sum(cal_valid_features(:)==1)];
            StartRow=[StartRow startRow];
            StartCol=[StartCol startCol];
        elseif row>=row_subma && col<col_subma 
            startRow = size(label_micro,1)-window_size(1)+1;
            startCol = (col - 1) * window_size(2)+ 1;
            currentl_fillblock = label_micro(startRow:(startRow + window_size(1) - 1), startCol:(startCol + window_size(2) - 1));
            cal_valid_features= (currentl_fillblock==0);
            %cal_valid_features= (currentl_fillblock==curfill_class) & (mask_label_micro~=0);
            Cal_adjacentnum=[Cal_adjacentnum sum(cal_valid_features(:)==1)];
            StartRow=[StartRow startRow];
            StartCol=[StartCol startCol];
        elseif row<row_subma && col>=col_subma 
            startRow = (row - 1) *  window_size(1)  + 1;
            startCol = size(label_micro,2)-window_size(2)+1;
            currentl_fillblock = label_micro(startRow:(startRow + window_size(1) - 1), startCol:(startCol + window_size(2) - 1));
            cal_valid_features= (currentl_fillblock~=0);
            %cal_valid_features= (currentl_fillblock==curfill_class) & (mask_label_micro~=0);
            Cal_adjacentnum=[Cal_adjacentnum sum(cal_valid_features(:)==1)];
            StartRow=[StartRow startRow];
            StartCol=[StartCol startCol];
        else row>=row_subma && col>=col_subma
            startRow = size(label_micro,1)-window_size(1)+1;
            startCol = size(label_micro,2)-window_size(2)+1;
            currentl_fillblock = label_micro(startRow:(size(label_micro,1)-1), startCol:(size(label_micro,2)-1));
            currentl_window(1:size(currentl_fillblock,1),1:size(currentl_fillblock,2))=currentl_fillblock;
            currentl_fillblock=currentl_window;
            cal_valid_features= (currentl_fillblock==0);
            %cal_valid_features= (currentl_fillblock==curfill_class) & (mask_label_micro==1);
            Cal_adjacentnum=[Cal_adjacentnum sum(cal_valid_features(:)==1)];
            StartRow=[StartRow startRow];
            StartCol=[StartCol startCol];
        end
    end
end
%将当前有效特征数值最接近willfill_area的值即为获取的填充basic unit
%[calfeature_maxvalue,calfeature_maxidx]=min(abs(Cal_adjacentnum-willfill_area));

fillchoose_idx=find(Cal_adjacentnum==max(Cal_adjacentnum));
%随机取值
rng(556 + k, 'twister');
rand_idx=randperm(length(fillchoose_idx),1);
cropRow=StartRow(fillchoose_idx(rand_idx));
cropCol=StartCol(fillchoose_idx(rand_idx));
fill_pixelpoints=[cropRow cropCol];
% crop_rowlength=Rowcol(calfeature_maxidx(1));
% crop_collength=Colcol(calfeature_maxidx(1));
