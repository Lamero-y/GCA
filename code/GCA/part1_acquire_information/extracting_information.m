function  [basicunit_infor,Rawimage_pixelsnum]=extracting_information(All_Intrainfor,Difclass_pixelsnum,gray_value)
% All_Intrainfor的整合：整合各个类别的basic unit的信息，并获取对应类别basic unit的稀疏度信息

% Preallocate struct array
basicunit_infor(length(gray_value)).class = [];
basicunit_infor(length(gray_value)).alloriginal_id = [];
basicunit_infor(length(gray_value)).allcurclass_area=[];
basicunit_infor(length(gray_value)).allcurclass_centroid=[];
basicunit_infor(length(gray_value)).allcurclass_BoundingBox=[];
basicunit_infor(length(gray_value)).allcurclass_sparity=[];
basicunit_infor(length(gray_value)).allcurclass_SameclassDis=[];
basicunit_infor(length(gray_value)).allcurclass_Boundaryjud=[];
basicunit_infor(length(gray_value)).allcurclass_countshistogram=[];
basicunit_infor(length(gray_value)).allcurclass_mindis=[];
basicunit_infor(length(gray_value)).allcurclass_minbox=[];
Rawimage_pixelsnum(length(gray_value)).raw_imageid=[]; 
Rawimage_pixelsnum(length(gray_value)).pixels_num=[];  
for k1=1:length(gray_value)
    current_class=gray_value(k1); 
    % 1.Extract information of the current class's basic unit
    allcurclass_id= find([All_Intrainfor.Current_class]==current_class); %获取当前类别在All_Intrainfor上的索引
    alloriginal_id=[All_Intrainfor(allcurclass_id).Image_index]; %表示basic unit对应raw observed image的索引值集合
    allcurclass_area=[All_Intrainfor(allcurclass_id).Area];%表示basic unit对应的area值
    allcurclass_centroid=[All_Intrainfor(allcurclass_id).Centroid];%表示basic unit对应的中心点
    allcurclass_centroid=reshape(allcurclass_centroid,2,[])';
    allcurclass_BoundingBox=[All_Intrainfor(allcurclass_id).BoundingBox];%表示basic unit对应的boundingbox
    allcurclass_BoundingBox=reshape(allcurclass_BoundingBox,4,[])';
    allcurclass_sparity=[All_Intrainfor(allcurclass_id).Sparity];%表示basic unit对应的Sparity
    allcurclass_SameclassDis=[All_Intrainfor(allcurclass_id).Sameclass_Disvalue]; %表示同类basic unit的最短距离
    allcurclass_Boundaryjud=[All_Intrainfor(allcurclass_id).Boundary_judgment]; %表示basic unit是都位于影像四边边界
    allcurclass_countshistogram=[All_Intrainfor(allcurclass_id).counts_histogram];%表示basic unit对应的中心点
    allcurclass_countshistogram=reshape(allcurclass_countshistogram,256,[])';

    sameclass_mindis=min(setdiff(allcurclass_SameclassDis,0));
    % 获取位于非四边的最小basic unit area信息
    sameclass_Boundaryjud_id = find(allcurclass_Boundaryjud==2);
    sameclass_areacol=allcurclass_area(sameclass_Boundaryjud_id);   
    [~,sameclass_minarea_id] = min(sameclass_areacol);
    sameclass_minarea_id_toallarea=sameclass_Boundaryjud_id(sameclass_minarea_id);
    minarea_boxinfor=[allcurclass_BoundingBox(sameclass_minarea_id_toallarea,3) allcurclass_BoundingBox(sameclass_minarea_id_toallarea,4)];
    
    basicunit_infor(k1).class = current_class;
    basicunit_infor(k1).alloriginal_id = alloriginal_id;
    basicunit_infor(k1).allcurclass_area=allcurclass_area;
    basicunit_infor(k1).allcurclass_centroid=allcurclass_centroid;
    basicunit_infor(k1).allcurclass_BoundingBox=allcurclass_BoundingBox;
    basicunit_infor(k1).allcurclass_sparity=allcurclass_sparity;
    basicunit_infor(k1).allcurclass_SameclassDis=allcurclass_SameclassDis;
    basicunit_infor(k1).allcurclass_Boundaryjud=allcurclass_Boundaryjud;
    basicunit_infor(k1).allcurclass_countshistogram=allcurclass_countshistogram;
    basicunit_infor(k1).allcurclass_mindis=sameclass_mindis;
    basicunit_infor(k1).allcurclass_minbox=minarea_boxinfor;
    
    %Difclass_pixelsnum=struct('Image_index',[],'Current_class',[],'Pixelsnum',[]);
    % 2.Difclass_pixelsnum
    difclasspixels_id= find([Difclass_pixelsnum.Current_class]==current_class); %获取当前类别在All_Intrainfor上的索引
    raw_imageid=[Difclass_pixelsnum(difclasspixels_id).Image_index]; %表示basic unit对应raw observed image的索引值集合
    rawimage_difclassnum=[Difclass_pixelsnum(difclasspixels_id).Pixelsnum];%表示basic unit对应的area值
    Rawimage_pixelsnum(k1).raw_imageid=raw_imageid; 
    Rawimage_pixelsnum(k1).pixels_num=rawimage_difclassnum; 
end