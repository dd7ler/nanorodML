% Spot 03 cross polarization 20x database entry

% crossData ================================================
% metadata
crossData.type = 'cross';
crossData.oxideT = '30';
crossData.wavelength = '660';
crossData.nanorods = '25x60nm gold';
crossData.immersion = 'air';
crossData.mag = 20;
crossData.angles = -5:1:5;
crossData.angle = 146;
crossData.detectionParams = struct(...
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
irisFname = '/Users/derin/nanorodML/imageData/cross/20x/PolStack_c1c2_132421.mat';
irisd = load(irisFname);
crossData.rawImages = double(irisd.image_data.image_cube);


% Get the feature info from corresponding 50x image database entry ============

% Load 50x
temp = load('/Users/derin/nanorodML/database/cross/spot03cross50x.mat');
fiftyx = temp.results;

results = matchHiMagParticles(crossData, fiftyx);

% Add in the metadata
results.metadata = struct;
requiredFields = { 'type', 'oxideT', 'wavelength', 'nanorods', 'immersion', 'detectionParams'};
for n = 1:length(requiredFields)
	results.metadata.(requiredFields{n}) = crossData.(requiredFields{n});
end
results.metadata = crossData;

figure;
myIm = results.images(:,:,floor(size(results.images,3)/2));
myIm = double(myIm);
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
close all;

% Check and save =========================================

% Run through the check function
ok = dbCheckFn(results);
if ~ok
	error('Not all fields present!');
	return;
end

% save if no errors
save('/Users/derin/nanorodML/database/cross/spot03cross20x.mat', 'results');

disp('Finished saving!');
