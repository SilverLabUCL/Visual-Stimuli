function [ Images ] = TreatPictures( filenames, path )
%treat pictures to be presented to a mouse
%- convert them into black and white
%- set contrast and luminance

if nargin<2
    path='C:\Users\Chiara\Documents\MATLAB\visual stimuli\natural images\mouse pictures\';
end

%final contrast and luminance values 
cn=0.5;
mn=120;

n_pictures=size(filenames);
Images=cell(1,n_pictures);

for pic=1:n_pictures
    
    %import image into matlab matrix
    I= imread([path filenames(pic,:) '.JPG']);
    %convert to black and white
    IBW=rgb2gray(I);
    %set mean luminance and contrast
    [ ImageOut ] = SetMeanAndContrast( IBW,mn,cn );
    
    Images{pic}=ImageOut;
end


save('NatImag.mat','Images')


end

