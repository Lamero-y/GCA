function mask_label_grid=mask_grid(mask_label,p)

mask_label_grid=zeros(size(mask_label,1)/p,size(mask_label,2)/p);%定义一个10*10的矩阵
for xi=1:size(mask_label_grid,1)
    for xj=1:size(mask_label_grid,2)
        xi_0=(xi-1)*p+1; xj_0=(xj-1)*p+1;
        gray_local2=mask_label(xi_0:xi_0+p-1,xj_0:xj_0+p-1);
        gray_local2_value=unique(gray_local2);
        gray_mode=mode(gray_local2(:));
        if  sum(gray_local2(:)==gray_mode)>=p*p*0.75
            mask_label_grid(xi,xj)=gray_mode;
        elseif sum(gray_local2(:)~=0)>=p*p*0.75
            mask_label_grid(xi,xj)=gray_mode;    
        end
    end
end