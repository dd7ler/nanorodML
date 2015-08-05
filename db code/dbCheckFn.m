function isOk = dbCheckFunction(dbInfo)
% This function returns 'true' if all of the required fields are present.
% It won't return 'false', instead it'll throw an error if it's unhappy with your output.
% 
% Required fields in results.metadata:
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
% Other fields for results:
% images 	: the actual imge data


% check metadata fields
requiredFields = { 'type', 'mag', 'oxideT', 'wavelength', 'nanorods', 'immersion', 'detectionParams'};

for n = 1:length(requiredFields)
	if ~isfield(dbInfo.metadata,requiredFields{n})
		error(['Database requires that metadata has field "' requiredFields{n} '"']);
	end
end
% check type (cirular or cross) so we can check for either 'angle' or 'zStackStepMicrons'
if strcmp(dbInfo.metadata.type,'circular')
	if ~isfield(dbInfo.metadata,'zStackStepMicrons')
		error('matchSEMParticles requires that dbInfo.metadata has field "zStackStepMicrons" because it contains more than one circular-polarization image');
	end
elseif strcmp(dbInfo.metadata.type,'cross')
	if ~isfield(dbInfo.metadata,'angles')
		error('matchSEMParticles requires that dbInfo.metadata has field "angles" because it contains more than one cross-polarization image');
	end
end

% check for images
if ~isfield(dbInfo,'images')
	error('Database requires the field "images"');
end
% check for features
if ~isfield(dbInfo,'features')
	error('Database requires the field "features"');
end
% check for excluded
if ~isfield(dbInfo,'excluded')
	error('Database requires the field "excluded"');
end

isOk = true;
return;
end