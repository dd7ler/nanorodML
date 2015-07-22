
spot7Dim = [4 4];

% load images
fList = regexpdir('/Users/derin/nanorod ML/image data/sem/spot7', '^.*$');
ims = cell(1,length(fList));
for n = 1:length(fList)
	I = imread(fList{n});
	% black out the bottom 240 pixels
	I((end-240):end, :) = median(I(:));

	ims{n} = I;
end
compositeIm = naiveMosaic(ims, spot7Dim);
% figure; imshow(imOut, []);

% find all the particles
results = detectRodSEM(compositeIm);