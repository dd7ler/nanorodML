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
	[irisIm, cropRect] = imcrop(IRISdata.rawImages);
	results.images = irisIm;
else
	% the middle image in the stack
	[irisIm, cropRect] = imcrop(IRISdata.rawImages(:,:,floor(stackSize/2)),[]);
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
[XY,~,~] = particleDetection(irisIm, IRISdata.detectionParams);
irisParticles = XY{1};

disp('IRIS particles detected');
% ================================================================================================
% Detect the particles in the SEM image
m = mean(SEMdata.mosaic(:));
s = std(SEMdata.mosaic(:));
thresh = m+4*s; % four standard deviations above background
SEMResults = detectRodSEM(SEMdata.mosaic, thresh);

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

% Align the two clusters of points using iterative closest point (ICP) matching
model = semModel';
data = irisParticles';

% 1 - match up the mean centroids so they start close together
v = mean(data,2)- mean(model,2);
modelArr = zeros(size(model));
for x = 1:size(model,2)
	modelArr(:,x) = model(:,x) + v;
end
% 2 - Do the actual alignment
[R,T,dataOut]=icp(modelArr,data,[],[],1);

disp('SEM and IRIS particles matched');
% ================================================================================================
% Transform the SEM particles to the cropped IRIS reference frame, and populate 'results.features'

rotAngle = -1*acos(R(1)); % reverse rotation angle
rotMat = [cos(rotAngle) -1*sin(rotAngle) ; sin(rotAngle) cos(rotAngle)];

% Initialize 'results.features' with original data, swap in updated Centroids
results.features = SEMResults;
for n = 1:length(categories)
	% get all the original centroids
	centroids = cat(1, SEMResults.(categories{n}).Centroid);

	for m = 1:length(centroids)
		% rotate and scaledown
		c0 = rotateCtrlPt(centroids(m,:)/SEMdata.magScaledown,-1*SEMdata.theta,fliplr(imDim));
		% translate by means
		temp = c0' + v - T;
		finalXY = rotMat*temp;
		results.features.(categories{n})(m).Centroid = finalXY';
	end
end

disp('Particles aligned');
% ================================================================================================
% Transform the excluded region by the same transform as the particles

% Dilate first so no excluded regions are missed, because we use 'nearest' when resizing
ex0 = imdilate(SEMdata.excluded, strel('disk', ceil(SEMdata.magScaledown))); % 2x scaledown radius dilation, nyquist limit I think

% scale down
incl0 = imresize(~SEMdata.excluded, 1/SEMdata.magScaledown, 'nearest');

% rotate by the rough offset angle
incl1 = imrotate(incl0, SEMdata.theta, 'crop'); % this rotates about the center of the image, just like rotateCtrlPt
ex1 = ~incl1;

% translate the same amount as the control points
rcTranslate = fliplr([v-T]');
ex2 = imtranslate(ex1, rcTranslate,1,'linear',false); % pad with 1, because 1 means 'not imaged');

% Alignment rotation about origin
ex3 = rotateAround(ex2, 0,0, rotAngle);
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
	ex3 = ex3(:,1:size2(2));
else
	ex3 = [ex3 ones(size1(1), size2(2)-size1(2))]; % make ex3 bigger (cols)
end

% dilate once more to to be safe
ex4 = imdilate(ex3, strel('disk', 3)); % roughly 1 psf width

% figure; imshow(double(irisIm).*~ex4,[]);

results.excluded = ex4;

end