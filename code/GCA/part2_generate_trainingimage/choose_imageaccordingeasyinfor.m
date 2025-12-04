clc;
clear;
imagepath='D:\A_userfile\generate_image\image_3000\';
labelpath='D:\A_userfile\generate_image\label_3000\';
imageDir=dir([imagepath '*.png']);
saveimage='D:\A_userfile\generate_image\image_end\image\';
savelabel='D:\A_userfile\generate_image\image_end\label\';
%获取easyinfor
load([imagepath 'easyclass_infor.mat']);
easymis_ologits=cell2mat(cellfun(@(x) ~isempty(x), easyclass_infor, 'UniformOutput', false));
easymis_oidx=find(easymis_ologits~=0);
for k=1:length(imageDir)
    k1=easymis_oidx(k);
    strr=strcat('image_',num2str(k1),'.png');
    image=imread([imagepath strr]);
    label=imread([labelpath strr]);
    imwrite(uint8(image),[saveimage strr])
    imwrite(uint8(label),[savelabel strr])
end