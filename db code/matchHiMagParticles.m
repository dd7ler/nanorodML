function results = matchHiMagParticles(irisData, hiMagData)
% This function works the same way as 'matchSEMParticles', except that
% it takes the feature information from a higher magnification image and
% passes it down to a lower magnification dataset.


% Crop irisData to the correct size
% This assumes that the 20x and 50x images were acquired with the same settings. Pretty lazy...
h = figure;
stackSize = size(irisData.rawImages,3);
if stackSize ==1
	[irisIm, cropRect] = imcrop(irisData.rawImages);
	results.images = irisIm;
	hiIm = hiMagData.images;
else
	% the middle image in the stack
	[irisIm, cropRect] = imcrop(irisData.rawImages(:,:,floor(stackSize/2)),[]);
	hiIm = hiMagData.images(:,:,floor(stackSize/2)); % 
	% crop and save the stack
	for n= 1:size(irisData.rawImages,3)
		results.images(:,:,n) = imcrop(irisData.rawImages(:,:,n),cropRect);
	end
end
close(h);
pause(0.01);

% ================================================================================================
% Align the two image

% Scale down hiIm
scaleFactor = irisData.mag/hiMagData.metadata.mag;
if scaleFactor~=1
	hiIm = imresize(hiIm,scaleFactor);
end

size1 = size(hiIm);
size2 = size(irisIm);
% y-direction
if size1(1)>size2(1)
	% The first image is too big
	hiIm = hiIm(1:size2(1),:);
else
	irisIm = irisIm(1:size1(1),:);
end

% x-direction
if size1(2)>size2(2)
	% The first image is too big
	hiIm = hiIm(:,1:size2(2));
else
	irisIm = irisIm(:,1:size1(2));
end

[delta, q] = phCorrAlign(hiIm, irisIm);
% Check the alignment
figure; imshow(double(hiIm)+double(irisIm),[]);
hiImAligned = imtranslate(double(hiIm), -1*delta);
figure; imshow(double(hiImAligned)+double(irisIm),[]);


% ================================================================================================
% Translate the coordinates

% The previous image resizing step was done wrt the origin, so we don't have to account for that

% copy over all coordinate information
results.features = hiMagData.features;
categories = {'isolates', 'aggregates', 'large'};



figure; 
imshow(irisIm,[]);
hold on;
colors = 'rgb';
for n = 1:length(categories)
	centroids = cat(1, results.features.(categories{n}).Centroid);
	for m = 1:length(centroids)
		% scaledown (no rotation)
		c0 = centroids(m,:)*scaleFactor;
		% translate by delta
		c1 = c0 - fliplr(delta);
		results.features.(categories{n})(m).Centroid = c1;
	end
	outResults = cat(1,results.features.(categories{n}).Centroid);
	plot(outResults(:,1),outResults(:,2), ['o' colors(n)]);
end
