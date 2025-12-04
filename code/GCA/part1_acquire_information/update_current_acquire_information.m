clc;
clear;
%获取每张影像上各类地物的basic unit的信息，并获取各个类别之间的空间关系(相邻，包围，被包围)
%% configs
imagepath='D:\A_userfile\lly\data\gid5\image_rename\';
labelpath='D:\A_userfile\lly\data\gid5\label\';
datapath='D:\A_userfile\generate_image\data_information\';
labmicrDir=dir([labelpath '*.png']);
savepath='D:\A_userfile\generate_image\data_information_update\';
gray_value=1:5; %当前数据集对应类别的灰度值
ignored_value=0;
s=512; %训练数据的大小

%% initialization
All_Intrainfor=[];%存储basic unit information form all raw observed image
% Difclass_pixelsnumall记录各个原始影像对应类别的像素个数，其为包含3个字符的struct：
%  (1)Image_index:对应数据集的索引值
%  (2)Current_class:类别索引
%  (3)Pixelsnum:类别对应的像素总数
Difclass_pixelsnumall=[]; 
%获取数据集中的各个类别的邻接信息
adjcant_relationship=zeros(length(gray_value));%相邻
contain_relationship=zeros(length(gray_value));%包围
containwith_relationship=zeros(length(gray_value));%被包围
pro=0.0005; %阈值

%% 获取数据集上各类互不相交的区域信息(regionprops)以及类间信息矩阵
% 主函数(geo_relationship):获取每张影像上各类互不相交的区域信息以及类间信息
for k=1:length(labmicrDir)
    image_name_micro=labmicrDir(k).name;
    label=imread([labelpath image_name_micro]);
    image=imread([imagepath image_name_micro]);
    %获取影像的basic unit信息以及各个类别之间的位置关系信息
    [Intrainfor,Difclass_pixelsnum,AreaRelationship]=...
        geo_relationship(gray_value,image,label,ignored_value,pro,k);
    %将每张原始数据获取到的信息Subregion_intrainfor，Subregion_interinfor合并到Allsubregion_intrainfor，Allsubregion_interinfor
     All_Intrainfor=[All_Intrainfor Intrainfor];
     Difclass_pixelsnumall=[Difclass_pixelsnumall Difclass_pixelsnum];
     adjcant_relationship=adjcant_relationship+AreaRelationship.adjcant_relationship;
     contain_relationship=contain_relationship+AreaRelationship.contain_relationship;
     containwith_relationship=containwith_relationship+AreaRelationship.containwith_relationship; 
end

%% extracting_information函数信息整理：将按照数据集索引值排序的结构体信息整理为按照数据集类别信息排序的结构体
[basicunit_infor,Rawimage_pixelsnum]=extracting_information(All_Intrainfor,Difclass_pixelsnumall,gray_value);
% output:
%  basicunit_infor(包含10个字段，大小为1*length(gray_value)的结构体，其行为类别值)：记录每个类别的所有区域信息
%  Rawimage_pixelsnum(包含两个字段raw_imageid和pixels_num,大小为1*length(gray_value)的结构体，其行为类别值)：记录每个类别对应的像素总数
upbasicunit_infor=basicunit_infor;
% 移除指定字段
upbasicunit_infor = rmfield(upbasicunit_infor, 'allcurclass_centroid');
upbasicunit_infor = rmfield(upbasicunit_infor, 'allcurclass_SameclassDis');
upbasicunit_infor = rmfield(upbasicunit_infor, 'allcurclass_Boundaryjud');
upbasicunit_infor = rmfield(upbasicunit_infor, 'allcurclass_mindis');
upbasicunit_infor = rmfield(upbasicunit_infor, 'allcurclass_minbox');

