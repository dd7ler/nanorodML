function results = matchSEMParticles(IRISdata, SEMdata)
% function results = matchSEMParticles(IRISdata, SEMdata)
% 
% This function takes structured information about an IRIS dataset and corresponding image
% 
% IRISdata is a struct that contains all of the information about the IRIS image:
% rawImages : the images, in an array (r,c,n) stack or (r,c) single image of any type or size
% 				* rawImages need not be cropped.
% type		: either 'circular' or 'cross' - the acquisition type
% oxideT	: the oxide thickness of the substrate
% wavelength: illumination wavelength
% nanorods	: a string, describing the nanorod type (e.g., '25x60nm gold')
% immersion : either 'air' or 'water'
% mag		: the putative magnification (10, 20, 50, etc)
% zStackStepMicrons : This field is required if rawImages is a stack, and type is 'circular'
% angle 	: This field is required if rawImages is a stack, and type is 'cross'
% detectionParams : a structure, containing all of the detection parameters
% 				* Type 'help particleDetection' for information.
% 
% SEMdata is a struct that contains all of the relevant information about the SEM image:
% mosaic	: The mosaic SEM image
% excluded	: A logical mask with the same dimensions as 'mosaic' indicating unimaged regions
% magScaledown : the pixelwise magnification scalar between the IRIS image and the SEM image
% theta		: initial guess at the rotation angle, in degrees, from the IRIS image orientation to the SEM image orientation .
% 
% The output is the structure 'results' that contains all information for later analysis:
% metadata	: all fields from IRISdata except 'rawImages'
% images 	: the IRIS image
% features 	: a structure that contains all feature coordinates. 
% 				It has fields 'isolates', 'aggregates', and 'large'.
% 				Each of these fields is itself a structure array, with fields 'Centroid' , 'Area', 'Orientation', and 'Eccentricity'.
% excluded	: a binary mask the size of one image, indicating regions where there was no SEM coverage.

% ================================================================================================
% Check for and save IRIS image metadata for our output.
% This information isn't all required for the output, but it is for the database.
disp('Matching SEM to IRIS');
results = struct;
results.metadata = struct;
requiredFields = { 'type', 'oxideT', 'wavelength', 'nanorods', 'immersion', 'detectionParams', 'mag'};
for n = 1:length(requiredFields)
	if ~isfield(IRISdata,requiredFields{n})
		error(['matchSEMParticles requires that IRISdata has field "' requiredFields{n} '"']);
	end
	results.metadata.(requiredFields{n}) = IRISdata.(requiredFields{n});
end
if ~isfield(SEMdata,'excluded')
	error('matchSEMParticles requires that SEMdata has field "excluded"');
end

% Crop the IRIS image to the correct size
h = figure;
stackSize = size(IRISdata.rawImages,3);
if stackSize ==1
	[irisIm, cropRect] = imcrop(IRISdata.rawImages, median(IRISdata.rawImages(:))*[.6 1.4]);
	results.images = irisIm;
else
	% the middle image in the stack
	myIm = IRISdata.rawImages(:,:,floor(stackSize/2));
	[irisIm, cropRect] = imcrop(myIm,median(myIm(:))*[.6 1.4]);
	% crop and save the stack
	for n= 1:size(IRISdata.rawImages,3)
		results.images(:,:,n) = imcrop(IRISdata.rawImages(:,:,n),cropRect);
	end
	if results.metadata.type == 'circular'
		if ~isfield(IRISdata,'zStackStepMicrons')
			error('matchSEMParticles requires that IRISdata has field "zStackStepMicrons" because it is circular polarization');
		end
		results.metadata.zStackStepMicrons = IRISdata.zStackStepMicrons;
	elseif results.metadata.type == 'cross'
		if ~isfield(IRISdata,'angles')
			error('matchSEMParticles requires that IRISdata has field "angles" because it is circular polarization');
		end
		results.metadata.angles = IRISdata.angles;
	end
end
close(h);
pause(0.01);
disp('Initialization completed');
% ================================================================================================
% Detect the particles in the IRIS image
k = fspecial('gaussian',21,6);
smot = imfilter(irisIm, k, 'replicate', 'same');
m = mean(smot(:));
s = std(smot(:));
m1 = smot>(m+2*s) | smot<(m-2*s);
m2 = imdilate(m1, strel('disk',20));
masked = irisIm;
masked(m2)= median(irisIm(:));
% figure; imshow(masked,[]);

[XY,~,~] = particleDetection(masked, IRISdata.detectionParams);
irisParticles = XY{1};
figure; imshow(irisIm,median(irisIm(:))*[0.8 1.2]); hold on;
plot(irisParticles(:,1), irisParticles(:,2), '*r');
pause(.02);
disp('IRIS particles detected');
% ================================================================================================
% Detect the particles in the SEM image

SEMResults = detectRodSEM(SEMdata.mosaic);

% Unpack all the SEM particles into a single list (useful for matching)
semPList = [];
categories = {'isolates', 'aggregates', 'large'};
for n = 1:length(categories)
	s = SEMResults.(categories{n});
	coords = cat(1,s.Centroid);
	semPList = [semPList; coords];
