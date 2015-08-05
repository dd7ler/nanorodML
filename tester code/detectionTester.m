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

% Initialization
if nargin<2
	error('Not enough arguements dude.');
elseif nargin ==3
	displayMatchup = varargin{3};
end
fnName = varargin{1};
dataName = varargin{2};

% load the database
db = load(dataName);

% Use the particle detector
fnStr = [fnName + '(db.images, db.metadata)'];
particleData = eval(fnName);

% Match up the method with the database