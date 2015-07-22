function corrcoef = corrCoefs(im, points, kernel)
% CORRCOEFS get correlation coefficients of regions in an image
% 
% corrcoef = corrCoefs(im, rc, kernel) is the correlation 
% 	coefficients of the regions in 'im' centered at coordinates
% 	in 'particles' with 'kernel'.

n=size(points,1);
corrcoef=zeros(n,1);
t = (size(kernel,1)-1)/2;

for k=1:n
    rc = round(points(k,:));
    rr = rc(2)+ (-1*t:t);
    cc = rc(1) + (-1*t:t);
    rr(rr<1) = 1; rr(rr>size(im,1)) = size(im,1);
    cc(cc<1) = 1; cc(cc>size(im,2)) = size(im,2);
    imCrop=double(im(rr ,cc));
    imCrop=imCrop-mean(imCrop(:));
    corrcoef(k)=sum(sum(kernel.*imCrop))/sqrt(sum(sum(kernel.^2))*sum(sum(imCrop.^2)));         
end