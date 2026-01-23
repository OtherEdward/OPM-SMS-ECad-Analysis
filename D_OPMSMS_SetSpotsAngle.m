% OPM SMS ECAD Spot Junction Size and Position
% D set angle for each spot junction
clear variables; clc
close all

%% load data

% user select data file
[rPath, rFile] = openLastUsedFile('mat');

% load data
load([rPath, rFile], 'rotXYZdata', 'regionIDX', 'sjIDX')

%% get spot junction data

% get junction only data
junXYZdata = rotXYZdata(regionIDX == 4, :);

% get number of spot junctions
nSJs = max(sjIDX);

% reconstruction zoom
zoom = 10;

%% loop over spot junctions

% cell to hold XYZ points for each spot junction
sjData = cell(nSJs, 1);

% angle set by user for each spot junction
sjAngle = zeros(nSJs, 3);

% set window size
wSize = 300;

% set padding for image display
pxPad = 0.3;

for i = 1:nSJs

    fprintf(1, '%d of %d\n', i, nSJs);

    % logical for this spot junction
    thisSJ = sjIDX == i;

    % points for this spot junction
    sjPts = junXYZdata(thisSJ, 1:3);

    %----------------------------------------------------------------------
    % shift SJ points to center around zero
    
    % get min/max for this spot junction
    minSJ = min(sjPts, [], 1);
    maxSJ = max(sjPts, [], 1);

    % get center position for this junction
    xyzCenter = (minSJ + maxSJ)./2;

    % center spot junction
    sjPts = sjPts - xyzCenter;

    % figure
    % scatter3(sjPts(:, 1), sjPts(:, 2), sjPts(:, 3), '.')

    %----------------------------------------------------------------------
    % xy rotation

    [rXpts, rYpts, xyAngle] = smsRotateImage.getImageAngle(sjPts(:, 1:2), wSize, pxPad);

    % xy = smsReconstructImage(sjPts(:, 1:2), zoom, 1);
    % xyR = smsReconstructImage([rXpts, rYpts], zoom, 1);
    % 
    % figure; imagesc(xy); axis image; colormap gray
    % figure; imagesc(xyR); axis image; colormap gray

    % update values
    sjPts(:, 1) = rXpts;
    sjPts(:, 2) = rYpts;

    %----------------------------------------------------------------------
    % xz rotation

    [rZpts, rXpts, xzAngle] = smsRotateImage.getImageAngle([sjPts(:, 3), sjPts(:, 1)], wSize, pxPad);

    % xz = smsReconstructImage([sjPts(:, 3), sjPts(:, 1)], zoom, 1);
    % xzR = smsReconstructImage([rZpts, rXpts], zoom, 1);
    % 
    % figure; imagesc(xz); axis image; colormap gray
    % figure; imagesc(xzR); axis image; colormap gray

    % update values
    sjPts(:, 1) = rXpts;
    sjPts(:, 3) = rZpts;

    %----------------------------------------------------------------------
    % yz rotation

    [rZpts, rYpts, yzAngle] = smsRotateImage.getImageAngle([sjPts(:, 3), sjPts(:, 2)], wSize, pxPad);

    % yz = smsReconstructImage([sjPts(:, 3), sjPts(:, 2)], zoom, 1);
    % yzR = smsReconstructImage([rZpts, rYpts], zoom, 1);
    % 
    % figure; imagesc(yz); axis image; colormap gray
    % figure; imagesc(yzR); axis image; colormap gray

    % update values
    sjPts(:, 2) = rYpts;
    sjPts(:, 3) = rZpts;

    % store angles
    sjAngle(i, :) = [xyAngle, xzAngle, yzAngle];

    % store rotated points
    sjData{i} = sjPts;

    % hold on
    % scatter3(sjPts(:, 1), sjPts(:, 2), sjPts(:, 3), '.')
    % hold off
end

%% save data

save([rPath, rFile], 'sjData', 'sjAngle', '-append')

%% plot junctions

for i = 1:nSJs

    fprintf(1, '%d of %d\n', i, nSJs);

    % logical for this spot junction
    thisSJ = sjIDX == i;

    % points for this spot junction
    sjPts = junXYZdata(thisSJ, 1:3);

    % rotated points
    rSJpts = sjData{i};

    % setup layout
    t = tiledlayout(2, 2);

    nexttile
    plot(sjPts(:, 2), sjPts(:, 1), '.'); axis image

    nexttile
    xy = smsReconstructImage([sjPts(:, 1), sjPts(:, 2)], 10, 1);
    imagesc(flipud(xy)); axis image; colormap gray

    nexttile
    plot(rSJpts(:, 2), rSJpts(:, 1), '.'); axis image

    nexttile
    xy = smsReconstructImage([rSJpts(:, 1), rSJpts(:, 2)], 10, 1);
    imagesc(flipud(xy)); axis image; colormap gray

    pause
end