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

% get spot junction only data
sjXYZdata = rotXYZdata(regionIDX == 4, :);

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
sjFitsResults = zeros(nSJs, 13);

% strcture with column type
sjC.amp1 = 1;
sjC.amp2 = 2;
sjC.x1 = 3;
sjC.y1 = 4;
sjC.x2 = 5;
sjC.y2 = 6;
sjC.p1wX = 7;
sjC.p1wY = 8;
sjC.p2wX = 9;
sjC.p2wY = 10;
sjC.offset = 11;
sjC.badFit = 12;
sjC.meanZ = 13;

for i = 1:nSJs

    fprintf(1, '%d of %d\n', i, nSJs);

    %----------------------------------------------------------------------
    % get raw SJ data

    % logical for this spot junction
    thisSJ = sjIDX == i;

    % points for this spot junction
    sjPts = sjXYZdata(thisSJ, 1:3);

    % average z position of this junction
    sjFitsResults(i, sjC.meanZ) = mean(sjPts(:, 3));

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
    sjFitsResults(i, 1:11) = fitR;
    
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

    answer = questdlg('Is the fit result good?', 'Fit Result', 'Yes','No','Yes');

    switch answer
        case 'Yes'
            sjFitsResults(i, sjC.badFit) = false;
        case 'No'
            sjFitsResults(i, sjC.badFit) = true;
    end

end

clear i t xG yG fitIM fitR xyMesh b0

%% get spacing and position data

% range for getting junction z position
thetaRange = 3*pi/180;

% mean z position vs spacing from fit
sjSZdata = zeros(nSJs, 3);

% get junction only data
junXYZdata = rotXYZdata(regionIDX == 3, :);

% convert junction data to polar
[jTheta, jRho, jZ] = cart2pol(junXYZdata(:, 1), junXYZdata(:, 2), junXYZdata(:, 3));

for i = 1:nSJs

    if sjFitsResults(i, sjC.badFit)
        % do nothing
    else

        %------------------------------------------------------------------
        % raw sj xyz data

        % logical for this spot junction
        thisSJ = sjIDX == i;

        % points for this spot junction
        sjPts = sjXYZdata(thisSJ, 1:3);

        % convert to polar
        [sjTheta, ~, ~] = cart2pol(sjPts(:, 1), sjPts(:, 2), sjPts(:, 3));

        % get the average theta for this spot junction
        meanSJtheta = mean(sjTheta);

        %------------------------------------------------------------------
        % junction data

        % get index for points in the theta range
        jIDX = jTheta <= meanSJtheta + thetaRange & jTheta >= meanSJtheta - thetaRange;

        % get xyz data for function in this theta range
        jAbove = junXYZdata(jIDX, :);

        %------------------------------------------------------------------
        % get relative spot junction z position

        rZ = abs(mean(jAbove(:, 3)) - mean(sjPts(:, 3)));

        fprintf(1, '%.2f\n', rZ);

        %------------------------------------------------------------------
        % spot junction fit data

        % get and store the average absolute z position for this spot junction
        sjSZdata(i, 1) = sjFitsResults(i, sjC.meanZ);

        % store relative z position
        sjSZdata(i, 2) = rZ;

        % get and store the separation between spot junctions
        sjSZdata(i, 3) = abs(sjFitsResults(i, sjC.x1) - sjFitsResults(i, sjC.x2));

        %------------------------------------------------------------------
        % plot data

        scatter3(junXYZdata(:, 1), junXYZdata(:, 2), junXYZdata(:, 3), '.')
        axis image
        hold on
        scatter3(jAbove(:, 1), jAbove(:, 2), jAbove(:, 3), '.')
        scatter3(sjPts(:, 1), sjPts(:, 2), sjPts(:, 3), '.')
        hold off
        view(0, 0)

        pause
    end

end

%% save results

save([rPath, rFile], 'sjFitsResults', 'sjSZdata', 'sjC', '-append')