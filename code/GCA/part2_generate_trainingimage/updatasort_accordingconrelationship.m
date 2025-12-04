function  State=updatasort_accordingconrelationship(choose_classcol_initial,chooseempairs,Relationship,basicunit_infor)
% Input：
%     choose_classcol_initial：当前选取的类别集合
%     chooseempairs:误分类别对
%     Relationship：所有类别的关系信息
%     basicunit_infor：所有对象的信息
%Output:
%     State包含三个字段:
%       (1)字段classcol:表示根据包含关系重新排序后的类别集合
%       (2)字段em_toclass：表示与choose_class易误分的类别值
%       (3)字段choose_class：表示选取的易误分类别对之一
%% 获取根据包含关系重新排序的类别集合
% 获取当前类别集合对应的包含关系集合
contain_relationship=Relationship.contain_relationship;
curclass_conrelation=contain_relationship(choose_classcol_initial,choose_classcol_initial);
% 获取当前类别的对象总数
objectnum_toclasscol=cell2mat(cellfun(@(x) length(x),{basicunit_infor(choose_classcol_initial).alloriginal_id},...
    'UniformOutput', false));
% 包含占比
containpro_toclasscol=sum(curclass_conrelation,2)./objectnum_toclasscol';
[~,containidx]=sort(containpro_toclasscol,'descend');
choose_classcol=choose_classcol_initial(containidx);

% 2: 重新定义choose_class、em_toclass的值(因为不考虑先后顺序)
choose_class=chooseempairs(2);
em_toclass=chooseempairs(1);
if find(choose_classcol == em_toclass)< find(choose_classcol == choose_class)
    em_toclass=chooseempairs(2);
    choose_class=chooseempairs(1);
end
State.classcol=choose_classcol;
State.em_toclass=em_toclass;
State.choose_class=choose_class;



    









