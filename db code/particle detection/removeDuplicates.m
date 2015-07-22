function redundants = removeDuplicates(xy, dist)

[~,~,clustMembsCell] = MeanShiftCluster(xy,dist);
dups = cellfun(@length, clustMembsCell);
rCell = clustMembsCell(dups~=1);
redundCell= cellfun(@(x) x(2:end), rCell, 'UniformOutput', false);
redundants = cell2mat(redundCell');