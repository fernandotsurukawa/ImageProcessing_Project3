dname = 'C:\Users\fetsuruk\OneDrive - Texas Tech University\TTU\MATLAB\ImageProcessing\Project3\ranks';
imds = imageDatastore(dname, ...
    'IncludeSubfolders',true, ...
    'LabelSource','foldernames', ...
    "ReadFcn",@customreader ...
    );

%% LAYERS
layers = [
    imageInputLayer([50 50 1])
    
    convolution2dLayer(3,8,'Padding','same')
    batchNormalizationLayer
    reluLayer
    
    maxPooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(3,16,'Padding','same')
    batchNormalizationLayer
    reluLayer
    
    maxPooling2dLayer(2,'Stride',2)
    
    convolution2dLayer(3,32,'Padding','same')
    batchNormalizationLayer
    reluLayer
    
    fullyConnectedLayer(13)
    softmaxLayer
    classificationLayer
    ];

%% OPTIONS
options = trainingOptions( ...
    'sgdm', ...
    'InitialLearnRate', 0.001, ...
    'MaxEpochs', 10, ...
    'Shuffle','every-epoch', ...
    'Verbose',false, ...
    'Plots','training-progress' ...
    );

%% TRAINING
net_rank = trainNetwork(imds,layers,options);

%% STORING THE NETWORK
save('net_rank.mat', 'net_rank');
