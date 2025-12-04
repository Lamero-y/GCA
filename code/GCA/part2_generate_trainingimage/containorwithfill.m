function Curbasic_unit=containorwithfill(Curbasic_unit,k)
%根据邻域关系进行包围关系的判断，并更新basic unit集合
%% step1: 将指定的包围basic信息填充到指定的basic unit中
specicon_idx=find([Curbasic_unit{:,10}]~=0);
specontainbasic_classnum=unique(unique([Curbasic_unit{specicon_idx,10}]));
delete_idx=[];
for k1=1:numel(specontainbasic_classnum)
    % 包围的basic unit的信息
    contain_classidx_incur=specontainbasic_classnum(k1);
    Curbasic_unit_deletespeci=Curbasic_unit(contain_classidx_incur,:);
    contain_basicimage=Curbasic_unit{contain_classidx_incur,2};
    contain_basiclabel=Curbasic_unit{contain_classidx_incur,1};
    contain_basiclabellogits=contain_basiclabel~=0;
    willfill_areaboxboundings=[Curbasic_unit{contain_classidx_incur,11}];
    % 填充的basic unit的信息
    statscuridx_basicunitidx=[Curbasic_unit{specicon_idx,10}]==contain_classidx_incur;
    willfill_basicidxincur=specicon_idx(statscuridx_basicunitidx);
    speciall_basicunitarea=[Curbasic_unit{willfill_basicidxincur,5}];
    % 对比在包围basic unit上的填充basic unit最恰当填充点
    [~,suitfillidx]=min(abs(willfill_areaboxboundings(:,3).*willfill_areaboxboundings(:,4)-speciall_basicunitarea));
    for k_fill=1:length(suitfillidx)
        suitidx_incur=suitfillidx(k_fill);
        willfill_boxboundings_cur= willfill_areaboxboundings(suitidx_incur,:);
        willbasic_image=Curbasic_unit{willfill_basicidxincur(k_fill),2};
        willbasic_label=Curbasic_unit{willfill_basicidxincur(k_fill),1};
        willcontain_basiclabellogits=imcrop(contain_basiclabellogits,willfill_boxboundings_cur);
        if sum(willcontain_basiclabellogits(:)~=0)==0
            diff_theta=0;
        else
            diff_theta=cal_rotatetheta_diff(willcontain_basiclabellogits,willbasic_label);
        end
        willbasic_label_r=imrotate(willbasic_label,diff_theta);
        willbasic_image_r=imrotate(willbasic_image,diff_theta);
        willbasic_image_r(all(willbasic_label_r==0,2),:,:)=[];
        willbasic_image_r(:,all(willbasic_label_r==0,1),:)=[];
        willbasic_label_r(all(willbasic_label_r==0,2),:)=[];
        willbasic_label_r(:,all(willbasic_label_r==0,1))=[];
        [willf_row,willf_col]=size(willbasic_label_r);
        % 2.填充
        if size(contain_basicimage,1)<willf_row || size(contain_basicimage,2)<willf_col ||...
           willfill_boxboundings_cur(2)+willf_row-1>size(contain_basicimage,1) ||...
           willfill_boxboundings_cur(1)+willf_col-1>size(contain_basicimage,2)
            new_row=ceil(max(max(size(contain_basicimage,1),willfill_boxboundings_cur(2)+willf_row-1),willf_row));
            new_col=ceil(max(max(size(contain_basicimage,2),willfill_boxboundings_cur(1)+willf_col-1),willf_col));
            new_image=zeros(new_row,new_col,3);
            new_label=zeros(new_row,new_col);
            new_image(1:1+size(contain_basicimage,1)-1,1:1+size(contain_basicimage,2)-1,:)=contain_basicimage;
            new_label(1:1+size(contain_basicimage,1)-1,1:1+size(contain_basicimage,2)-1)=contain_basiclabel;
            contain_basicimage=new_image;
            contain_basiclabel=new_label;
        end
        middle_image=zeros([size(contain_basiclabel),3]);
        middle_label=zeros(size(contain_basiclabel));
        middle_image(willfill_boxboundings_cur(2):willfill_boxboundings_cur(2)+willf_row-1,...
            willfill_boxboundings_cur(1):willfill_boxboundings_cur(1)+willf_col-1,:)=willbasic_image_r;
        middle_label(willfill_boxboundings_cur(2):willfill_boxboundings_cur(2)+willf_row-1,...
            willfill_boxboundings_cur(1):willfill_boxboundings_cur(1)+willf_col-1,:)=willbasic_label_r;
        middle_image1= middle_image(:,:,1); middle_image2= middle_image(:,:,2);
        middle_image3= middle_image(:,:,3);
        contain_basicimage1=contain_basicimage(:,:,1);contain_basicimage2=contain_basicimage(:,:,2);
        contain_basicimage3=contain_basicimage(:,:,3);
        contain_basicimage1(middle_label~=0)=middle_image1(middle_label~=0);
        contain_basicimage2(middle_label~=0)=middle_image2(middle_label~=0);
        contain_basicimage3(middle_label~=0)=middle_image3(middle_label~=0);
        contain_basicimage(:,:,1)=contain_basicimage1;
        contain_basicimage(:,:,2)=contain_basicimage2;
        contain_basicimage(:,:,3)=contain_basicimage3;
        contain_basiclabel(middle_label~=0)=middle_label(middle_label~=0);
    end
    delete_idx=[delete_idx,willfill_basicidxincur];
    willfill_areaboxboundings(unique(suitfillidx),:)=[];
    Curbasic_unit_deletespeci{1,2}=contain_basicimage;
    Curbasic_unit_deletespeci{1,1}=contain_basiclabel;
    Curbasic_unit_deletespeci{1,4}=sum(contain_basiclabel(:)~=0)/(size(contain_basiclabel,1)*size(contain_basiclabel,2));
    Curbasic_unit_deletespeci{1,5}=sum(contain_basiclabel(:)~=0);
    Curbasic_unit_deletespeci{1,11}=willfill_areaboxboundings;
    Curbasic_unit(contain_classidx_incur,:)=Curbasic_unit_deletespeci;
