% OPM SMS ECAD Spot Junction Size and Position
% B select spot junctions
clear variables; clc
close all

%% load data

% user select data file
[rPath, rFile] = openLastUsedFile('mat');

% load data
load([rPath, rFile], 'rotXYZdata', 'regionIDX', 'zStep', 'zHeight')

%% get spot junction data

junXYZdata = rotXYZdata(regionIDX == 4, :);

ptsMin = min(junXYZdata(:, 1:3), [], 1);
ptsMax = max(junXYZdata(:, 1:3), [], 1);

%% set parameters

% set z step size in pixel units
if ~exist('zStep', 'var')
    zStep = 200/116.9;
end

% set z thickness in pixels
if ~exist('zHeight', 'var')
    zHeight = 300/116.9;
end

% get z range
zRange = ptsMax(3) - ptsMin(3);

% num z steps
nzSteps = ceil(zRange/zStep);

% set image zoom
zoom = 10;

%% setup stack

% get min/max values for reconstruction
[~, ~, ~, minMaxArray, ~] = smsReconstructImage(junXYZdata, zoom, 1);

%% make image stack

% set starting z value for stack
zLower = ptsMin(3);

sjMarked = [];

h = figure('Color', [1, 1, 1]);
axes
g = figure('Color', [1, 1, 1]);
axes

for i = 1:nzSteps

    fprintf(1, '%d of %d\n', i, nzSteps);

    % set upper z limit
    zUpper = zLower + zHeight;

    % get index for points in this step
    inStep = junXYZdata(:, 3) < zUpper & junXYZdata(:, 3) >= zLower;

    if sum(inStep) > 0

        % reconstruct this z step
        stepImage = smsReconstructImage(junXYZdata(inStep, :), zoom, 1, minMaxArray);

        % display this z step
        imagesc(h.Children, stepImage); axis image
        colormap(h.Children, 'gray');
        clim([0, 3])

        % set active figure
        figure(h)

        % user select points
        [x, y] = userSelectPtsCurIMG();

        % get number of selection points
        nPts = size(x, 1);

        if nPts > 0

            % convert to camera pixels
            x = (x./zoom) + ptsMin(1);
            y = (y./zoom) + ptsMin(2);
            z = (zLower + (zHeight/2));

            % plot
            plot(g.Children, junXYZdata(inStep, 2), junXYZdata(inStep, 1), '.')
            hold(g.Children, 'on')
            plot(g.Children, y, x, '.', 'MarkerSize', 20)
            hold(g.Children, 'off')
            axis(g.Children, 'image')
            xlim(g.Children, [ptsMin(2), ptsMax(2)])
            ylim(g.Children, [ptsMin(1), ptsMax(1)])

            % setup array with current z position
            zs = z.*ones(nPts, 1);

            sjMarked = [sjMarked; [x, y, zs]];

        end
    end

    % update lower z bound
    zLower = zLower + zStep;

end

close all
clear inStep stepImage x y zs i g h z zLower zUpper zRange nPts

%% plot result

scatter3(junXYZdata(:, 1), junXYZdata(:, 2), junXYZdata(:, 3), '.'); axis image
hold on
scatter3(sjMarked(:, 1), sjMarked(:, 2), sjMarked(:, 3), 1000, 'r.')
hold off

%% check for close points

% get number of marked points
nPts = size(sjMarked, 1);

% check for clusters of points.
dbIdx = dbscan(sjMarked, 1.4*zStep, 2);

% get logical for all uncluster points
ltZ = dbIdx < 0;

% update to start at 1
dbIdx(ltZ) = dbIdx(ltZ) + 2;
dbIdx(~ltZ) = dbIdx(~ltZ) + 1;

% get max cluster
mxDB = max(dbIdx);

% make db color array base
cArray = rand(mxDB, 3);

% make full color array
cA = zeros(nPts, 3);
for i = 1:nPts
    cA(i, :) = cArray(dbIdx(i), :);
end

% plot points colored by cluster
scatter3(sjMarked(:, 1), sjMarked(:, 2), sjMarked(:, 3), 100, cA, 'filled')
axis image
hold on

% array for consolidated points
cPts = sjMarked(ltZ, :);

% loop for clustered points
for i = 2:mxDB

    cPts = [cPts; mean(sjMarked(dbIdx == i, :), 1)];

end

scatter3(cPts(:, 1), cPts(:, 2), cPts(:, 3), 100, 'b.')
hold off

% overwrite the sjMarked positions
sjMarked = cPts;

clear cPts cA cArray i nPts ltZ mxDB cIdx dbIdx nPts

%% save data

save([rPath, rFile], 'sjMarked', 'zHeight', 'zStep', '-append')