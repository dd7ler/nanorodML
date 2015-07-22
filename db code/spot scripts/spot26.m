% Spot 26 database entry info

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
	'gaussianTh', -1,...
	'template', 5,...
	'SD', 1,...
	'innerRadius', 9,...
	'outerRadius', 12,...
	'contrastTh', 1.05,...
	'polarization', true);

% get IRIS images
irisFname = '/Users/derin/nanorodML/imageData/circular/2015-6-15 z stacks/50x/c4_2/c4_2_MMStack.ome.tif';
irisStackInfo = imfinfo(irisFname);
IRISdata.rawImages = zeros(irisStackInfo(1).Height, irisStackInfo(1).Width);
for n = 1:length(irisStackInfo)
	IRISdata.rawImages(:,:,n) = imread(irisFname,n);
end


% SEMdata ================================================
mosaicDim = [5 4]; % 5 down, 4 across

% SEMdata.excluded = NOT IMPLEMENTED YET :P
SEMdata.magScaledown = 14.2;
SEMdata.theta = 146;

% get composite image
fList = regexpdir('/Users/derin/nanorodML/imageData/sem/spot26', '^.*\.tif$');
ims = cell(1,length(fList));
for n = 1:length(fList)
	I = imread(fList{n});
	% black out the bottom 240 pixels
	I((end-240):end, :) = median(I(:));

	ims{n} = I;
end
compositeIm = stitchMosaic(ims, mosaicDim);
SEMdata.mosaic = compositeIm;


% Get the particle position info =========================
results = matchSEMParticles(IRISdata, SEMdata);

% Show results ===========================================

figure;
imshow(results.images(:,:,floor(length(irisStackInfo)/2)),[]);
hold on;
color = 'rgb';
categories = {'isolates', 'aggregates', 'large'};
for n = 1:length(categories)
	newCentroids = cat(1,results.features.(categories{n}).Centroid);
	plot(newCentroids(:,1), newCentroids(:,2), ['o' color(n)]);
end
