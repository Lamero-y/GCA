function [strideH, strideW] = computeStride(imageSize, windowSize)
    % 影像大小
    H = imageSize(1);
    W = imageSize(2);

    % 窗口大小
    h = windowSize(1);
    w = windowSize(2);

    % 差值
    deltaH = H - h;
    deltaW = W - w;

    % 获取差值的所有因数
    strideH_candidates = divisors(deltaH);
    strideW_candidates = divisors(deltaW);
    
    % 获取非负整数下最接近ceil(H/h),ceil(W/w)的值
    strideH_candidates_nidx=find(strideH_candidates-ceil(H/h)>0);
    strideW_candidates_nidx=find(strideW_candidates-ceil(W/h)>0);
    [~,strideH_idx] = min(strideH_candidates(strideH_candidates_nidx));  % 最大步长
    [~,strideW_idx] = min(strideW_candidates(strideW_candidates_nidx));  % 最大步长
    strideH = deltaH/strideH_candidates(strideH_candidates_nidx(strideH_idx));
    strideW = deltaW/strideW_candidates(strideW_candidates_nidx(strideW_idx)); 
    if strideH_candidates(strideH_candidates_nidx(strideH_idx))>ceil(H/h)*2 
       strideH=deltaH/ceil(H/h);
    end
    if strideW_candidates(strideW_candidates_nidx(strideW_idx))>ceil(W/h)*2 
       strideW=deltaW/ceil(W/h);
    end 
end

function factors = divisors(n)
    % 计算整数 n 的所有因数
     factors = find(mod(n, 1:n) == 0);
end

