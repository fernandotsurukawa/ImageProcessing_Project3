function data = customreader(filename)
    % code from default function: 
    onState = warning('off', 'backtrace'); 
    c = onCleanup(@() warning(onState)); 
    data = imread(filename);
    % added lines: 
    data = rgb2gray(data);
    data = imresize(data, [50 50]);
end