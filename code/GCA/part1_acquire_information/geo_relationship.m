function [Intrainfor,Difclass_pixelsnum,AreaRelationship]=geo_relationship(gray_value,image,label,ignored_value,pro,N)
%geo_relationship函数的作用：
%    geo_relationship(gray_value,image,label,ignored_value,pro,k);
%   (1) module B的实现：For each raw observed image and its ground truth, it extracts basic unit information for each class present in the subregion.
%   (2) 获取类间关系信息: adjcant_relationship,contain_relationship,containwith_relationship
%
% Output：(1)gray_value：数据集的类别 (2)label:ground truth (3)ignored_value:忽略标签对应的灰度值
%         (4)pro:basic unit的area阈值输入(判别basic unit是否有效) (5)k:原始数据的顺序索引
%
% Intrainfor由12个字段组成：  
%        (1)Image_index:记录原始数据顺序索引        
%        (2)Current_class:记录当前basic unit的类别值(根据子区域的类别值进行遍历，获取basic unit)
%        (3)Area_num:记录子区域在Current_class下的basic unit的总数
%        (4)Area(size:Area_num*1)：记录子区域在Current_class下的各个basic unit的有效像素总数
%        (5)Centroid(size:Area_num*2)：记录子区域在Current_class下的各个basic unit的中心坐标
%        (6)BoundingBox(size:Area_num*4)：记录子区域在Current_class下的各个basic unit的BoundingBox信息
%        (7)Sparity(size:Area_num*1):记录子区域在Current_class下的各个basic unit的稀疏度信息
%        (8)Distance_infor(size:Area_num*Area_num):记录子区域在Current_class下的各个basic unit之间的距离信息

%% initialization
% Intrainfor=struct('Image_index',[],'Current_class',[],'Area',[],'Centroid',[],'BoundingBox',[], 'Sparity',[],'Sameclass_Disvalue',[],...
%            'Boundary_judgment',[],'counts_histogram',[]);  
adjcant_relationship=zeros(length(gray_value));
contain_relationship=zeros(length(gray_value));
containwith_relationship=zeros(length(gray_value));
% Difclass_pixelsnum=struct('Image_index',[],'Current_class',[],'Pixelsnum',[]);
[m,n]=size(label); %当前影像的尺寸
classcol=unique(label); %当前影像的类别集合
classcol(classcol==ignored_value)=[];%删除0值
s=512;

%% 利用regionprops函数依次记录影像中各个类别下的区域信息(basic unit)
% 注：在之后的代码中(主代码的49-163行)会对获取的区域信息进行二次判断: 
%     若获取的basic unit的尺寸在s*s内，则认为其为basic unit，
%     反之，则将去按照记录区域的最小尺寸的倍数作为窗口尺寸，以一定步长对basic unit进行获取
isempty_idx = [];
Intrainfor = []; % 预先定义结构体数组
Difclass_pixelsnum = [];
parfor k1=1:length(classcol)
    currentclass_region_logits=(label==classcol(k1)); %获取label影像上类别值为classcol(k1)对应的逻辑矩阵
    currentclass_region_imagelogits=repmat(currentclass_region_logits,[1 1 3]);
    currentclass_image=image.*uint8(currentclass_region_imagelogits);
    current_class_indices=find(gray_value==classcol(k1));%获取在该循环下对应的类别索引(也是类别值)
    current_classnum=sum(currentclass_region_logits(:));
    %% step1：构造灰度图（标签本身就是灰度图）
    label_rgb_1 = uint8(currentclass_region_logits) * 255;  % R 通道
    label_rgb_2 = uint8(currentclass_region_logits) * 0;    % G 通道
    label_rgb_3 = uint8(currentclass_region_logits) * 0;    % B 通道
    yy_zeros=zeros(m+2,n+2,3);
    yy_zeros(2:1+m,2:1+n,1)=label_rgb_1;
    yy_zeros(2:1+m,2:1+n,2)=label_rgb_2;
    yy_zeros(2:1+m,2:1+n,3)=label_rgb_3;

    %% step3：使用 MeanShift（edison_wrapper）
    [~,labels] = edison_wrapper(yy_zeros, @RGB2Luv, ...
                                   'MinimumRegionArea',100);
    labels(rgb2gray(yy_zeros)==0)=0;%若某个区域内部存在一个封闭的标黑区域，漂移会将其作为划分为一个区域
    labels_ori = labels(2:1+m, 2:1+n);
    stats_c = regionprops(labels_ori,'all');
    %stats_c = regionprops(currentclass_region_logits,'Area', 'Centroid', 'BoundingBox');   
