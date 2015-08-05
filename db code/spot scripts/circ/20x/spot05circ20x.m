% Spot 5 circular polarization 20x database entry

% IRISdata ================================================
% metadata
IRISdata.type = 'circular';
IRISdata.oxideT = '30';
IRISdata.wavelength = '660';
IRISdata.nanorods = '25x60nm gold';
IRISdata.immersion = 'air';
IRISdata.mag = 20;
IRISdata.zStackStepMicrons = 1;
IRISdata.angle = 146;
IRISdata.detectionParams = struct(...
	'IntensityThresh', 0.6, ...
	'EdgeTh', 2,...
	'gaussianTh', -1,...
	'template', 5,...
	'SD', 1,...
	'innerRadius', 9,...
	'outerRadius', 12,...
	'contrastTh', 1.05,...
	'polarization', true);

% Load in IRIS images
irisFname = '/Users/derin/nanorodML/imageData/circular/2015-6-15 z stacks/20x/c12_3/c12_3_MMStack.ome.tif';
irisStackInfo = imfinfo(irisFname);
IRISdata.rawImages = zeros(irisStackInfo(1).Height, irisStackInfo(1).Width);
for n = 1:length(irisStackInfo)
	IRISdata.rawImages(:,:,n) = imread(irisFname,n);
end

% Get the feature info from corresponding 50x image database entry ============

% Load 50x
temp = load('/Users/derin/nanorodML/database/spot05circ50x.mat');
fiftyx = temp.results;
fiftyx.metadata.mag = 50; % backwards compatibility hack for testing

results = matchHiMagParticles(IRISdata, fiftyx);

% Add in the metadata
results.metadata = struct;
requiredFields = { 'type', 'oxideT', 'wavelength', 'nanorods', 'immersion', 'detectionParams'};
for n = 1:length(requiredFields)
	results.metadata.(requiredFields{n}) = IRISdata.(requiredFields{n});
end
results.metadata = IRISdata;

figure;
myIm = results.images(:,:,floor(size(results.images,3)/2));
imshow(myIm.*~results.excluded,median(myIm(:))*[0.8 1.2]);
hold on;
color = 'rgb';
categories = {'isolates', 'aggregates', 'large'};
for n = 1:length(categories)
	newCentroids = cat(1,results.features.(categories{n}).Centroid);
	plot(newCentroids(:,1), newCentroids(:,2), ['o' color(n)]);
end

rep = input('Does it look ok? [y]/n:', 's');
if isempty(rep)
	rep = 'y';
end
if rep ~= 'y'
	return;
end

% Check and save =========================================

% Run through the check function
ok = dbCheckFn(results);
if ~ok
	error('Not all fields present!');
	return;
end

% save if no errors
save('/Users/derin/nanorodML/database/spot05circ20x.mat', 'results');

disp('Finished saving!');
