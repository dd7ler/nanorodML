function particleData = simple_NanorodDetector(images, metadata)
% function particleData = simple_NanorodDetector(images, metadata)
% 
% ‘Images’ is a (r x c x n) array of n images with size (r x c). It will have the type ‘double’, and will not be scaled after reading it in from the file. There is no mirror normalization, and no ‘pre’ images.
% ‘Metadata’ is a MATLAB structure with a variety of fields. The fields are negotiable, but definitely at least includes the basic optical properties of the system:
% 
% method (‘circular’ or ‘cross’)
% range of angles or z-step size if applicable
% magnification
% NA
% Camera properties (pixel size, etc)
% illumination wavelength/spectrum
% oxide thickness
% nanorod size
% 
% If your function has any custom parameters that are adjusted depending on the magnification, etc, you need to keep those internal to the function and choose/adjust them based on ‘metadata’.
% 
% ‘particleData' is a struct that can contain any fields that you think may be interesting, but must contain at least one field in particular: ‘positions’. ‘positions’ is an [nx2] array, where the position of the nth particle is given by positions(n,:).
% 
% Positions should be in (x,y) coordinate format, not (r,c) format.

% =========================
% Check for required fields
% =========================

ok = dbCheckFn(results);

% ===================
% Parameter selection
% ===================

params = struct(...
	'IntensityThresh', 0.6, ...
	'EdgeTh', 2,...
	'gaussianTh', -1,...
	'template', 5,...
	'SD', 1,...
	'innerRadius', 9,...
	'outerRadius', 12,...
	'contrastTh', 1.05,...
	'polarization', true);


% example of how to adjust params based on an input
if(metadata.type=='circular')
	% adjust params
elseif (metadata.type=='cross')
	%adjust params
else
	error('Type error: metadata.type must be either "cross" or "circular"');
end

% ==================
% Particle detection
% ==================

% We're only using the middle image of the stack here, regardless of everything we've ever come to know.
im = images(:,:,ceil(size(images,3)));
[particleXY, contrasts, correlations] = detectParticles(im, params);

% format the output correctly
particleData.positions = particleXY{1};
particleData.contrasts = contrasts{1};
particleData.correlations = correlations{1};
