function imOut = naiveMosaic(ims, dims)
% Shoulder-to-shoulder composition (Use if there is NO OVERLAP)
% 
% ims is a cell array of images that all have the same size.
% images are in order left to right, descending rows (like reading a paragraph).
% dims is the dimensions of the composite in matrix layout convention [r, c].
%

down = dims(1);
across = dims(2);

tileSize = size(ims{1});
outSize = tileSize.*dims;


temp = repmat([1:down]-1, across, 1);
startR = reshape(temp, 1, down*across)*tileSize(1);
startC = repmat([1:across]-1,1, down)*tileSize(2);


imOut = zeros(outSize);
for n = 1:(dims(1)*dims(2))
	r = (startR(n)+1):(startR(n)+tileSize(1));
	c = (startC(n)+1):(startC(n)+tileSize(2));
	imOut(r, c) = ims{n};
end
