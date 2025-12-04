function Curclass_infor = statsinfor_cropimage_bystep(inilabelpath,cropSize)
  
% 获取所有 PNG 文件
labelDir = dir(fullfile(inilabelpath, '*.png'));
Curclass_inforall = cell(1, length(labelDir));  % 预先分配 cell 数组

parfor k = 1:length(labelDir)
    % 读取每张影像
    lab1 = imread(fullfile(inilabelpath, labelDir(k).name));
    originalSize = size(lab1);
    [strideH, strideW] = computeStride(size(lab1), cropSize);
    
    % 计算行数和列数
    numRows = ceil((originalSize(1)-cropSize(1))/strideH);
    numCols = ceil((originalSize(2)-cropSize(2))/strideW);
    
    % 循环裁剪影像
    localCurclass_infor = [];  % 临时保存当前迭代的结果
    for i = 1:numRows
        for j = 1:numCols
            % 计算裁剪起始坐标
            startRow = min((i - 1) * strideH + 1,originalSize(1) - cropSize(1) + 1);
            startCol = min((j - 1) * strideW + 1,originalSize(2) - cropSize(2) + 1);

            % 设置裁剪终止坐标
            endRow = min(startRow + cropSize(1) - 1, originalSize(1));
            endCol = min(startCol + cropSize(2) - 1, originalSize(2));
            
            % 读取裁剪数据
            croppedDataImage = lab1(startRow:endRow, startCol:endCol);
            
            % 获取类别信息
            croppedImageClass = setdiff(unique(croppedDataImage), 0)'; 
            sumpixels_num = sum(croppedDataImage(:) ~= 0);
            
            class_pro = zeros(1, length(croppedImageClass));
            classcol_areanum = zeros(1, length(croppedImageClass));
            classcol_areamin = zeros(1, length(croppedImageClass));
            
            for k1 = 1:length(croppedImageClass)
                curclass = croppedImageClass(k1);
                class_pro(k1) = sum(croppedDataImage(:) == curclass) / sumpixels_num;
                curclass_imagelogits = croppedDataImage == curclass;
                stats = regionprops(curclass_imagelogits);
                if isempty(sum([stats.Area] > cropSize(1) * cropSize(2) * 0.0005))
                    classcol_areanum(k1) = 1;
                    classcol_areamin(k1) = min([stats.Area]);
                else
                    classcol_areanum(k1) = sum([stats.Area] > cropSize(1) * cropSize(2) * 0.0005);
                    classcol_areamin(k1) = min([stats.Area] > cropSize(1) * cropSize(2) * 0.0005);
                end
            end
            
            % 保存每个裁剪区域的类别信息
            localCurclass_infor = [localCurclass_infor, struct('classcol', croppedImageClass, ...
                                                              'classallnum', classcol_areanum, ...
                                                              'classallprop', class_pro, ...
                                                              'classallminarea', classcol_areamin)];
        end
    end    
    % 将每个线程的结果存储到 cell 数组中
    Curclass_inforall{k} = localCurclass_infor;
end

Curclass_inforall = [Curclass_inforall{:}];
classcol_allinfor = cellfun(@(x) num2str(x), {Curclass_inforall.classcol}, 'UniformOutput', false);
[uniqueCombinations, ~, idx] = unique(classcol_allinfor, 'stable');
Curclass_infor=[];
parfor k1=1:max(idx)
    curclassinfor=str2num(uniqueCombinations{k1});
    curclassinfor_idx=idx==k1;
    curclassallnum=vertcat(Curclass_inforall(curclassinfor_idx).classallnum);
    curclassallprop=vertcat(Curclass_inforall(curclassinfor_idx).classallprop);
    curclassallminarea=vertcat(Curclass_inforall(curclassinfor_idx).classallminarea);
    
    % 获取区域数的分布以及在不同区域数下占比的分布
    curclass_areanumpro=zeros(length(curclassinfor),max(curclassallnum(:)));
    curclass_areanumpro_allpro=cell(1,length(curclassinfor));
    curclass_areanumpro_allmin=zeros(length(curclassinfor),max(curclassallnum(:)));
    
    for k2=1:length(curclassinfor)
        curclass_areanum=curclassallnum(:,k2);
        [areanum_counts, ~] = histcounts(curclass_areanum, [1:1+max(curclassallnum(:))]);
        areanum_hist=areanum_counts./sum(areanum_counts);
        
        % stats the information of araenum
        curclass_areanumpro(k2,:)=areanum_hist;
        % Statistical analysis of proportions under different regions
        Curclass_areanumpro=zeros(length(areanum_counts),10);

        for k3=1:length(areanum_counts)
            %pro
            curclass_areanumidx= curclass_areanum==k3;
            if sum(curclass_areanumidx)==0
                continue;
            end
            curclass_areanum_pro=curclassallprop(curclass_areanumidx,k2);
            [areanumpro_counts, ~] = histcounts(curclass_areanum_pro, [0:0.1:1]);
            Curclass_areanumpro(k3,:)=areanumpro_counts./sum(areanumpro_counts);
            %min value
            curclass_areanum_min=curclassallminarea(curclass_areanumidx,k2);
            if ~isempty(min(curclass_areanum_min(curclass_areanum_min>cropSize(1) * cropSize(2) * 0.0005)))
               curclass_areanumpro_allmin(k2,k3)=min(curclass_areanum_min(curclass_areanum_min>cropSize(1) * cropSize(2) * 0.0005));
            end
        end
        curclass_areanumpro_allpro{k2}=Curclass_areanumpro;
    end
    Curclass_infor = [Curclass_infor, struct('classcol', curclassinfor, ...
                                             'classcol_totalnum', sum(curclassinfor_idx), ...
                                             'classnum_todistribution', curclass_areanumpro, ...
                                             'classpro_todistribution', {curclass_areanumpro_allpro},...
                                             'classminarea',curclass_areanumpro_allmin)];
end
