function ParticleContrasts= ComputeContrast(frame, PeakValues, peakLocations, innerRadius, outerRadius)
% PARTICLECONTRASTS determine particle local contrasts
% 
% ParticleContrasts= ComputeContrast(frame, PeakValues, peakLocations, innerRadius, outerRadius)

medianVals = zeros(size(PeakValues));

for k = 1:size(peakLocations,1)
	xy = round(peakLocations(k,:));
	x0 = xy(1) - outerRadius; if x0 < 1, x0 = 1; end;
	x1 = xy(1) + outerRadius; if x1 > size(frame,2), x1 = size(frame,2); end;
	y0 = xy(2) - outerRadius; if y0 < 1, y0 = 1; end;
	y1 = xy(2) + outerRadius; if y1 > size(frame,1), y1 = size(frame,1); end;
	region = frame(y0:y1, x0:x1);
    [xx,yy] = meshgrid(x0:x1, y0:y1);
    mask = ~(sqrt((xx-xy(1)).^2+(yy-xy(2)).^2)>=outerRadius | sqrt((xx-xy(1)).^2+(yy-xy(2)).^2)<=innerRadius);
    medianVals(k)= median(region(mask));
end
ParticleContrasts = double(PeakValues)./medianVals;