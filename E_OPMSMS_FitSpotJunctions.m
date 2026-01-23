% OPM SMS ECAD Spot Junction Size and Position
% E fit each spot junction and find its relative z position
clear variables; clc
close all

%% load data

% user select data file
[rPath, rFile] = openLastUsedFile('mat');

% load data
load([rPath, rFile], 'rotXYZdata', 'regionIDX', 'sjIDX', 'sjData')

%% get spot junction data

% get junction only data
junXYZdata = rotXYZdata(regionIDX == 4, :);

% get number of spot junctions
nSJs = size(sjData, 1);

% reconstruction zoom
zoom = 10;

% padding for reconstructed image
pxPad = 0.3;

%%

% window to show results
tiledlayout(1, 2)

% array to store fit results
sjFitsResults = zeros(nSJs, 11);

for i = 1:nSJs

    fprintf(1, '%d of %d\n', i, nSJs);

    %----------------------------------------------------------------------
    % get raw SJ data

    % logical for this spot junction
    thisSJ = sjIDX == i;

    % points for this spot junction
    sjPts = junXYZdata(thisSJ, 1:3);

    % average z position of this junction
    sjMeanZ = mean(sjPts(:, 3));

    %----------------------------------------------------------------------
    % get image data and setup for fitting

    % get rotated points a spot junction
    thisSJ = sjData{i};

    % setup minmax array for reconstruction
    xMin = min(thisSJ(:, 1)) - pxPad;
    xMax = max(thisSJ(:, 1)) + pxPad;
    yMin = min(thisSJ(:, 2)) - pxPad;
    yMax = max(thisSJ(:, 2)) + pxPad;
    minMax = [xMin, xMax, yMin, yMax];

    % make image for fitting
    xy = smsReconstructImage(thisSJ(:, 1:2), zoom, 1, minMax);

    % user inital guess for peak locations
    [xG, yG] = userSelectPts(xy);

    % setup initial guess array
    b0 = [3, 3, xG(1), yG(1), xG(2), yG(2), 2, 5, 2, 5, 0];

    % fit data
    [fitR, xyMesh] = fitGaussian_2D2PeakSigmaXY(xy, b0);

    % store fit results
    sjFitsResults(i, :) = fitR;
    
    % make fit image
    fitIM = Gaussian_2D2PeakSigmaXY(fitR, xyMesh);

    % plot data with center selections
    nexttile(1)
    imagesc(xy); axis image; colormap gray
    hold on
    plot(yG, xG, 'r.')
    hold off

    % plot fit image
    nexttile(2)
    imagesc(fitIM); axis image; colormap gray

end

clear i t xG yG fitIM fitR xyMesh b0