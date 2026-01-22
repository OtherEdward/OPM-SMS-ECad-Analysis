% OPM SMS ECAD Spot Junction Size and Position
% C crop out spot junctions and align
clear variables; clc
close all

%% load data

% user select data file
[rPath, rFile] = openLastUsedFile('mat');

% load data
load([rPath, rFile], 'rotXYZdata', 'regionIDX', 'sjMarked')

%% get spot junction data

% get junction only data
junXYZdata = rotXYZdata(regionIDX == 4, :);

% get number of junction points
jPts = size(junXYZdata, 1);

% juntion index array
sjIDX = zeros(jPts, 1);

% tracking index for point locations
sjTrack = (1:jPts).';

%% crop data around marked positions

% get number of marked locations
nPts = size(sjMarked, 1);

% set crop distance
rCut = 3;

for i = 1:nPts

    fprintf(1, '%d of %d\n', i, nPts);

    % get distance to all points
    rD = sqrt(sum((sjMarked(i, :) - junXYZdata).^2, 2));

    % logical points within distance
    inR = rD <= rCut;

    % get points in the current junction
    curSJ = junXYZdata(inR, 1:3);
    curTrack = sjTrack(inR);

    % 3D crop junction
    thisSJ = sms3Droi(curSJ, 'freehand');

    % get index for points in this spot junction
    sjPts = curTrack(thisSJ);

    % set array values for this spot junction
    sjIDX(sjPts) = i;

end

clear rD inR curSJ curTrack thisSJ sjPts i

%% show each junction

for i = 1:nPts

    thisSJ = sjIDX == i;

    imagesc(smsReconstructImage(junXYZdata(thisSJ, :), 10, 1)); axis image
    colormap gray

    pause
end

%% plot each junction

% ROI distance
rCut = 3;

for i = 1:nPts

    fprintf(1, '%d of %d\n', i, nPts);

    % get logical for points in this junction
    thisSJ = sjIDX == i;

    % get points in this junction
    thisSJpts = junXYZdata(thisSJ, 1:3);

    % get average position
    mP = mean(thisSJpts(:, 1:3), 1);

    % get logical points within z range
    inR = all(junXYZdata >= mP - rCut & junXYZdata <= mP + rCut, 2);

    scatter3(junXYZdata(inR, 1), junXYZdata(inR, 2), junXYZdata(inR, 3), '.')
    axis image
    hold on
    scatter3(thisSJpts(:, 1), thisSJpts(:, 2), thisSJpts(:, 3), 100, 'r.')
    hold off

    pause
end

%% save spot junction index

save([rPath, rFile], 'sjIDX', '-append')