%% upbasicunit_infor：记录每个类别对应的basic unit集合 
% 作用：将basicunit_infor中区域大小超出s*s大小的进行二次处理，保证所有的basic unit在s*s内
%       并将获取到的新的basic unit信息整合到upbasicunit_infor结构体中
minbox_diffclass=cell(length(gray_value),1);
for k1=1:length(gray_value)
    % Step 1: Get minimum size information for the basic unit of the current class
    allboundbox = basicunit_infor(k1).allcurclass_BoundingBox;
    % 添加一个约束条件，为保证basic unit的有效性以及效率最小尺寸不得小于2^5
    allboundbox_limit = find(allboundbox(:,3)>=2^5 & allboundbox(:,4)>=2^5);
    allboundboxlimit = allboundbox(allboundbox_limit,3:4);
    allboundboxlimit_s = allboundboxlimit(:,1).*allboundboxlimit(:,2);
    basic_windows=allboundboxlimit(allboundboxlimit_s==min(allboundboxlimit_s),:);
    minbox_diffclass{k1,1}=basic_windows; %记录到结构体minbox_diffclass 
    
    % Step 2: Get all basic unit sizes that exceed s*s
    original_allid=basicunit_infor(k1).alloriginal_id; %获取basic unit对应原始数据的索引集合
    original_allsparity=basicunit_infor(k1).allcurclass_sparity; %获取basic unit对应的稀疏度信息
    allbasic_boxinfor=[basicunit_infor(k1).allcurclass_BoundingBox]; %获取basic unit对应的box信息
    statsbasic_id = find(allbasic_boxinfor(:,3)>s | allbasic_boxinfor(:,4)>s); % 筛选basic unit集合中尺寸超出s的索引集合
    
    % Step 3: Generate optimized size combinations
    row_allpos=unique([(1:fix(s/ basic_windows(1))).*basic_windows(1) s]); % m_p所有大小
    col_allpos=unique([(1:fix(s/ basic_windows(2))).*basic_windows(2) s]); % n_p的所有大小
    combinations = combvec(row_allpos, col_allpos)';  % Generate all combinations
    products = prod(combinations, 2);% Calculate the product of each combination
    differences = abs(combinations(:, 1) - combinations(:, 2));
    [~, sorting_index] = sortrows([products, -differences]);
    combinations_sorted = combinations(sorting_index, :);% Apply the sorting index to combinations and products
    
    % Initialize variables to store the updated basic unit information
    updata_basicoriginalid=[];
    updata_basicarea=[];
    updata_basicboundingbox=zeros(0, 4);% Preallocate with correct column size
    updata_basicsparity=[];
    updata_basiccountshistogram=zeros(0, 256);
    
    % Inner loop for statsbasic_id elements
    for k2=1:length(statsbasic_id)
        tic;
        originalid = original_allid(statsbasic_id(k2)); %获取当前basic unit对应原始数据的索引值
        inibasic_box = ceil(allbasic_boxinfor(statsbasic_id(k2),:)-[0 0 1 1]);
        curimage=imread([imagepath labmicrDir(originalid).name]);
        curlabel = imread([labelpath labmicrDir(originalid).name]);
        curbasicimage = imcrop(curimage,inibasic_box);
        curbasiclabel = imcrop(curlabel,inibasic_box);
        curbasiclabel(curbasiclabel~=k1)=0;
        curbasiclabel_copy=curbasiclabel;
        [row_p,col_p]=size(curbasiclabel);
        inibasic_sparity = sum((curbasiclabel(:)==k1))/(row_p*col_p); %获取当前basic unit的稀疏度
        
        % Filter combinations based on current dimensions
        filtered_combinations=combinations_sorted;
        if row_p <= s && col_p > s
           stats_comsort=find(combinations_sorted(:,1)<=row_p);
           filtered_combinations=combinations_sorted(stats_comsort,:);
        end
        if col_p <= s && row_p > s
           stats_comsort=find(combinations_sorted(:,2)<=col_p);
           filtered_combinations=combinations_sorted(stats_comsort,:);
        end
        
        % Evaluate each combination
        for k3=1:size(filtered_combinations,1)
            k_com1=size(filtered_combinations,1)+1-k3;%倒叙
            basic_row=filtered_combinations(k_com1,1);%粒度的大小为(basic_row,basic_column）
            basic_column=filtered_combinations(k_com1,2);
            n1=basic_row-1;
            n2=basic_column-1;                        
            h_row=round(basic_row/8*7);%遍历时的行步长
            h_column=round(basic_column/8*7);%遍历时的列步长
            temp_k=k1*ones(basic_row,basic_column);
            h_rowallpos=unique([1:h_row:row_p-n1 max(row_p-s+1,1)]);
            h_colallpos=unique([1:h_column:col_p-n2 max(col_p-s+1,1)]);
            
            % Nested loops for position
            for i_row=1:length(h_rowallpos)
                for j_col=1:length(h_colallpos)
                    i=h_rowallpos(i_row);
                    j=h_colallpos(j_col);
                    diff=abs(double(curbasiclabel(i:i+n1,j:j+n2))-temp_k);
                    
                    % Check if this region satisfies sparsity criteria
                    if sum(diff(:)==0)>=basic_row*basic_column * inibasic_sparity
                        points_tooriginal=inibasic_box(1:2)+[j-1 i-1];
                        curbasic_boundingbox=[points_tooriginal n2+1 n1+1];
                        curbasic_sparity=sum(diff(:)==0)/(basic_row*basic_column);
                        curbasic_orignalid=originalid;
                        curbasic_area=sum(diff(:)==0);
                        %计算分布
                        currenregion_image=imcrop(curbasicimage,[j i n2+1 n1+1]);
                        currenregion_label=imcrop(curbasiclabel_copy,[j i n2+1 n1+1]);
                        currenregion_label_logits=currenregion_label==k1;
                        current_onlyoneclassimage=currenregion_image(currenregion_label_logits);
                        [countshistogram,~] = histcounts(current_onlyoneclassimage, 256);
                        curbasiclabel(i:i+n1/8*7,j:j+n2/8*7)=0;
                    end
                end
            end
        end %结束该粒度大小的遍历
        toc
    end
    
    %% Consolidate updated info back to upbasicunit_infor
    upid=upbasicunit_infor(k1).alloriginal_id;
    uparea=upbasicunit_infor(k1).allcurclass_area;
    upBoundingBox=upbasicunit_infor(k1).allcurclass_BoundingBox;
    upsparity=upbasicunit_infor(k1).allcurclass_sparity;
    upcountshistogram=upbasicunit_infor(k1).allcurclass_countshistogram;
    
    % Remove outdated information
    upid(statsbasic_id)=[];
    uparea(statsbasic_id)=[];
    upBoundingBox(statsbasic_id,:)=[];
    upsparity(statsbasic_id)=[];
    upcountshistogram(statsbasic_id)=[];
    
    % Append optimized information
    upbasicunit_infor(k1).alloriginal_id=[upid updata_basicoriginalid];
    upbasicunit_infor(k1).allcurclass_area=[uparea updata_basicarea];
    upbasicunit_infor(k1).allcurclass_BoundingBox=[upBoundingBox;updata_basicboundingbox];
    upbasicunit_infor(k1).allcurclass_sparity=[upsparity updata_basicsparity];
    upbasicunit_infor(k1).allcurclass_countshistogram=[upcountshistogram updata_basiccountshistogram];
end

%% Obtain the set of possible category combinations within an s×s region of the original training dataset 
  
Relationship.adjcant_relationship=adjcant_relationship;
Relationship.contain_relationship=contain_relationship;
Relationship.containwith_relationship=containwith_relationship;

%% 信息保存
save([savepath 'simi_matrix.mat'], 'simi_matrix', '-v7.3');
save([savepath 'Difclass_pixelsnumall.mat'],'Difclass_pixelsnumall')
save([savepath 'All_Intrainfor.mat'],'All_Intrainfor')
save([savepath 'basicunit_infor.mat'],'basicunit_infor')
save([savepath 'upbasicunit_infor.mat'],'upbasicunit_infor')
save([savepath 'Rawimage_pixelsnum.mat'],'Rawimage_pixelsnum')
save([savepath 'Relationship.mat'],'Relationship')
save([savepath 'minbox_diffclass.mat'],'minbox_diffclass1')