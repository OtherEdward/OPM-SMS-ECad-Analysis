% OPM SMS ECAD Spot Junction Size and Position
% A rotate cell data for selection
clear variables; clc
close all

%% load data

% user select data file
[rPath, rFile] = openLastUsedFile('mat');

% load data
load([rPath, rFile])

%% move to center

% get min/max values for (x, y, z) coordinates
xyzMax = max(cellXYZdata(:, 1:3), [], 1);
xyzMin = min(cellXYZdata(:, 1:3), [], 1);

% get center positions
xyzCenter = (xyzMax + xyzMin)/2;

% move to origin
rotXYZdata = cellXYZdata(:, 1:3) - xyzCenter;

%% get xz angle

% make images
xzImage = flipud(smsReconstructImage([rotXYZdata(:, 3), rotXYZdata(:, 1)], 10, 1));

% user draw line
[xzLine, ~] = userROIs.getROIs(xzImage, 'line');

% get angle
xzAngle = atan(abs(xzLine{1, 1}.Position(1, 1) - xzLine{1, 1}.Position(2, 1))/abs(xzLine{1, 1}.Position(1, 2) - xzLine{1, 1}.Position(2, 2)));

%% rotate xz data

% convert to polar
[theta, rho] = cart2pol(rotXYZdata(:, 1), rotXYZdata(:, 3));

% adjust angle
theta = theta + xzAngle;

% convert back to XZ
[x, z] = pol2cart(theta, rho);

% update values
rotXYZdata(:, 1) = x;
rotXYZdata(:, 3) = z;

% imagesc(flipud(smsReconstructImage([z, x], 10, 1)))

%% get yz angle

% make images
yzImage = flipud(smsReconstructImage([rotXYZdata(:, 3), rotXYZdata(:, 2)], 10, 1));

% user draw line
[yzLine, ~] = userROIs.getROIs(yzImage, 'line');

% get angles
yzAngle = atan(abs(yzLine{1, 1}.Position(1, 1) - yzLine{1, 1}.Position(2, 1))/abs(yzLine{1, 1}.Position(1, 2) - yzLine{1, 1}.Position(2, 2)));

%% rotate yz data

% convert to polar
[theta, rho] = cart2pol(rotXYZdata(:, 2), rotXYZdata(:, 3));

% adjust angle
theta = theta + yzAngle;

% convert back to XZ
[y, z] = pol2cart(theta, rho);

% update values
rotXYZdata(:, 2) = y;
rotXYZdata(:, 3) = z;

% imagesc(flipud(smsReconstructImage([z, y], 10, 1)))

%% show results

scatter3(cellXYZdata(:, 1), cellXYZdata(:, 2), cellXYZdata(:, 3), '.'); axis image
view(90, 0)

figure
scatter3(rotXYZdata(:, 1), rotXYZdata(:, 2), rotXYZdata(:, 3), '.'); axis image
view(90, 0)

%% save results

save([rPath, rFile], 'xzAngle', 'yzAngle', 'rotXYZdata', '-append')

%% clean up

clear rho theta x y z xzLine yzLine xzImage yzImage xyzMin xyzMax xyzCenter