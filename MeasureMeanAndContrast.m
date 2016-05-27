function [mn,cn]=MeasureMeanAndContrast(Image)

Image=single(Image);

mn=mean(mean(mean(Image)));
cn=std(reshape(Image,[],1,1))/mn;


end