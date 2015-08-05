function results = detectRodSEM(image)
% Nanorods in an SEM image are identified and segmented.
% Individual rods are distinguished from clusters.
% Orientations are measured as well
% It also returns the locations and sizes of any large features (i.e. crystals)

% =======================================================================
% Find large bright features. This includes large salt crystals, or Si regions

% smooth over nanorods
k = fspecial('gaussian',121,30);
I2 = imfilter(image, k, 'replicate', 'same');
% figure; imshow(I2,[]); 

% threshold brighter regions against background
m = mean(I2(:));
s = std(I2(:));
I3 = I2>(m+3*s) | I2<(m-3*s);
% figure; imshow(I3,[])

% closing - close all holes in features
I4 = imclose(I3, strel('disk',50));

% dilation - cast a larger shadow, to be conservative.
results.largeMask = imdilate(I4, strel('disk', 250));
% figure; imshow(results.largeMask);

% Enumerate these large features
results.large = regionprops(results.largeMask, 'Centroid', 'Area', 'Eccentricity', 'Orientation');

% =======================================================================
% Find nanorods and clusters

% hi-pass filter
I2 = imtophat(image, strel('disk', 5));
% figure; imshow(I2,[])
% Binarize - rods are much brighter than the background
m = mean(I2(:));
s = std(I2(:));
I3 = (I2>=m+10*s);
% figure; imshow(I3,[]);

% close - combine very near features into a single larger one
I4 = imclose(I3, strel('disk', 15));
% figure; imshow(I4,[]);

nrRegions = regionprops(I4, 'Centroid', 'Area', 'Eccentricity', 'Orientation');

% =======================================================================
% Remove all nanorod regions within the large features
coords = cat(1,nrRegions.Centroid);
isInside = zeros(1, length(coords));
for n = 1:length(coords)
	xy = round(coords(n,:));
	isInside(n) = results.largeMask(xy(2), xy(1));
end
nrRegions(logical(isInside)) = [];

% =======================================================================
% sort remaining nanorod regions by size
% The average size for a single nanorod is about 25-30 pixels in the first test image
minSingle = 8;
maxSingle = 35; % anything larger than this is not a single nanorod
% 
% Identify isolated particles (singletons)

% remove everyting
sizes = cat(1,nrRegions.Area);

results.isolates = nrRegions(sizes>minSingle & sizes<maxSingle);

% Identify clusters/aggregates and larger features
results.aggregates = nrRegions(sizes>maxSingle);


% verification image
figure; imshow(image, []);
hold on;
color = 'rgb';
categories = {'isolates', 'aggregates', 'large'};
for n = 1:length(categories)
	newCentroids = cat(1,results.(categories{n}).Centroid);
	plot(newCentroids(:,1), newCentroids(:,2), ['o' color(n)]);
end

end