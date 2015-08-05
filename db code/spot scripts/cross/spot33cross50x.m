% spot33cross50x.m

% crossData ================================================
% metadata
crossData.type = 'cross';
crossData.oxideT = '30';
crossData.wavelength = '660';
crossData.nanorods = '25x60nm gold';
crossData.immersion = 'air';
crossData.mag = 50;
crossData.angles = -5:1:5;
crossData.angle = 146;
crossData.detectionParams = struct(...
	'IntensityThresh', 0.6, ...
	'EdgeTh', 2,...
	'gaussianTh', 0,...
	'template', 5,...
	'SD', 1,...
	'innerRadius', 9,...
	'outerRadius', 12,...
	'contrastTh', 1.1,...
	'polarization', true);


% Load in IRIS images
irisFname = '/Users/derin/nanorodML/imageData/cross/50x/PolStack_c5_164116.mat';
irisd = load(irisFname);
crossData.rawImages = irisd.image_data.image_cube;

% Get the featureinfo from corresponding 50x circular polarization database entry ============
temp = load('/Users/derin/nanorodML/database/circ/spot33circ50x.mat');
circData = temp.results;

results = matchCrossToCircParticles(crossData, circData);

results.metadata = struct;
requiredFields = { 'type', 'oxideT', 'wavelength', 'nanorods', 'immersion', 'detectionParams', 'mag', 'angles'};
for n = 1:length(requiredFields)
	results.metadata.(requiredFields{n}) = crossData.(requiredFields{n});
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
close all;

% save if no errors
save('/Users/derin/nanorodML/database/spot33cross50x.mat', 'results');

disp('Finished saving!');