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
	hiMag = hiMagData.images;
else
	% the middle image in the stack
	[irisIm, cropRect] = imcrop(irisData.rawImages(:,:,floor(stackSize/2)),[]);
	hiMag = hiMagData.images(:,:,floor(stackSize/2)); % 
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
	hiIm = imresize(hiMag,scaleFactor);
end

irisAlign = irisIm; % temporary variable for alignment
size1 = size(hiIm);
size2 = size(irisAlign);
% y-direction
if size1(1)>size2(1)
	% The first image is too big
	hiIm = hiIm(1:size2(1),:);
else
	irisAlign = irisAlign(1:size1(1),:);
end

% x-direction
if size1(2)>size2(2)
	% The first image is too big
	hiIm = hiIm(:,1:size2(2));
else
	irisAlign = irisAlign(:,1:size1(2));
end

[delta, q] = phCorrAlign(hiIm, irisAlign);
% Check the alignment
% figure; imshow(double(hiIm)+double(irisAlign),[]);
hiImAligned = imtranslate(double(hiIm), -1*delta);
% figure; imshow(double(hiImAligned)+double(irisAlign),[]);


% ================================================================================================
% Translate the coordinates

% The previous image resizing step was done wrt the origin, so we don't have to account for that

% copy over all coordinate information
results.features = hiMagData.features;
categories = {'isolates', 'aggregates', 'large'};

% figure; 
% imshow(irisIm,median(irisIm(:))*[0.6 1.4]);
% hold on;
% colors = 'rgb';

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
	% plot(outResults(:,1),outResults(:,2), ['o' colors(n)]);
end

% ================================================================================================
% Translate 'excluded'

% Scale down
if scaleFactor~=1
	ex0 = imresize(hiMagData.excluded,scaleFactor);
else
	ex0 = hiMagData.excluded;
end

% translate by delta (no rotation)
ex1 = imtranslate(ex0, -1*delta,1,'linear',false); % pad with 1, because 1 means 'not imaged');

% reshape to the correct size
size1 = size(ex1);
size2 = size(irisIm);
% y-direction
if size1(1)>size2(1)
	% The first image is too big
	ex1 = ex1(1:size2(1),:);
else
	ex1 = [ex1; ones(size2(1)-size1(1), size1(2))]; % make ex1 bigger (rows)
end
% x-direction
if size1(2)>size2(2)
	% The first image is too big
	ex1 = ex1(:,1:size2(2));
else
	ex1 = [ex1 ones(size(ex1,1), size2(2)-size(ex1,2))]; % make ex1 bigger (cols)
end

% figure; imshow(hiMag.*~hiMagData.excluded,[]);
% figure; imshow(irisIm.*~ex1,[]);

results.excluded = ex1;
