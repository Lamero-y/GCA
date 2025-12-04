function [fill_pixelpoints]=subrandcrop_image(label,window_size,curclass_area)

row_submatrix = size(label, 1) / window_size(1);
col_submatrix = size(label, 2) / window_size(2);
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
            currentl_fillblock = label(startRow:(startRow + window_size(1) - 1), startCol:(startCol + window_size(2) - 1));
            cal_valid_features= (currentl_fillblock~=0);
            Cal_adjacentnum=[Cal_adjacentnum sum(cal_valid_features(:)==1)];
            StartRow=[StartRow startRow];
            StartCol=[StartCol startCol];
        elseif row>=row_subma && col<col_subma 
            startRow = size(label,1)-window_size(1)+1;
            startCol = (col - 1) * window_size(2)+ 1;
            currentl_fillblock = label(startRow:(startRow + window_size(1) - 1), startCol:(startCol + window_size(2) - 1));
            cal_valid_features= (currentl_fillblock~=0);
            %cal_valid_features= (currentl_fillblock==curfill_class) & (mask_label_micro~=0);
            Cal_adjacentnum=[Cal_adjacentnum sum(cal_valid_features(:)==1)];
            StartRow=[StartRow startRow];
            StartCol=[StartCol startCol];
        elseif row<row_subma && col>=col_subma 
            startRow = (row - 1) *  window_size(1)  + 1;
            startCol = size(label,2)-window_size(2)+1;
            currentl_fillblock = label(startRow:(startRow + window_size(1) - 1), startCol:(startCol + window_size(2) - 1));
            cal_valid_features= (currentl_fillblock~=0);
            %cal_valid_features= (currentl_fillblock==curfill_class) & (mask_label_micro~=0);
            Cal_adjacentnum=[Cal_adjacentnum sum(cal_valid_features(:)==1)];
            StartRow=[StartRow startRow];
            StartCol=[StartCol startCol];
        else row>=row_subma && col>=col_subma
            startRow = size(label,1)-window_size(1)+1;
            startCol = size(label,2)-window_size(2)+1;
            currentl_fillblock = label(startRow:(size(label,1)-1), startCol:(size(label,2)-1));
            currentl_window(1:size(currentl_fillblock,1),1:size(currentl_fillblock,2))=currentl_fillblock;
            currentl_fillblock=currentl_window;
            cal_valid_features= (currentl_fillblock~=0);
            Cal_adjacentnum=[Cal_adjacentnum sum(cal_valid_features(:)==1)];
            StartRow=[StartRow startRow];
            StartCol=[StartCol startCol];
        end
    end
end
[~,calfeature_maxidx]=min(abs(Cal_adjacentnum-curclass_area));
cropRow=StartRow(calfeature_maxidx);
cropCol=StartCol(calfeature_maxidx);
fill_pixelpoints=[cropRow cropCol];
end