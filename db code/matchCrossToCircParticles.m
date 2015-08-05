function results = matchCrossToCircParticles(crossData, circData)
% The function matches cross-polarized images (50x) with 
% circular-polarized images (50x) and maps the particle data over.

% get the cross image --------------------------------------------------------------------
h = figure;
stackSize = size(crossData.rawImages,3);
if stackSize ==1
	[crossIm, cropRect] = imcrop(crossData.rawImages, median(double(crossData.rawImages(:)))*[.6 1.4]);
	results.images = crossIm;
else
	% the middle image in the stack
	myIm = crossData.rawImages(:,:,floor(stackSize/2));
	[crossIm, cropRect] = imcrop(myIm,median(double(myIm(:)))*[.6 1.4]);
	% crop and save the stack
	for n= 1:size(crossData.rawImages,3)
		results.images(:,:,n) = imcrop(crossData.rawImages(:,:,n),cropRect);
	end
end
results.images = double(results.images);
crossIm = double(crossIm);
close(h);
pause(0.01);

% get the circ image --------------------------------------------------------------------
% we don't need to crop!
stackSize = size(circData.images,3);
if stackSize ==1
	circIm = circData.images;
else
	% the middle image in the stack
	circIm = double(circData.images(:,:,floor(stackSize/2)));
end
circIm = double(circIm);


% The scaling and rotation might be slightly off, so we use CPD instead of phase correlation

% get the cross particles
k = fspecial('gaussian',31,8);
smot = imfilter(crossIm, k, 'replicate', 'same');
m = mean(smot(:));
s = std(smot(:));
m1 = smot>(m+2*s) | smot<(m-2*s);
m2 = imdilate(m1, strel('disk',20));
masked = crossIm;
masked(m2)= median(crossIm(:));
% figure; imshow(masked,[]);

[XY,~,~] = particleDetection(masked, crossData.detectionParams);
crossParticles = XY{1};
figure; imshow(crossIm,median(crossIm(:))*[0.8 1.2]); hold on;
plot(crossParticles(:,1), crossParticles(:,2), '*r');
pause(.02);
disp('Cross particles detected');

% Unpack all the CIRC particles into a single list (useful for matching)
circParticles = [];
categories = {'isolates', 'aggregates', 'large'};
for n = 1:length(categories)
	s = circData.features.(categories{n});
	coords = cat(1,s.Centroid);
	circParticles = [circParticles; coords];
end

% DO ALIGNMENT

opt.method='rigid'; % use rigid registration
opt.viz=1;          % show every iteration
opt.outliers=0.5;   % use 0.1 noise weight
opt.normalize=1;    % normalize to unit variance and zero mean before registering (default)
opt.scale=1;        % estimate global scaling too (default)
opt.rot=1;          % estimate strictly rotational matrix (default)
opt.corresp=1;      % compute correspondence vector at the end of registration (not being estimated by default)

opt.max_it=1000;     % max number of iterations
opt.tol=1e-8;       % tolerance

% do the transformation backwards, because there tends to be lots of 'extra' SEM particles (IRIS detection misses quite a few)
[Transform, C]=cpd_register(crossParticles, circParticles, opt);

disp('SEM and IRIS particles matched');
% ================================================================================================
% Populate 'results.features' with the transformed particles

% Initialize 'results.features' with original data, swap in updated Centroids
results.features = circData.features;
curIdx = 1;
for n = 1:length(categories)
	for m = 1:length(cat(1, circData.features.(categories{n}).Centroid))
		results.features.(categories{n})(m).Centroid = Transform.Y(curIdx,:);
		curIdx = curIdx+1;
	end
end

disp('Particles aligned');

% ================================================================================================
% transfer over the excluded region as well

% Dilate first so no excluded regions are missed, because we use 'nearest' when resizing
% make bigger (the 50x images have a higher-resolution camera, so it's bigger in pixel-space)
incl1 = imresize(~circData.excluded, Transform.s, 'nearest');

% translate the same amount as the control points
rcTranslate = fliplr(Transform.t');
incl2 = imtranslate(incl1, rcTranslate,0,'linear',false); % pad with 0, because 0 means 'not imaged');


% rotate by the offset angle
rotAngle = -180/pi*acos(Transform.R(1)); % alignment rotation angle
incl3 = rotateAround(incl2, 0,0, rotAngle);
ex0 = ~incl3;

% reshape to the correct size
size1 = size(ex0);
size2 = size(crossIm);
% y-direction
if size1(1)>size2(1)
	% The first image is too big
	ex0 = ex0(1:size2(1),:);
else
	ex0 = [ex0; ones(size2(1)-size1(1), size1(2))]; % make ex0 bigger (rows)
end
% x-direction
if size1(2)>size2(2)
	% The first image is too big
	ex0 = ex0(:,1:size(crossIm,2));
else
	ex0 = [ex0 ones(size(ex0,1), size(crossIm,2)-size(ex0,2))]; % make ex0 bigger (cols)
end

figure; imshow(double(crossIm).*~ex0,median(double(crossIm(:)))*[.6 1.4]);
hold on;
color = 'rgb';
categories = {'isolates', 'aggregates', 'large'};
for n = 1:length(categories)
	newCentroids = cat(1,results.features.(categories{n}).Centroid);
	plot(newCentroids(:,1), newCentroids(:,2), ['o' color(n)]);
end


results.excluded = ex0;