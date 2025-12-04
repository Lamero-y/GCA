function croppedData = cropimage_bystep(inilabelpath,cropSize)

    labelDir = dir(fullfile(inilabelpath, '*.png'));
    flag1=1;

    for k = 1:length(labelDir)
        lab1 = imread(fullfile(inilabelpath, labelDir(k).name));
        originalSize = size(lab1);
        [strideH, strideW] = computeStride(size(lab1), cropSize);

        numRows = ceil((originalSize(1)-cropSize(1))/strideH);
        numCols = ceil((originalSize(2)-cropSize(2))/strideW);

        %initialization
        position_infor=zeros(numRows*numCols,4);
        class_infor=cell(numRows*numCols,1);
        flag=1;

        for i = 1:numRows
            for j = 1:numCols
                startRow = min((i - 1) * strideH + 1,originalSize(1) - cropSize(1) + 1);
                startCol = min((j - 1) * strideW + 1,originalSize(2) - cropSize(2) + 1);

                endRow = min(startRow + cropSize(1) - 1, originalSize(1));
                endCol = min(startCol + cropSize(2) - 1, originalSize(2));

                croppedDataImage = lab1(startRow:endRow, startCol:endCol);

                croppedImageClass = setdiff(unique(croppedDataImage), 0);

                position_infor(flag,:) = [startCol  startRow cropSize(1) - 1 cropSize(2) - 1];
                class_infor{flag} = croppedImageClass;
                flag=flag+1;
            end
        end
        classinfor_uniqeuidx = cellfun(@(x) num2str(x'), class_infor, 'UniformOutput', false);

        [uniqueCombinations, ~, idx] = unique(classinfor_uniqeuidx, 'stable');
        for k1=1:size(uniqueCombinations,1)
            classinfor_rawimage=str2num(uniqueCombinations{k1});
            classidxinfor_rawimage=idx==k1;
            newEntry.index=k;
            newEntry.classes = classinfor_rawimage;
            newEntry.position = position_infor(classidxinfor_rawimage,:);
            croppedData(flag1) = newEntry; 
            flag1=flag1+1;
        end    
    end
end