%     % 剔除面积小于阈值的区域
%     toosmall_logical = [stats_c.Area] < s*s*pro; % 逻辑索引，表示面积小于阈值的区域
%     stats_c(toosmall_logical) = []; % 剔除一些错误信息（极小区域信息）
%     if isempty(stats_c1)
%         isempty_idx=[isempty_idx k1];
%         continue
%     end
    %获取在该循环下的basic unit的信息：
    local_intrainfor = []; % 临时保存当前迭代的 Intrainfor
    local_difclass_pixelsnum = []; % 临时保存当前迭代的 Difclass_pixelsnum
    for k2 = 1:length(stats_c)
        % 1. 计算当前类别下各个 basic unit 之间的欧式距离
        centroids = reshape([stats_c.Centroid], 2, []).';
        distances = pdist2(centroids, centroids);
        distances(eye(size(distances)) == 1) = inf; % 将对角线距离设置为无穷大，避免自比较
        Sameclass_Disvalue = min(distances(k2, :));
        
        % 2. 当前类别的area信息
        area_currentclass=stats_c(k2).Area;
        % 3. area的中心信息集合
        area_centercol=stats_c(k2).Centroid;
        % 4. area的BoundingBox信息集合
        curbasic_box=stats_c(k2).BoundingBox;
        area_boxcol=curbasic_box;         
        % 5. 计算area的稀疏度
        Spar=stats_c(k2).Area/(curbasic_box(3)*curbasic_box(4)); 
        % 6. basic unit的边界判定
        % 6.1 起始点的判断
        if sum(ismember(ceil([curbasic_box(1) curbasic_box(2)]),[1 m n]))>=1 || ... % 起始点判断
                sum(ismember(ceil([curbasic_box(1) curbasic_box(2)])+[curbasic_box(3) curbasic_box(4)],[1 m n]))>=1 % 末尾点判断
            Boundary_judg=1;%表示该basic unit在四边上
        else
            Boundary_judg=2;
        end
        %7. counts_histogram计算
        currenregion_image=imcrop(currentclass_image,curbasic_box);
        currenregion_label=imcrop(currentclass_region_logits,curbasic_box);
        current_onlyoneclassimage=currenregion_image(currenregion_label);
        [countsA,~] = histcounts(current_onlyoneclassimage, 256);
        % 将该区域下的当前类别的basic unit的上述6个信息汇总到region_info结构体中
        curclass_info = struct('Image_index',N,'Current_class',current_class_indices,'Area',area_currentclass,...
             'Centroid',area_centercol,'BoundingBox',area_boxcol,'Sparity',Spar,'Sameclass_Disvalue', ...
             Sameclass_Disvalue,'Boundary_judgment',Boundary_judg,'counts_histogram',countsA);
        difclass_pixelsnum=struct('Image_index',N,'Current_class',current_class_indices,'Pixelsnum',current_classnum);
        
        local_intrainfor = [local_intrainfor; curclass_info];
        local_difclass_pixelsnum = [local_difclass_pixelsnum; difclass_pixelsnum];
    end
    % 合并当前迭代的结果到最终结果中
    Intrainfor = [Intrainfor; local_intrainfor];
    Difclass_pixelsnum = [Difclass_pixelsnum; local_difclass_pixelsnum];
end
% 该类区域信息获取完毕
        
