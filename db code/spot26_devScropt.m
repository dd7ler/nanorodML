
spot26Dim = [5 4];

% load images
fList = regexpdir('/Users/derin/nanorod ML/image data/sem/spot26', '^.*\.tif$');
ims = cell(1,length(fList));
for n = 1:length(fList)
	I = imread(fList{n});
	% black out the bottom 240 pixels
	I((end-240):end, :) = median(I(:));

	ims{n} = I;
end
compositeIm = stitchMosaic(ims, spot26Dim);
figure; imshow(compositeIm, []);

% downsample the SEM results to the same pixel distance as the IRIS data
scaleDownFactor = 14.2; 

% SEM image scaledown - useful for visualization
imDown = imresize(compositeIm,1/10);

% get the circular polarization image from z-stack
irisFname = '/Users/derin/nanorod ML/image data/circular/2015-6-15 z stacks/50x/c4_2/c4_2_MMStack.ome.tif';
irisStackInfo = imfinfo(irisFname);
nIms = length(irisStackInfo);

% Naively grab the middle image
irisRaw = imread(irisFname,floor(nIms/2));

% Crop the correct region
h = figure; 
irisIm = imcrop(irisRaw,[]);
close(h);
pause(0.01);

% Get particle positions from IRIS
% best guess at parameters
defaultParams = struct(...
	'IntensityThresh', 0.6, ...
	'EdgeTh', 2,...
	'gaussianTh', -1,...
	'template', 5,...
	'SD', 1,...
	'innerRadius', 9,...
	'outerRadius', 12,...
	'contrastTh', 1.05,...
	'polarization', true); 
[particleXY, contrasts, correlations] = particleDetection(irisIm, defaultParams);
irisParticles = particleXY{1}';

% Display IRIS results
figure; imshow(irisIm,[]);
hold on;
plot(irisParticles(1,:), irisParticles(2,:), 'o');
size(irisParticles)

% find all the particles in the SEM image
% Get the particle threshold by finding pixels greater than the background noise
I = imread(fList{5});
h = double(I(1:(end-240),:));
m = mean(h(:));
s = std(h(:));
thresh = m+4*s;
% bw = zeros(size(I));
% bw(I>thresh) = 1;
% bw(I<thresh) = 0;
% figure; imshow(bw);

SEMResults = detectRodSEM(compositeIm, thresh);

% display unscaled SEM results
figure; 
imshow(compositeIm,[]);
hold on;

colors = 'rbc';
for n = 1:3
	s = SEMResults.(categories{n});
	coords = cat(1,s.Centroid);
	plot(coords(:,1), coords(:,2), ['o' colors(n)]);
end

% Rescale the SEM results
% shrink to the 50x scale and rotate -146 degrees
categories = {'isolated', 'aggregates', 'large'};
theta = 146;
imDim = size(imDown);
for n = 1:3
	coords = cat(1,SEMResults.(categories{n}).Centroid);
	newCoords = [];
	for m = 1:length(coords)
		newCoords(m,:) = rotateCtrlPt(coords(m,:)/scaleDownFactor,-1*theta,fliplr(imDim));
	end
	scaledCoords.(categories{n}).coords = newCoords;
end

% display rotated and scaled SEM particles
% figure; 
% hold on;

% categories = {'isolated', 'clusters', 'aggregates'};
% colors = 'rbc';
% for n = 1:3
% 	coords = scaledCoords.(categories{n}).coords;
% 	plot(coords(:,1), coords(:,2), ['o' colors(n)]);
% end

% Match up the IRIS particles with the SEM particles
% get the IRIS particles
irisParticles = particleXY{1};
% get all the SEM particles
semParticles = [];
for n = 1:3
	semParticles = [semParticles; scaledCoords.(categories{n}).coords];
end
% plot both
% figure; plot(semParticles(:,1), semParticles(:,2), 'o', irisParticles(:,1), irisParticles(:,2), '*');



% Find the best overlap using Iterative Closest Point algorithm
model = semParticles';
data = irisParticles';
% find the centroids for each group, and adjust the model (SEM) so they start close

v = mean(data,2)- mean(model,2);
modelArr = zeros(size(model));
for x = 1:size(model,2)
	modelArr(:,x) = model(:,x) + v;
end

figure; hold on; 
plot(modelArr(1,:), modelArr(2,:), 'o', data(1,:), data(2,:), '*');
axis([0 1000 0 800]);
% do the alignment
[R,T,dataOut]=icp(modelArr,data,[],[],1);
% Display the aligned data + native model
figure; hold on;
plot(modelArr(1,:),modelArr(2,:),'o',dataOut(1,:),dataOut(2,:),'*'), axis equal
axis([0 1000 0 800]);


% ugly-ass angle inversion
rotAngle = -1*acos(R(1)); % opposite direction
rotMat = [cos(rotAngle) -1*sin(rotAngle) ; sin(rotAngle) cos(rotAngle)];

% Rotate and scale the model data forwards, show that is equivalent
% modelAligned = zeros(size(modelArr));
% for n = 1:size(modelArr,2)
	
% 	% rotation
% 	temp = rotMat*modelArr(:,n);
% 	% translation
% 	modelAligned(:,n) = temp - T;
% end


modelAligned = zeros(size(modelArr));
for n = 1:size(modelArr,2)
	
	% rotation
	temp = rotMat*modelArr(:,n);
	% translation
	modelAligned(:,n) = temp - T;
end


plot(modelAligned(1,:),modelAligned(2,:),'o',data(1,:),data(2,:),'*'), axis equal

% Great! Now we know where all the particles are. Plot them on the original IRIS image.
figure; imshow(irisIm,[]);
hold on;
plot(modelAligned(1,:),modelAligned(2,:),'o');