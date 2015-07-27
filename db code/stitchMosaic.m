function [imOut,excluded] = stitchMosaic(ims, dims)
% Method 2 - stitch images left-to-right
% horizontal rows are stitched together with phase correlation.
% Rows are combined into the final image naively (using the same overlap amount, no alignment)
% excluded is a logical mask the same size as imOut, indicating all regions that are not covered.

% A sliver is arbitrarily chosen to be 300 pixels
sliverW = 300;

down = dims(1);
across = dims(2);

tileSize = size(ims{1});
progressbar('Aligning SEM and IRIS images:',[]);

for r = 1:down
	
	% stitch together the entire row
	thisRow = ims{(r-1)*across+1};
	sliverStartY = 1;
	for c = 1:(across-1)
		% Match the rightmost sliver of the first with the leftmost sliver of the next
		% Also remove the bottom gray sections from the slivers.
		idx = c + (r-1)*across;

		im1 = thisRow;
		im2 = ims{idx+1};
		leftSliver = im1(sliverStartY:(sliverStartY-1+tileSize(1)-240), (end-sliverW+1):end);
		rightSliver = im2(1:end-240, 1:sliverW);

		% vector difference between the slivers
		[delta, q] = phCorrAlign(leftSliver, rightSliver);
		% 	TODO - have a check so if the alignment is way off, it is reset.
		
		% vector difference between the full images
		deltaIm = delta + [sliverStartY-1 size(im1,2)-sliverW];

		% combine the images - translate the second image
		thisRow = zeros(ceil(tileSize + deltaIm));
		im2t = zeros(ceil(tileSize + deltaIm)); % used for translating the second image

		if deltaIm(1)>0
			% the second image is lower than the first
			im2t(1:tileSize(1), 1:tileSize(2)) = im2;
			thisRow = imtranslate(im2t,deltaIm);
			thisRow(1:size(im1,1), 1:size(im1,2)) = im1;
			sliverStartY = floor(deltaIm(1)+1);
		else
			% the second image is above the first
			x = -1* floor(deltaIm(1)); % how far down we need to start
			im2t(x:(x-1+tileSize(1)), 1:tileSize(2)) = im2;
			thisRow = imtranslate(im2t, deltaIm);
			thisRow(x:(x-1+size(im1,1)), 1:size(im1,2)) = im1;
			sliverStartY = 1;
		end
		
		progressbar([], c/(across-1));
	end
	% figure; imshow(thisRow,[]);

	if ~exist('imOut')
		imOut = thisRow;
	else
		% append this row to imOut

		% find out what the average overlap amount in pixels for this row was - it's the same for vertical and horizontal I hope!
		totalW = size(thisRow,2);
		overlapW = (across*tileSize(2)- totalW)/(across-1);
		% pct = overlapW/totalW;

		% Apply this overlap when stitching the rows - put lower rows on top of higher ones
		% The row has gotten a bit fatter itself, include that here as well
		% thisStart = floor((r-1)*tileSize(1)*(1-pct)+1) - (size(thisRow,1)-tileSize(1))
		thisStart = size(imOut,1)+1 - floor(overlapW) - (size(thisRow,1)-tileSize(1));

		% Center the new row below the old one
		compositeW = size(imOut,2);

		if totalW>=compositeW
			% We need to stretch the composite to fit the output
			offset = floor((totalW-compositeW)/2);
			
			% make a larger container
			temp = zeros(thisStart-1+size(thisRow,1),size(thisRow,2)); 
			temp(1:size(imOut,1), offset:(offset-1+size(imOut,2))) = imOut;
			temp(thisStart:end, :) = thisRow;
			clear imOut;
			imOut = temp;
		else
			% Center the output image to the composite
			offset = floor((compositeW-totalW)/2)+1;

			imOut(thisStart:(thisStart-1+size(thisRow,1)), offset:(offset-1+size(thisRow,2))) = thisRow;
		end		
	end
	progressbar(r/down, []);

	excluded = zeros(size(imOut));
	excluded(imOut==0) = 1;
	imOut(imOut==0) = median(imOut(:));
end