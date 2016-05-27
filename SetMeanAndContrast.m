function [ ImageOut ] = SetMeanAndContrast( Image,mn,cn )
%Set mean luminance mn and contrast cn of an image

%convert to single precision
Image=single(Image);

%set the mean
mn0=mean(mean(mean(Image)));
Image=Image+(mn-mn0);

%set the contrast
std0=std(reshape(Image,[],1,1));
cn0=std0/mn;
Image=(Image-mn)*(cn/cn0)+mn;
ImageOut=uint8(Image);

end

