% OPM SMS ECAD Spot Junction Size and Position
clear variables; clc
close all

%% load data

% user select data file
[rPath, rFile] = openLastUsedFile('mat');

% load data
load([rPath, rFile], 'rotXYZdata', 'regionIDX')

%% get spot junction data

junXYZdata = rotXYZdata(regionIDX == 4, :);

ptsMin = min(junXYZdata(:, 1:3), [], 1);
ptsMax = max(junXYZdata(:, 1:3), [], 1);

%% set parameters

% set z step size in pixel units
zStep = 200/116.9;

% set z thickness in pixels
zHeight = 300/116.9;

% get z range
zRange = ptsMax(3) - ptsMin(3);

% num z steps
nzSteps = ceil(zRange/zStep);

zoom = 10;

%% setup stack

% make 2D image
[srImage, ~, ~, minMaxArray, ~] = smsReconstructImage(junXYZdata, zoom, 1);

% make zeros stack
% srStack = zeros(size(srImage, 1), size(srImage, 2), nzSteps);

clear srImage

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
        % set(0, 'CurrentFigure', h)
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
            zs = (zLower + (zHeight/2)).*ones(nPts, 1);

            sjMarked = [sjMarked; [x, y, zs]];

        end
    end

    % update lower z bound
    zLower = zLower + zStep;

end

close all
clear inStep stepImage x y zs i g h z zLower zUpper zStep zRange zHeight nPts

%% plot result

scatter3(junXYZdata(:, 1), junXYZdata(:, 2), junXYZdata(:, 3), '.'); axis image
hold on
scatter3(sjMarked(:, 1), sjMarked(:, 2), sjMarked(:, 3), 1000, 'r.')
hold off

%% check for close points

% get number of marked points
nPts = size(sjMarked, 1);

% get distance between all points
sjDis = pdist(sjMarked);