end
Curbasic_unit(delete_idx,:)=[];
         
%% step2：根据包含关系随机判断当前是否存在包含关系
relation_withclassnumidlogits =cellfun(@numel,Curbasic_unit(:,7))==3;%剔除与多个类别存在关系的类别信息
relation_withclassnumid=find(relation_withclassnumidlogits==1);
Curbasic_unit_deletespecifical=Curbasic_unit(relation_withclassnumid,:);
relationship_allset=[Curbasic_unit_deletespecifical{:,7}];
non_zero_counts =sum(relationship_allset~=0); % 获取非零值的个数,>2存在包围关系 
contains_relation=non_zero_counts>=2;
contains_relation_allset=relationship_allset(:,contains_relation);
contains_relation_allset_id=find(contains_relation==1);
Containwith_minid=[]; contain_maxid=[];
% 若类别中存在包含关系，则根据包含关系进行拼接，后在根据相邻关系进行填充
% 随机数生成确定包含关系
[contains_relation_allset,~,contain_allid]=unique(contains_relation_allset','rows');
for k2=1:size(contains_relation_allset,1)
    curcontain=cumsum(contains_relation_allset(k2,:)./sum(contains_relation_allset(k2,:)));
    curcontain_idx=find(contain_allid==k2);
    rng(1658 + k, 'twister');
    contain_rand=rand();
    if contain_rand>curcontain(1) && contain_rand<=curcontain(2) %存在包围关系
        %keyboard
        contain_classidx_incur=unique([Curbasic_unit_deletespecifical{contains_relation_allset_id(curcontain_idx)',3}]);%获取包围类别信息
        contain_area=[Curbasic_unit_deletespecifical{contains_relation_allset_id(curcontain_idx)',5}];
        if length(contain_classidx_incur)>1
            maxarea_id=contain_area==max(contain_area);
            contain_class_c=[Curbasic_unit_deletespecifical{contains_relation_allset_id(curcontain_idx(maxarea_id))',3}];
            containwith_class=setdiff(contain_classidx_incur,contain_class_c);
            contain_classidx_incur=contain_class_c;
        else
            containwith_class=unique([Curbasic_unit_deletespecifical{contains_relation_allset_id(curcontain_idx)',6}]);
        end
        containwith_id=find([Curbasic_unit_deletespecifical{:,3}]==containwith_class);
        containwith_area=[Curbasic_unit_deletespecifical{containwith_id,5}];
        if max(contain_area)>min(containwith_area)*2 %将其最小区域填充到其最大区域中
            % 获取对应包围关系的area最大的basic unit信息
            contain_maxid=contains_relation_allset_id(curcontain_idx(max(contain_area)== contain_area));
            contain_maxid=contain_maxid(1);
            contain_basicimage=Curbasic_unit_deletespecifical{contain_maxid,2};
            contain_basiclabel=Curbasic_unit_deletespecifical{contain_maxid,1};
            [m1,n1]=size(contain_basiclabel);
            % 获取对应被包围关系的area最大的basic unit信息
            containwith_minid=containwith_id(min(containwith_area)==containwith_area);
            containwith_minid=containwith_minid(1);
            containwith_basicimage=Curbasic_unit_deletespecifical{containwith_minid,2};
            containwith_basiclabel=Curbasic_unit_deletespecifical{containwith_minid,1};
            [m2,n2]=size(containwith_basiclabel);
            % 合并
            if m1>m2 && n1>n2
                contain_basiclabel_logits=contain_basiclabel==0;
                stats_c=regionprops(contain_basiclabel_logits);
                bbox_values = reshape([stats_c.BoundingBox], 4, [])';
                if ~isempty(stats_c)
                    area_stats=[stats_c.Area];
                    [~,areasuitable_id]=min(abs(area_stats-repmat(sum(containwith_basiclabel(:)~=0),1,length(area_stats))));
                    points_suit=stats_c(areasuitable_id).BoundingBox;
                    if points_suit(2)+m2-1>m1
                        points_suit(2)=m1-m2+1;
                    end
                    if points_suit(1)+n2-1>n1
                        points_suit(1)=n1-n2+1;
                    end
                    %合并填充
                    middle_containlabel=zeros(m1,n1); 
                    middle_containimage=zeros(m1,n1,3); 
                    middle_containlabel(points_suit(2):points_suit(2)+m2-1,points_suit(1):points_suit(1)+n2-1)=containwith_basiclabel;
                    middle_containimage(points_suit(2):points_suit(2)+m2-1,points_suit(1):points_suit(1)+n2-1,:)=containwith_basicimage;
                    contain_basicimage_1= contain_basicimage(:,:,1); contain_basicimage_2= contain_basicimage(:,:,2);
                    contain_basicimage_3= contain_basicimage(:,:,3);
                    middle_containimage_1=middle_containimage(:,:,1); middle_containimage_2=middle_containimage(:,:,2);
                    middle_containimage_3=middle_containimage(:,:,3);
                    contain_basicimage_1(middle_containlabel~=0)=middle_containimage_1(middle_containlabel~=0);
                    contain_basicimage_2(middle_containlabel~=0)=middle_containimage_2(middle_containlabel~=0);
                    contain_basicimage_3(middle_containlabel~=0)=middle_containimage_3(middle_containlabel~=0);
                    contain_basicimage(:,:,1)=contain_basicimage_1;
                    contain_basicimage(:,:,2)=contain_basicimage_2;
                    contain_basicimage(:,:,3)=contain_basicimage_3;
                    contain_basiclabel(middle_containlabel~=0)=middle_containlabel(middle_containlabel~=0);
                    Curbasic_unit_deletespecifical{contain_maxid,1}=contain_basiclabel;
                    Curbasic_unit_deletespecifical{contain_maxid,2}=contain_basicimage;
                    Curbasic_unit_deletespecifical{contain_maxid,4}=sum(contain_basiclabel(:)~=0)/(size(contain_basiclabel,1)*size(contain_basiclabel,2));
                    Curbasic_unit_deletespecifical{contain_maxid,5}=sum(contain_basiclabel(:)~=0);
                    Containwith_minid=[Containwith_minid containwith_minid];
                else
                    rng(2003 + k, 'twister');
                    points_suit_m=randi(m1-m2+1,1);
                    rng(1892 + k, 'twister');
                    points_suit_n=randi(n1-n2+1,1);
                    middle_containlabel=zeros(m1,n1); 
                    middle_containimage=zeros(m1,n1,3); 
                    middle_containlabel(points_suit_m:points_suit_m+m2-1,points_suit_n:points_suit_n+n2-1)=containwith_basiclabel;
                    middle_containimage(points_suit_m:points_suit_m+m2-1,points_suit_n:points_suit_n+n2-1,:)=containwith_basicimage;
                    contain_basicimage_1= contain_basicimage(:,:,1); contain_basicimage_2= contain_basicimage(:,:,2);
                    contain_basicimage_3= contain_basicimage(:,:,3);
                    middle_containimage_1=middle_containimage(:,:,1); middle_containimage_2=middle_containimage(:,:,2);
                    middle_containimage_3=middle_containimage(:,:,3);
                    contain_basicimage_1(middle_containlabel~=0)=middle_containimage_1(middle_containlabel~=0);
                    contain_basicimage_2(middle_containlabel~=0)=middle_containimage_2(middle_containlabel~=0);
                    contain_basicimage_3(middle_containlabel~=0)=middle_containimage_3(middle_containlabel~=0);
                    contain_basicimage(:,:,1)=contain_basicimage_1;
                    contain_basicimage(:,:,2)=contain_basicimage_2;
                    contain_basicimage(:,:,3)=contain_basicimage_3;
                    contain_basiclabel(middle_containlabel~=0)=middle_containlabel(middle_containlabel~=0);
                    Curbasic_unit_deletespecifical{contain_maxid,1}=contain_basiclabel;
                    Curbasic_unit_deletespecifical{contain_maxid,2}=contain_basicimage;
                    Curbasic_unit_deletespecifical{contain_maxid,4}=sum(contain_basiclabel(:)~=0)/(size(contain_basiclabel,1)*size(contain_basiclabel,2));
                    Curbasic_unit_deletespecifical{contain_maxid,5}=sum(contain_basiclabel(:)~=0);
                    Containwith_minid=[Containwith_minid containwith_minid];
                end
            end
        end
    elseif contain_rand>curcontain(2) && contain_rand<=curcontain(3) %存在被包围关系
        containwith_class=unique([Curbasic_unit_deletespecifical{contains_relation_allset_id(curcontain_idx)',3}]);%获取被包围类别信息
        containwith_area=[Curbasic_unit_deletespecifical{contains_relation_allset_id(curcontain_idx)',5}];
        if length(containwith_class)>1
            minarea_id=containwith_area==min(containwith_area);
            containwith_class_c=[Curbasic_unit_deletespecifical{contains_relation_allset_id(curcontain_idx(minarea_id))',3}];
            contain_classidx_incur=setdiff(containwith_class,containwith_class_c);
            containwith_class=containwith_class_c;
        else
            contain_classidx_incur=unique([Curbasic_unit_deletespecifical{contains_relation_allset_id(curcontain_idx)',6}]);
        end
        contain_id=find([Curbasic_unit_deletespecifical{:,3}]==contain_classidx_incur);
        contain_area=[Curbasic_unit_deletespecifical{contain_id,5}];
        if max(contain_area)>min(containwith_area)*2 %将其最小区域填充到其最大区域中
            % 获取对应包围关系的area最大的basic unit信息
            contain_maxid=contain_id(max(contain_area)== contain_area);
            contain_maxid=contain_maxid(1);
            contain_basicimage=Curbasic_unit_deletespecifical{contain_maxid,2};
            contain_basiclabel=Curbasic_unit_deletespecifical{contain_maxid,1};
            [m1,n1]=size(contain_basiclabel);
            % 获取对应被包围关系的area最大的basic unit信息
            containwith_minid=contains_relation_allset_id(curcontain_idx(min(containwith_area)==containwith_area));
            containwith_minid=containwith_minid(1);
            containwith_basicimage=Curbasic_unit_deletespecifical{containwith_minid,2};
            containwith_basiclabel=Curbasic_unit_deletespecifical{containwith_minid,1};
            [m2,n2]=size(containwith_basiclabel);
            if m1>m2 && n1>n2
                % 合并
                contain_basiclabel_logits=contain_basiclabel==0;
                stats_c=regionprops(contain_basiclabel_logits);
                bbox_values = reshape([stats_c.BoundingBox], 4, [])';
                if ~isempty(stats_c)
                    area_stats=[stats_c.Area];
                    [~,areasuitable_id]=min(abs(area_stats-repmat(sum(containwith_basiclabel(:)~=0),1,length(area_stats))));
                    points_suit=stats_c(areasuitable_id).BoundingBox;
                    %合并填充
                    middle_containlabel=zeros(m1,n1); 
                    middle_containimage=zeros(m1,n1,3); 
                    if points_suit(2)+m2-1>m1
                        points_suit(2)=m1-m2+1;
                    end
                    if points_suit(1)+n2-1>n1
                        points_suit(1)=n1-n2+1;
                    end
                    middle_containlabel(points_suit(2):points_suit(2)+m2-1,points_suit(1):points_suit(1)+n2-1)=containwith_basiclabel;
                    middle_containimage(points_suit(2):points_suit(2)+m2-1,points_suit(1):points_suit(1)+n2-1,:)=containwith_basicimage;
                    contain_basicimage_1= contain_basicimage(:,:,1); contain_basicimage_2= contain_basicimage(:,:,2);
                    contain_basicimage_3= contain_basicimage(:,:,3);
                    middle_containimage_1=middle_containimage(:,:,1); middle_containimage_2=middle_containimage(:,:,2);
                    middle_containimage_3=middle_containimage(:,:,3);
                    contain_basicimage_1(middle_containlabel~=0)=middle_containimage_1(middle_containlabel~=0);
                    contain_basicimage_2(middle_containlabel~=0)=middle_containimage_2(middle_containlabel~=0);
                    contain_basicimage_3(middle_containlabel~=0)=middle_containimage_3(middle_containlabel~=0);
                    contain_basicimage(:,:,1)=contain_basicimage_1;
                    contain_basicimage(:,:,2)=contain_basicimage_2;
                    contain_basicimage(:,:,3)=contain_basicimage_3;
                    contain_basiclabel(middle_containlabel~=0)=middle_containlabel(middle_containlabel~=0);
                    Curbasic_unit_deletespecifical{contain_maxid,1}=contain_basiclabel;
                    Curbasic_unit_deletespecifical{contain_maxid,2}=contain_basicimage;
                    Curbasic_unit_deletespecifical{contain_maxid,4}=sum(contain_basiclabel(:)~=0)/(size(contain_basiclabel,1)*size(contain_basiclabel,2));
                    Containwith_minid=[Containwith_minid containwith_minid];
                else
                    rng(2003 + k, 'twister');
                    points_suit_m=randi(m1-m2+1,1);
                    rng(1892 + k, 'twister');
                    points_suit_n=randi(n1-n2+1,1);
                    %合并填充
                    middle_containlabel=zeros(m1,n1); 
                    middle_containimage=zeros(m1,n1,3); 
                    middle_containlabel(points_suit_m:points_suit_m+m2-1,points_suit_n:points_suit_n+n2-1)=containwith_basiclabel;
                    middle_containimage(points_suit_m:points_suit_m+m2-1,points_suit_n:points_suit_n+n2-1,:)=containwith_basicimage;
                    contain_basicimage_1= contain_basicimage(:,:,1); contain_basicimage_2= contain_basicimage(:,:,2);
                    contain_basicimage_3= contain_basicimage(:,:,3);
                    middle_containimage_1=middle_containimage(:,:,1); middle_containimage_2=middle_containimage(:,:,2);
                    middle_containimage_3=middle_containimage(:,:,3);
                    contain_basicimage_1(middle_containlabel~=0)=middle_containimage_1(middle_containlabel~=0);
                    contain_basicimage_2(middle_containlabel~=0)=middle_containimage_2(middle_containlabel~=0);
                    contain_basicimage_3(middle_containlabel~=0)=middle_containimage_3(middle_containlabel~=0);
                    contain_basicimage(:,:,1)=contain_basicimage_1;
                    contain_basicimage(:,:,2)=contain_basicimage_2;
                    contain_basicimage(:,:,3)=contain_basicimage_3;
                    contain_basiclabel(middle_containlabel~=0)=middle_containlabel(middle_containlabel~=0);
                    Curbasic_unit_deletespecifical{contain_maxid,1}=contain_basiclabel;
                    Curbasic_unit_deletespecifical{contain_maxid,2}=contain_basicimage;
                    Curbasic_unit_deletespecifical{contain_maxid,4}=sum(contain_basiclabel(:)~=0)/(size(contain_basiclabel,1)*size(contain_basiclabel,2));
                end
            end
        end
    end
end
% 被包含basic unit索引值
upContainwith_minid=relation_withclassnumid(Containwith_minid);
upcontain_maxid=relation_withclassnumid(contain_maxid);
Curbasic_unit(upcontain_maxid,:)=Curbasic_unit_deletespecifical(contain_maxid,:);
Curbasic_unit(upContainwith_minid,:)=[];
