
% Align two iris images of different (or same) magnification

% grab the middle image from both stacks
% image1 
irisFname = '/Users/derin/nanorod ML/image data/circular/2015-6-15 z stacks/50x/c4_2/c4_2_MMStack.ome.tif';
irisStackInfo = imfinfo(irisFname);
nIms = length(irisStackInfo);
im1Raw = imread(irisFname,floor(nIms/2));
h = figure;
im1 = imcrop(im1Raw,[]);
close(h)
pause(.01);

% image2
irisFname = '/Users/derin/nanorod ML/image data/circular/2015-6-15 z stacks/20x/c34_1/c34_1_MMStack.ome.tif';
irisStackInfo = imfinfo(irisFname);
nIms = length(irisStackInfo);
im2Raw = imread(irisFname,floor(nIms/2));
h = figure;
im2 = imcrop(im2Raw,[]);
close(h)
pause(.01);


% rescale im1 down to im2 size
im1Scale = 50;
im2Scale = 20;

scaleFactor = im2Scale/im1Scale;
if scaleFactor~=1
	im1 = imresize(im1,scaleFactor);
end

% Crop images to the same size, so we can use phase correlation alignment
size1 = size(im1);
size2 = size(im2);
% y-direction
if size1(1)>size2(1)
	% The first image is too big
	im1 = im1(1:size2(1),:);
else
	im2 = im2(1:size1(1),:);
end

% x-direction
if size1(2)>size2(2)
	% The first image is too big
	im1 = im1(:,1:size2(2));
else
	im2 = im2(:,1:size1(2));
end

% Align the two images
[delta, q] = phCorrAlign(im1, im2);

% % show the unaligned images superposed
% figure; imshow(double(im1)+double(im2),[]);

% % show the aligned images superposed
% im1Aligned = imtranslate(double(im1), -1*delta);
% figure; imshow(double(im1Aligned)+double(im2),[]);