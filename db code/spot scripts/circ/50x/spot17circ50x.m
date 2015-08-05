% Spot 17 circular polarization 50x database entry

% IRISdata ================================================
% metadata
IRISdata.type = 'circular';
IRISdata.oxideT = '30';
IRISdata.wavelength = '660';
IRISdata.nanorods = '25x60nm gold';
IRISdata.immersion = 'air';
IRISdata.mag = 50;
IRISdata.zStackStepMicrons = 1;
IRISdata.angle = 146;
IRISdata.detectionParams = struct(...
	'IntensityThresh', 0.6, ...
	'EdgeTh', 2,...
	'gaussianTh', 0,...
	'template', 5,...
	'SD', 1,...
	'innerRadius', 9,...
	'outerRadius', 12,...
	'contrastTh', 1.05,...
	'polarization', true);

% Load in IRIS images
irisFname = '/Users/derin/nanorodML/imageData/circular/2015-6-15 z stacks/50x/c3_1/c3_1_MMStack.ome.tif';
irisStackInfo = imfinfo(irisFname);
IRISdata.rawImages = zeros(irisStackInfo(1).Height, irisStackInfo(1).Width);
for n = 1:length(irisStackInfo)
	IRISdata.rawImages(:,:,n) = imread(irisFname,n);
end


% SEMdata ================================================
mosaicDim = [4 4]; % 5 down, 4 across

SEMdata.magScaledown = 14.2;
SEMdata.theta = 146;

% get composite image
fList = regexpdir('/Users/derin/nanorodML/imageData/sem/spot17', '^.*\.tif$');
ims = cell(1,length(fList));
for n = 1:length(fList)
	I = imread(fList{n});
	% black out the bottom 240 pixels
	I((end-240):end, :) = 0;

	ims{n} = I;
end
[compositeIm,excluded] = stitchMosaic(ims, mosaicDim);
SEMdata.excluded = excluded;
SEMdata.mosaic = compositeIm;


% Get the particle position info =========================
results = matchSEMParticles(IRISdata, SEMdata);

% Show results ===========================================

figure;
myIm = results.images(:,:,floor(size(results.images,3)/2));
imshow(myIm.*~results.excluded, median(myIm(:))*[0.8 1.2]);
hold on;
color = 'rgb';
categories = {'isolates', 'aggregates', 'large'};
for n = 1:length(categories)
	newCentroids = cat(1,results.features.(categories{n}).Centroid);
	plot(newCentroids(:,1), newCentroids(:,2), ['o' color(n)]);
end

rep = input('Does it look ok? [y]/n ', 's');
if isempty(rep)
	rep = 'y';
end
if rep ~= 'y'
	return;
end
close all
% Check and save =========================================

% Run through the check function
ok = dbCheckFn(results);
if ~ok
	error('Not all fields present!');
	return;
end

% save if no errors
save('/Users/derin/nanorodML/database/spot17circ50x.mat', 'results');

disp('Finished saving!');