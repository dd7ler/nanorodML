function KPData = getParticles(I, IntensityTh, EdgeTh)

ImScale = 4;
MatchFlag = 0;

KPData = SIFTDetection(I, IntensityTh, EdgeTh, MatchFlag, ImScale);
KPData.Peaks=I(sub2ind(size(I), round(KPData.VKPs(2,:).'), round(KPData.VKPs(1,:).')));
end