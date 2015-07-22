function results = detectRodSEM(image, threshold)
% Nanorods in an SEM image are identified and segmented.
% Individual rods are distinguished from clusters.
% Orientations are measured as well
% It also returns the locations and sizes of any large features (i.e. crystals)
% 
% You don't need to provide a threshold for the rods, but you can if you want.
% switch nargin
% case 0
% 	error('detectRodSEM needs an image');
% case 1
% 	threshold = graythresh(image);
% end
% 
% TODO - fix the bug where some edges look like a bunch of particles. better discrimination of large non-particle things by identifying large problem-regions, for example.

% get raw location data
bw = zeros(size(image));
bw(image>=threshold) = 1;
bw = logical(bw);
% bw = im2bw(image, threshold);
% figure; imshow(bw)
regions = regionprops(bw, 'Centroid', 'Area', 'Eccentricity', 'Orientation');

% The average size for a single nanorod is about 25-30 pixels in the first test image

minSingle = 15;
maxSingle = 50;
maxCluster = 250; % 10x the nominal average. Anything bigger than this is avoided entirely.

% Identify isolated particles (singletons)
sizes = cat(1,regions.Area);

results.isolates = regions(sizes>minSingle & sizes<maxSingle);

% Identify clusters/aggregates and larger features
results.aggregates = regions(sizes>maxSingle & sizes<maxCluster);

% Identify any large, bright features (crystals, dust, etc)
results.large = regions(sizes>maxCluster);
end