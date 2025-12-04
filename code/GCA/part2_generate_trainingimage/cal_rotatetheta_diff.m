function diff_theta=cal_rotatetheta_diff(willcontain_basiclabel,willbasic_label)
 % 1.1确定填充区域的角度
willcontain_basiclabellogits=willcontain_basiclabel~=0;
[m,n]=size(willcontain_basiclabellogits);
%rotate image
edges = edge(willcontain_basiclabellogits, 'Canny');
if ~isempty(find(edges)) && sum(edges(:))>m*n*0.1
    [y, x] = find(edges);
    points = [x, y]; 
    coeff = pca(points);
    theta_containbasic = atan2d(coeff(2, 1), coeff(1, 1));
else
    theta_containbasic = 0;
end
% 1.2确定basic unit的角度
willbasic_labellogits=willbasic_label~=0;
edges_wbasic = edge(willbasic_labellogits, 'Canny');
if ~isempty(find(edges_wbasic)) && sum(edges(:))>m*n*0.1
    [y_wbasic, x_wbasic] = find(edges_wbasic);
    points_wbasic = [x_wbasic, y_wbasic]; 
    coeff_wbasic = pca(points_wbasic);
    if isempty(coeff_wbasic)
        diff_theta=0-theta_containbasic;
        return;
    end
    theta_wbasic= atan2d(coeff_wbasic(2, 1), coeff_wbasic(1, 1));
    diff_theta=theta_wbasic-theta_containbasic;
else
    diff_theta=0-theta_containbasic;
end
