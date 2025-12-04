function classcol_infor=update_area_number(Relationship,choose_classcol,curclass_pro_normal,choose_classcol_areanum,irr_class)
%choose last fill class information
contain_relationship=Relationship.contain_relationship;
% 
red_classcol=setdiff(choose_classcol,irr_class);
red_classidx=ismember(choose_classcol,red_classcol);
curclass_conrelation=contain_relationship(red_classcol,red_classcol);
if isempty(red_classcol)
    curclass_conrelation=contain_relationship(choose_classcol,choose_classcol);
    contain_pro=sum(curclass_conrelation,2)./sum(curclass_conrelation(:));
    curclass_pro_normal_choose=curclass_pro_normal;
    choose_pro=contain_pro*0.7+curclass_pro_normal_choose*0.3;
    choose_pro_narmal=choose_pro./sum(choose_pro);
    lastclass=choose_classcol(choose_pro_narmal==max(choose_pro_narmal));
    change_idx=find(lastclass(end)==choose_classcol);
    curclass_pro_normal(change_idx)=0.8;
    choose_classcol_areanum(change_idx)=1;
elseif length(red_classcol)==1
    change_idx=find(red_classcol==choose_classcol);
    lastclass=red_classcol;
    curclass_pro_normal(change_idx)=0.8;
    choose_classcol_areanum(change_idx)=1;
else
    if sum(curclass_conrelation(:))==0
        contain_pro=zeros(length(red_classcol),1);
    else
        contain_pro=sum(curclass_conrelation,2)./sum(curclass_conrelation(:));
    end
    if length(red_classcol)~=length(choose_classcol)
        curclass_pro_normal_choose=curclass_pro_normal(red_classidx);
    else
        curclass_pro_normal_choose=curclass_pro_normal;
    end
    choose_pro=contain_pro*0.7+curclass_pro_normal_choose*0.3;
    choose_pro_narmal=choose_pro./sum(choose_pro);
    lastclass=red_classcol(choose_pro_narmal==max(choose_pro_narmal));
    change_idx=find(lastclass(end)==choose_classcol);
    curclass_pro_normal(change_idx)=0.8;
    choose_classcol_areanum(change_idx)=1;
end
classcol_infor.lastclass=lastclass;
classcol_infor.curclass_pro_normal=curclass_pro_normal;
classcol_infor.choose_classcol_areanum=choose_classcol_areanum;
    
    
    
    

