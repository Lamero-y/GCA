function [fill_pixelpoints]=pick_suitarea(label_micro,basiclabel,k)
%label_micro=basic_label;
window_size=size(basiclabel);
row_submatrix = size(label_micro, 1) / window_size(1);
col_submatrix = size(label_micro, 2) / window_size(2);
row_subma=ceil(row_submatrix);
col_subma=ceil(col_submatrix);
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
            cal_valid_features= (currentl_fillblock~=0) & (basiclabel==0);
            Cal_adjacentnum=[Cal_adjacentnum sum(cal_valid_features(:)==1)];
            StartRow=[StartRow startRow];
            StartCol=[StartCol startCol];
        elseif row>=row_subma && col<col_subma 
            startRow = size(label_micro,1)-window_size(1)+1;
            startCol = (col - 1) * window_size(2)+ 1;
            currentl_fillblock = label_micro(startRow:(startRow + window_size(1) - 1), startCol:(startCol + window_size(2) - 1));
            cal_valid_features= (currentl_fillblock~=0) & (basiclabel==0);
            Cal_adjacentnum=[Cal_adjacentnum sum(cal_valid_features(:)==1)];
            StartRow=[StartRow startRow];
            StartCol=[StartCol startCol];
        elseif row<row_subma && col>=col_subma 
            startRow = (row - 1) *  window_size(1)  + 1;
            startCol = size(label_micro,2)-window_size(2)+1;
            currentl_fillblock = label_micro(startRow:(startRow + window_size(1) - 1), startCol:(startCol + window_size(2) - 1));
            cal_valid_features= (currentl_fillblock~=0) & (basiclabel==0);
            Cal_adjacentnum=[Cal_adjacentnum sum(cal_valid_features(:)==1)];
            StartRow=[StartRow startRow];
            StartCol=[StartCol startCol];
        else row>=row_subma && col>=col_subma
            startRow = size(label_micro,1)-window_size(1)+1;
            startCol = size(label_micro,2)-window_size(2)+1;
            currentl_fillblock = label_micro(startRow:(size(label_micro,1)-1), startCol:(size(label_micro,2)-1));
            currentl_window(1:size(currentl_fillblock,1),1:size(currentl_fillblock,2))=currentl_fillblock;
            currentl_fillblock=currentl_window;
            cal_valid_features= (currentl_fillblock~=0) & (basiclabel==0);
            Cal_adjacentnum=[Cal_adjacentnum sum(cal_valid_features(:)==1)];
            StartRow=[StartRow startRow];
            StartCol=[StartCol startCol];
        end
    end
end
fillchoose_idx=find(Cal_adjacentnum==max(Cal_adjacentnum));
rng(376 + k, 'twister');
rand_idx=randperm(length(fillchoose_idx),1);
cropRow=StartRow(fillchoose_idx(rand_idx));
cropCol=StartCol(fillchoose_idx(rand_idx));
fill_pixelpoints=[cropRow cropCol];

