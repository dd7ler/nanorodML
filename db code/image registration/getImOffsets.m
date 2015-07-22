function deltaRCT = getImOffsets(images)
% getImOffsets Get the row, column and rotation offsets of a series of images 
% 	from the first one.
% 	
% deltaxyt = alignSeries(IMAGES) is a nx3 matrix, where n is size(IMAGES,3). 
% 	IMAGES is an array of same-size images, such that image i is retrieved with 
% 	images(:,:,i). Naturally, deltaRCT(1,:) = [0 0 0].
% 
% If size(images,3) ==1, deltaxyt is an empty matrix. Otherwise,
% 	each row of deltaxyt has the form [deltaR, deltaC, deltaTheta], where each 
% 	displacement is measured in pixels from the first image in the series.
% 
% NOTE - Only row and column offsets are implemented so far - not rotation. 
% 	So, the third column is always 0 - for now...

deltaRCT = zeros(size(images,3),3);
for n = 2:size(images,3)
    rc = phCorrAlign(images(:,:,1), images(:,:,n));
	deltaRCT(n,:) = [rc 0];
end