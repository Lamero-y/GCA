function matrix_expand=matrixexpand(matrix,p_micro)

[x,y]=size(matrix);
matrix_expand=ones(x*p_micro,y*p_micro);
for k1=1:x
    for k2=1:y
        x_cur=(k1-1)*p_micro+1;
        y_cur=(k2-1)*p_micro+1;
        matrix_expand(x_cur:x_cur+p_micro-1,y_cur:y_cur+p_micro-1)=matrix(k1,k2);
    end
end
        
