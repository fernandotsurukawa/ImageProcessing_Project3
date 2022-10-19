%% AUTHOR: FERNANDO KOITI TSURUKAWA R11670161
clc
clear
close all
dname = uigetdir;
% INPUT THE CORRECT DIRECTORY WITH THE CARDS HERE
% dname = 'C:\Users\fetsuruk\OneDrive - Texas Tech University\TTU\MATLAB\ImageProcessing\Project3\Photos-002';
imds = imageDatastore(dname, 'ReadSize', 1);
load('net_rank.mat')
load('net_suit.mat')

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
    
    % MAKE INPUT IMAGE GREYSCALE
    if(length(size(im)) > 2)
        imgrey = rgb2gray(im);
    end

    % CONVERTING IMAGE TO FLOAT VALUES RANGING IN [0,1]
    [resX, resY] = size(imgrey);
    imgrey = double(imgrey) / 255;

    % GETTING RID OF BACKGROUND NOISE
    dimBlur = 10;
    h = ones(dimBlur, dimBlur) / dimBlur^2;
    imBlur = conv2(imgrey, h, 'same');

    % THRESHOLD
%     threshold = graythresh(imBlur);
    threshold = 0.80; % 0.8 works for training images, but it's too high 
%                                                          for test images

    % SWEEPING THE IMAGE DOWNWARDS
    for i = 1 : resX 
        if max( imBlur(i,:) ) > threshold
            xCorner1 = i;
            [~, yCorner1] = max( imBlur(i,:) );
            break
        end
    end

    % SWEEPING THE IMAGE UPWARDS
    for i = resX : -1 : 1 
        if max( imBlur(i,:) ) > threshold
            xCorner3 = i;
            [~, yCorner3] = max( imBlur(i,:) );
            break
        end
    end

    % SWEEPING THE IMAGE LEFT TO RIGHT
    for j = 1 : resY 
        if max( imBlur(:,j) ) > threshold
            [~, xCorner4] = max( imBlur(:,j) );
            yCorner4 = j;
            break
        end
    end

    % SWEEPING THE IMAGE RIGHT TO LEFT
    for j = resY : -1 : 1 
        if max( imBlur(:,j) ) > threshold
            [~, xCorner2] = max( imBlur(:,j) );
            yCorner2 = j;
            break
        end
    end

    % PLACING CORNER1 ON TOP LEFT OF THE CARD
    length1 = sqrt((xCorner1-xCorner2)^2 + (yCorner1-yCorner2)^2);
    length2 = sqrt((xCorner1-xCorner4)^2 + (yCorner1-yCorner4)^2);

    if length1 > length2
        xtemp = xCorner1;
        ytemp = yCorner1;

        xCorner1 = xCorner2;
        yCorner1 = yCorner2;

        xCorner2 = xCorner3;
        yCorner2 = yCorner3;

        xCorner3 = xCorner4;
        yCorner3 = yCorner4;

        xCorner4 = xtemp;
        yCorner4 = ytemp;
    end
    
    % CALCULATING THE ANGLE OF ROTATION
    theta = atan2(xCorner2 - xCorner1, yCorner2 - yCorner1);

    % EMPIRICAL FACTOR USED TO CORRECT THE ANGLE
    factor = 1.08;
    if  (0 < theta) && (theta < pi/2)
        theta = pi/4 + factor * (theta - pi/4);
    elseif (pi/2 < theta) && (theta < pi)
        theta = 3*pi/4 + factor * (theta - 3*pi/4);
    end

    rot = [   cos(-theta) sin(-theta); ...
             -sin(-theta) cos(-theta)];

    tform = rigid2d(rot, [0, 0]);
    imout = imwarp(imgrey, tform);

    [resX_new, resY_new] = size(imout);
    imoutBlur = conv2(imout, h, 'same');

    for i = 1 : resX_new
        if max( imoutBlur(i,:) ) > threshold
            xCrop_top = i;
            break
        end
    end

    for i = resX_new : -1 : 1
        if max( imoutBlur(i,:) ) > threshold
            xCrop_bottom = i;
            break
        end
    end

    for j = 1 : resY_new
        if max( imoutBlur(:,j) ) > threshold
            yCrop_left = j;
            break
        end
    end

    for j = resY_new : -1 : 1
        if max( imoutBlur(:,j) ) > threshold
            yCrop_right = j;
            break
        end
    end

    imout = imcrop(imwarp(im, tform),[yCrop_left xCrop_top yCrop_right - yCrop_left xCrop_bottom - xCrop_top]);

    [resX_out, resY_out, ~] = size(imout);

    % EMPIRICAL COORDINATES THAT INDICATE ROUGHLY POSITION OF RANK AND SUIT
    xRank_top = 51 / 1251 * resX_out;
    yRank_left = 31 / 890 * resY_out;
    xRank_bottom = 208 / 1251 * resX_out;
    yRank_right = 163 / 890 * resY_out;
    imRank = imcrop(imout,[yRank_left xRank_top yRank_right - yRank_left xRank_bottom - xRank_top]);

    xSuit_top = 208 / 1251 * resX_out;
    ySuit_left = 31 / 890 * resY_out;
    xSuit_bottom = 337 / 1251 * resX_out;
    ySuit_right = 163 / 890 * resY_out;
    imSuit = imcrop(imout,[ySuit_left xSuit_top ySuit_right - ySuit_left xSuit_bottom - xSuit_top]);

    rank = classify(net_rank, rgb2gray(imresize(imRank, [50 50])));
    suit = classify(net_suit, rgb2gray(imresize(imSuit, [50 50])));

    rank = char(rank);
    suit = char(suit);

%     figure1 = figure(1);
%     imshow(im)
    figure(1)
    imshow(im)
    hold on
    plot(yCorner1, xCorner1, 'x', 'LineWidth', 3)
    plot(yCorner2, xCorner2, 'x', 'LineWidth', 3)
    plot(yCorner3, xCorner3, 'x', 'LineWidth', 3)
    plot(yCorner4, xCorner4, 'x', 'LineWidth', 3)
    legend('Corner1', 'Corner2', 'Corner3', 'Corner4')
    hold off

    figure(2)
    imshow(imRank)
    title(strcat('Predicted rank: ', rank))

    figure(3)
    imshow(imSuit)
    title(strcat('Predicted suit: ', suit))

    pause
end

%% CODE USED TO DISPLAY CORNERS OF THE CARDS


%% CODE USED TO GENERATE TRAINING DATA
% datacount = 1;
%     filenameRank = strcat('rank', int2str(datacount),'.png');
%     imwrite(imRank, filenameRank);
%     filenameSuit = strcat('suit', int2str(datacount),'.png');
%     imwrite(imSuit, filenameSuit);

%     datacount = datacount + 1;
%     pause