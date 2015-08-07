function [counts, falsePos, falseNeg] = nanorodTester(varargin)
% function results = nanorodTester(fnName, dataName, displayMatchup)
% 
% fnName is the name of the detection function you want to test (a string).
% dataName is the name of the database .mat file you wish to evaluate with (also a string).
% displayMatchup can be true (1) to show the matchup plot, or false (0) or ignored.
% 
% Both the detection function and dataName should be on your path, and should be unique.
%
% Counts is the number of particles detected by 'fnName' in 'dataName'
% falsePos is the number of particles detected by 'fnName' that *weren't* in the database
% falseNeg is the number of particles *not* detected by 'fnName' that were in the database
tic
% Initialization
if nargin<2
	error('Not enough arguements dude.');
elseif nargin ==3
	displayMatchup = varargin{3};
end
fn = varargin{1};
dataName = varargin{2};

% load the database
db = load(dataName);
r = db.results;

% check that it has all fields
ok = dbCheckFn(r);

% extract particle coordinates
dbParticles = [];
categories = {'isolates', 'aggregates', 'large'};
for n = 1:length(categories)
	s = r.features.(categories{n});
	coords = cat(1,s.Centroid);
	dbParticles = [dbParticles; coords];
end

% Use the particle detector
particleData = feval(fn,r.images, r.metadata);
detectorXY = particleData.positions;


% Match particles
particles = {detectorXY, dbParticles};
m = matchParticles(particles,8); % cluster bandwidth decides how loose of an association is ok
matches = m{1};

counts = length(matches);
falsePos = length(detectorXY)-counts;
falseNeg = length(dbParticles) - counts;


if displayMatchup

	% Display results
	figure;
	im = r.images(:,:,ceil(size(r.images,3)/2));
	imshow(im,median(im(:))*[.6 1.4]);
	hold on;
	plot(detectorXY(:,1),detectorXY(:,2), '*r', dbParticles(:,1), dbParticles(:,2), 'ob');
	for n = 1:length(matches)
		p1 = detectorXY(matches(n,1),:);
		p2 = dbParticles(matches(n,2),:);
		x = [p1(1) p2(1)];
		y = [p1(2) p2(2)];
		line(x,y,'Color','k', 'LineWidth', 2);
	end
	legend('detector', 'ground truth', 'matches');

end
toc