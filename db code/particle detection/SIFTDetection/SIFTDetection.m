function [KPData]= SIFTDetection(InputIm, IntensityTh, EdgeTh, MatchFlag, ImScale)

%Upsample the image to enlargen the features:
UpInputIm=single(imresize(InputIm,ImScale,'bilinear'));
%Normalize the upsampled image
UpNormInputIm=UpInputIm-min(UpInputIm(:));
UpNormInputIm=255*UpNormInputIm./max(UpNormInputIm(:));


if MatchFlag==1
    [KPData.KPs,KPData.Feats] = vl_sift(UpNormInputIm, 'PeakThresh',IntensityTh,'EdgeThresh',EdgeTh);
else
    [KPData.KPs,~] = vl_sift(UpNormInputIm, 'PeakThresh',IntensityTh,'EdgeThresh',EdgeTh);
end

KPData.VKPs= ComputeVisualKeyPoints(KPData.KPs,ImScale, size(InputIm));
