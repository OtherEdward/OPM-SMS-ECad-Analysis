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

%% set parameters

% set z step size in pixel units
zStep = 100/116.9;

% set z thickness in pixels
zHeight = 300/116.9;

% get z range
zRange = max(junXYZdata(:, 3)) - min(junXYZdata(:, 3));

% num z steps
nzSteps = ceil(zRange/zStep);

%% z loop

zLower = min(junXYZdata(:, 3));

for i = 1:nzSteps

    fprintf(1, '%d of %d\n', i, nzSteps);

    % set upper z limit
    zUpper = zLower + zHeight;

    % get index for points in this step
    inStep = junXYZdata(:, 3) < zUpper & junXYZdata(:, 3) >= zLower;

    if sum(inStep) > 0

        % get xy and index data for this step
        thisStep = junXYZdata(inStep, :);

        imagesc(smsReconstructImage(thisStep, 10, 1))
        axis image
        colormap gray
        clim([0, 5])

        zLower = zLower + zStep;

        pause(0.2)

    end

end