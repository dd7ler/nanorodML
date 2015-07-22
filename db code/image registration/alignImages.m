% Calculates alignment displacement and angle. Performs a number of
% rotations to the base image, then calls phCorrAlign to do fast phase
% correlation alignment of the rotated image to the base image.

function [delta_out, theta_out, composite_out, qList] = alignImages(I1, I2, theta)
% I1 and I2 are the images to be aligned. theta is all of
% angles to test. Time to execute increases as the resolution of theta
% increases and the size of the images increases. I1 and I2 must be the
% same size.

% Get the middle sections of the two images, and align those

I1crop = cropPow2(I1);
m = median(I2(:));
q_best=0;
qList = zeros(1,length(theta));
for t = 1:length(theta)
    I2r = imrotate(I2,theta(t),'crop'); % Rotate the second image
    I2r = cropPow2(I2r);
    [delta,q] = phCorrAlign(I1crop,I2r); % align the rotated image to the first
    qList(t) = q;
    % I2_aligned = imtranslate(I2r,delta);    % Create composite image
    % composite = (double(I1crop) + double(I2_aligned)) /2; 
    % imwrite(uint8(255*(composite-min(composite(:)))./range(composite(:))), ['alignment image number ' num2str(t) '.jpeg'],'jpeg');
    if q > q_best % then is the best rotation so far.
%         imwrite(uint8(255*(composite-min(composite(:)))./range(composite(:))), ['aligned composite' num2str(t) '.jpeg'],'jpeg');
        delta_out = delta;
        theta_out = theta(t);
        q_best = q;
    end
    progressbar([],t/length(theta));
end
I2r = imrotate(I2,theta_out,'crop');
I2r(I2r == 0) = median(I2(:));
I2_aligned = imtranslate(I2r,delta_out);

% Create composite image
composite_out = (double(I1) + double(I2_aligned)) /2; 

composite_out(composite_out<.7*m) = m;