%% 获取当前影像的类间信息：(被)包围关系，相邻关系
% 类间信息的判断:(1)将当前类别的区域进行膨胀，获取其对应的边界坐标，
%               (2)根据坐标获取标记影像对应的像素值,根据其值进行判断：
%                   * 若边界像素值均为同一值，则表示该类区域被包围，记录；
%                   * 若边界像素值为多个值，则表示当前该类区域与其相邻，记录。
classcol(isempty_idx)=[]; %isempty_idx是该类别下获取的basic unit尺寸均较小,不予考虑，因此在这里将剔除该类别信息
adjcant_relationship_pro=cell(1,length(classcol));
parfor k3=1:length(classcol)
    current_class_indices = double(classcol(k3)); %获取在该循环下对应的类别索引(也是类别值)
    labeldilate_logiuts = (label==current_class_indices); %获取当前类别对应区域的逻辑矩阵
    %利用regionprops获取膨胀后影像各个类别的边界信息，并根据该边界信息获取其在label上对应的像素值，从而获取其周边邻域信息
    SE = strel('disk',10); 
    label_dilate=imdilate(labeldilate_logiuts,SE);
    [dilate_labels, ~] = bwlabel(label_dilate);
    area_num=setdiff(unique(dilate_labels),0);
    
    % 创建局部变量来存储每次循环的结果，避免并行冲突
    local_adjcant_relationship = zeros(length(gray_value));
    local_adjcant_relationprop = cell(length(gray_value));
    local_contain_relationship = zeros(length(gray_value));
    local_containwith_relationship = zeros(length(gray_value));
    
    for k4=1:length(area_num)
        area_label = dilate_labels==area_num(k4);
        stats_dilate_boundries = bwboundaries(area_label,'noholes');%获取不包含孔洞信息的区域边界坐标
        area_boundries=stats_dilate_boundries{1,1};% 边界坐标
        % sub2ind函数将下标转换为线性索引
        linear_indices = sub2ind(size(label), area_boundries(:, 1), area_boundries(:, 2));
        % 根据线性索引获取像素值
        pixelsvaluecol_label=label(linear_indices);
        geolation_withclass=setdiff(unique(pixelsvaluecol_label),[0 current_class_indices]);
        
        if ~isempty(geolation_withclass)
            if length(geolation_withclass) > 1
                local_adjcant_relationship(current_class_indices, unique(geolation_withclass)) = local_adjcant_relationship(current_class_indices, unique(geolation_withclass)) + 1;
                 % 计算比例并归一化
                Withclasspro = histcounts(pixelsvaluecol_label, [geolation_withclass', max(geolation_withclass) + 1]) / length(linear_indices);
                Withclasspro_nor = Withclasspro / sum(Withclasspro);

                % 批量更新 local_adjcant_relationprop
                local_adjcant_relationprop(current_class_indices, geolation_withclass) = ...
                    cellfun(@(existing, new) [existing, new], ...
                    local_adjcant_relationprop(current_class_indices, geolation_withclass), ...
                    num2cell(Withclasspro_nor), 'UniformOutput', false);

            elseif length(geolation_withclass) == 1
                pixelsvaluecol_boundpro=sum(pixelsvaluecol_label(:)==geolation_withclass)/length(linear_indices);
                if pixelsvaluecol_boundpro>=0.7
                    local_contain_relationship(unique(geolation_withclass),current_class_indices) = local_contain_relationship(unique(geolation_withclass),current_class_indices) + 1;
                    local_containwith_relationship(current_class_indices,unique(geolation_withclass)) = local_containwith_relationship(current_class_indices,unique(geolation_withclass)) + 1;
                else
                    local_adjcant_relationship(current_class_indices, unique(geolation_withclass)) = local_adjcant_relationship(current_class_indices, unique(geolation_withclass)) + 1;
                    local_adjcant_relationprop{current_class_indices, unique(geolation_withclass)} = ...
                        [local_adjcant_relationprop{current_class_indices, unique(geolation_withclass)},pixelsvaluecol_boundpro];
                end
            end
        end
        % 单通道
%         if length(geolation_withclass)>1
%             adjcant_relationship(current_class_indices, unique(geolation_withclass))=adjcant_relationship(current_class_indices, unique(geolation_withclass))+1;
%         else
%             contain_relationship(unique(geolation_withclass),current_class_indices)=contain_relationship(unique(geolation_withclass),current_class_indices)+1;
%             containwith_relationship(current_class_indices,unique(geolation_withclass))=containwith_relationship(current_class_indices,unique(geolation_withclass))+1;
%         end
    end
    % 并行运算：合并局部变量到全局结果中
    adjcant_relationship = adjcant_relationship + local_adjcant_relationship;
    adjcant_relationship_pro{k3} = local_adjcant_relationprop;
    contain_relationship = contain_relationship + local_contain_relationship;
    containwith_relationship = containwith_relationship + local_containwith_relationship;
end
% adjcant_relationship_pro整合信息
[rows, cols] = size(adjcant_relationship_pro{1}); % 确定 15x15 的大小
adjcant_relationshippro = cell(rows, cols); % 初始化合并后的 15x15 元胞数组
% 遍历每个位置
for i = 1:rows
    for j = 1:cols
        % 初始化数组存储
        arraysToMerge = [];
        for idx = 1:length(adjcant_relationship_pro)
            currentArray = adjcant_relationship_pro{idx}{i, j};
            arraysToMerge = [arraysToMerge; currentArray(:)]; % 按行拼接
        end
        % 将合并后的数组存储到结果中
        adjcant_relationshippro{i, j} = arraysToMerge; % 最终是一个数值数组
    end
end

AreaRelationship.adjcant_relationship=adjcant_relationship;
AreaRelationship.adjcant_relationshippro=adjcant_relationshippro;
AreaRelationship.contain_relationship=contain_relationship;
AreaRelationship.containwith_relationship=containwith_relationship;   