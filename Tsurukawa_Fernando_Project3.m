%% AUTHOR: FERNANDO KOITI TSURUKAWA R11670161
clc
clear
close all
% dname = uigetdir;
% dname = 'C:\Users\ferna\OneDrive - Texas Tech University\TTU\MATLAB\ImageProcessing\Project3\Photos-001';
dname = 'C:\Users\fetsuruk\OneDrive - Texas Tech University\TTU\MATLAB\ImageProcessing\Project3\Photos-001';
imds = imageDatastore(dname, 'ReadSize', 1);

%% EXTENSION CONDITIONAL CHECK
fileNames = imds.Files;

% CHECKING ONE OF THE FILES' FORMAT
[~,~,extension] = fileparts(fileNames{1}); 

% HAS TO BE .JPG FORMAT
if ( strcmp(extension,'.jpg') ~= 1)
    fprintf('Incompatible format\n')
    return
end

%% PROCESS IMAGES ONE AT A TIME
while hasdata(imds)
    im = read(imds);
    
    % MAKE IT GREYSCALE
    if(length(size(im)) > 2)
        imgrey = rgb2gray(im);
    end

    % CONVERTING IMAGE TO FLOAT VALUES RANGING IN [0,1]
    imgrey = double(imgrey) / 255;

    dimBlur = 10;
    h = ones(dimBlur, dimBlur) / dimBlur^2;
    imgrey = conv2(imgrey, h, 'valid'); % SIZE CHANGED HERE

    % MAKE IT BINARY
    threshold = 0.80;
    imBW = imbinarize(imgrey, threshold);

    % BROADENING THE GRADIENT EDGES
    dimBlur = 10;
    h = ones(dimBlur, dimBlur) / dimBlur^2;
    imBW = conv2(imBW, h, 'same');

    % FINDING GRADIENT
    [gradX, gradY] = gradient(imBW);
    gradPhase = atan2(gradY, gradX);

    [values, edges] = histcounts(gradPhase, 1000);

    [~,index] = max(values);

    while abs(edges(index)) < 0.05 
        [~,index] = max(values);
        values(index) = 0; % NULLIFYING THE FALSE MAX
    end

    [~,index] = max(values);

    theta = 1/2*(edges(index)+edges(index+1));
%     theta = theta*dimBlur^2;

    rot = [ cos(-theta) sin(-theta); ...
           -sin(-theta) cos(-theta) ];

    tform = rigid2d(rot, [0, 0]);
    imout = imwarp(im, tform);

    figure(1)
    imshow(imBW)

    figure(2)
    imshow(imout)

%     figure(2)
%     imshow(gradPhase);

%     figure(4)
%     histogram('BinEdges', edges*180/pi, 'BinCounts', values);
    
%     [resX_new, resY_new] = size(imout);
%     imoutBlur = conv2(imout, h, 'same');

%     imout = imcrop(imout,[yCrop_left xCrop_top yCrop_right - yCrop_left xCrop_bottom - xCrop_top]);

    pause
%     return % TODO REPLACE RETURN BY PAUSE FOR FINAL TESTING
end