function basicunit_fillsort_end=sort_basicunit(Curbasic_unit,lastclass,s)
% 函数目的：考虑了稀疏度、大小、以及包含关系的信息进行排序. 排序要求是 spar 越小越优先,size 信息也要越小越优先,且 spar 的优先级大于 size
% 同时,如果某个类别的 size 较大但不存在包含关系，则该类别不受 size 的影响;而稀疏度不是特别小的情况下，将该类别优先填充.

%1.获取各个basic unit的稀疏度，大小信息以及包含关系信息
basicunit_class=[Curbasic_unit{:,3}];
basicunit_spar=[Curbasic_unit{:,4}];
basicunit_size=[Curbasic_unit{:,5}];
%获取latclass的位置信息
lastclass_infor=find(basicunit_class==lastclass);

% 归一化处理
basicunit_spar_normalized = (basicunit_spar - min(basicunit_spar)) / (max(basicunit_spar) - min(basicunit_spar));
basicunit_size_normalized = (basicunit_size - min(basicunit_size)) / (max(basicunit_size) - min(basicunit_size));

% 定义权重因子
weight_spar = 0.6;  % spar 的权重因子
weight_size = 0.4;  % size 的权重因子
% 计算加权后的值
weighted_value = weight_spar * basicunit_spar_normalized - weight_size * basicunit_size_normalized;
%根据weighted_value排序
[~,basicunit_fillsort]=sort(weighted_value,'ascend');
if lastclass_infor~=2
    basicunit_fillsort_end=[basicunit_fillsort(~ismember(basicunit_fillsort,lastclass_infor)) lastclass_infor];
else
    basicunit_fillsort_end=basicunit_fillsort;    
end


