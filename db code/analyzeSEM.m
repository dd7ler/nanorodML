function results = analyzeSEM(imginfo)
% 
% nanorods, clusters and aggregates are identified from tiled SEM images
% The position and orientation of every nanorod is determined.
% Also, clusters (2-20 nanorods) and aggregates (20+ or salt crystals) are identified.
% 
% 
% It can remove the SEM banner:
% provide imginfo.hasBanner = true, and the imginfo.bannerHeight
% 
% It rotates the SEM coordinate system by the angle in imginfo.angleOffset
% 

% load the corresponding 50x SP-IRIS image
iris = load(imginfo.irisFile);
irisIm = iris.data;

% TODO - test this
% detect the particles in the IRIS image
defaultParams = struct(...
	'IntensityThresh', 0.6, ...
	'EdgeTh', 2,...
	'gaussianTh', 0.45,...
	'template', 5,...
	'SD', 1,...
	'innerRadius', 9,...
	'outerRadius', 12,...
	'contrastTh', 1.01,...
	'polarization', true); 
[particleXY, contrasts, correlations] = particleDetection(irisIm, defaultParams);

% TODO - test this
% rotate the coordinate system of the IRIS image to match the SEM image
% The rotation is about the origin, which is at the top-left corner of the image.
% This is to get it close - not perfect. Particle alignment should include matching as well.
% The iris image must be rotated by +147.65 degrees to match the SEM images.
% This angle is for all of them.
theta = imginfo.angleOffset;
dim = size(irisIm);
for n = 1:length(particleXY)
	rc = fliplr(particleXY(n:));
	rcOut = rotateCtrlPt(rc, theta, dim)
end

rodData = cell(length(imginfo.fnames),1);
for tile = 1:length(imginfo.fnames)
	imf = imginfo.fnames{tile};
	image = imread(imf);

	if (imginfo.hasBanner)
		image = image(1:(end-imginfo.bannerHeight), :);
	end

	% get data for this tile
	rodData{tile} = detectRodSEM(image);

	% TODO
	% Do a gross alignment of the image data from each SEM tile to the IRIS image
end



% TODO scale the particle coordinate system to the IRIS image