end
disp('SEM particles detected');
% ================================================================================================
% Match up SEM particles and IRIS particles

% Rotate and scale down the SEM particle positions
semModel = zeros(size(semPList));
imDim = size(SEMdata.mosaic)/SEMdata.magScaledown;
for m = 1:length(semModel)
	semModel(m,:) = rotateCtrlPt(semPList(m,:)/SEMdata.magScaledown,-1*SEMdata.theta,fliplr(imDim));
end

% Align the two clusters of points using Coherent Point Drift

% % 1 - match up the mean centroids so they start close together
% v = mean(irisParticles,1)- mean(semModel,1);
% modelArr = zeros(size(model));
% for x = 1:size(model,2)
% 	modelArr(x,:) = model(x,:) + v;
% end

% 2 - Do the actual alignment nonrigidly (because the SEM image tiling is not certain)

opt.method='nonrigid'; % use nonrigid registration
opt.beta=4;            % the width of Gaussian kernel (smoothness)
opt.lambda=3;          % regularization weight

opt.viz=1;              % show every iteration
opt.outliers=.3;       % use 0.7 noise weight
opt.fgt=0;              % do not use FGT (default)
opt.normalize=1;        % normalize to unit variance and zero mean before registering (default)
opt.corresp=1;          % compute correspondence vector at the end of registration (not being estimated by default)

opt.max_it=500;         % max number of iterations
opt.tol=1e-10;          % tolerance

figure;
[Transform, C]=cpd_register(irisParticles,semModel, opt);


% do the alignment again but rigidly, to get the rotation translation and scaling factors for the exclusion mask

opt.method='rigid'; % use rigid registration
opt.viz=1;          % show every iteration
opt.outliers=0.6;   % use 0.1 noise weight
opt.normalize=1;    % normalize to unit variance and zero mean before registering (default)
opt.scale=1;        % estimate global scaling too (default)
opt.rot=1;          % estimate strictly rotational matrix (default)
opt.corresp=1;      % compute correspondence vector at the end of registration (not being estimated by default)

opt.max_it=500;     % max number of iterations
opt.tol=1e-8;       % tolerance

% do the transformation backwards, because there tends to be lots of 'extra' SEM particles (IRIS detection misses quite a few)
[MaskTransform, MaskC]=cpd_register(semModel, irisParticles, opt);

disp('SEM and IRIS particles matched');
% ================================================================================================
% Populate 'results.features' with the transformed particles

% Initialize 'results.features' with original data, swap in updated Centroids
results.features = SEMResults;
curIdx = 1;
for n = 1:length(categories)
	for m = 1:length(cat(1, SEMResults.(categories{n}).Centroid))
		results.features.(categories{n})(m).Centroid = Transform.Y(curIdx,:);
		curIdx = curIdx+1;
	end
end

disp('Particles aligned');
% ================================================================================================
% Transform the excluded region by the same transform as the particles

% Dilate first so no excluded regions are missed, because we use 'nearest' when resizing
scaleFactor = SEMdata.magScaledown/MaskTransform.s;
ex0 = imdilate(SEMdata.excluded, strel('disk', ceil(scaleFactor/2))); % 2x scaledown radius dilation, nyquist limit I think
% scale down
incl0 = imresize(~ex0, 1/scaleFactor, 'nearest');

% rotate by the total offset angle
incl1 = imrotate(incl0, SEMdata.theta, 'crop'); % this rotates about the center of the image, just like rotateCtrlPt
rotAngle = -1*180/pi*acos(MaskTransform.R(1)); % alignment rotation angle
incl2 = rotateAround(incl1, 0,0, rotAngle);
ex2 = ~incl2;


% translate the same amount as the control points
rcTranslate = -1*fliplr(MaskTransform.t');
ex3 = imtranslate(ex2, rcTranslate,1,'linear',false); % pad with 1, because 1 means 'not imaged');

% reshape to the correct size
size1 = size(ex3);
size2 = size(irisIm);
% y-direction
if size1(1)>size2(1)
	% The first image is too big
	ex3 = ex3(1:size2(1),:);
else
	ex3 = [ex3; ones(size2(1)-size1(1), size1(2))]; % make ex3 bigger (rows)
end
% x-direction
if size1(2)>size2(2)
	% The first image is too big
	ex3 = ex3(:,1:size(irisIm,2));
else
	ex3 = [ex3 ones(size(ex3,1), size(irisIm,2)-size(ex3,2))]; % make ex3 bigger (cols)
end

% dilate once more to to be safe
ex4 = imdilate(ex3, strel('disk', 3)); % roughly 1 psf width

% figure; imshow(double(irisIm).*~ex4,[]);
% hold on;
% color = 'rgb';
% categories = {'isolates', 'aggregates', 'large'};
% for n = 1:length(categories)
% 	newCentroids = cat(1,results.features.(categories{n}).Centroid);
% 	plot(newCentroids(:,1), newCentroids(:,2), ['o' color(n)]);
% end


results.excluded = ex4;

end