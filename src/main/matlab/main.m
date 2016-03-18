%
% BodyNets2013: A Computing-Efficient Algorithm for Accelerometer-Based Real-Time Activity Recognition Systems
% Copyright 2013 Pejman Ghorbanzade <mail@ghorbanzade.com>
% Released under the terms of MIT License
% https://github.com/ghorbanzade/bodynets2013/blob/master/LICENSE
%

%% INTRO

clear all; clc; close all;
for i = 2 : -1 : 1
    disp([...
    '-------------------------------------------------------------';...
    '  Accelerometer-Based Real-Time Activity Recognition System  ';...
    '  Wireless Sensor Networks Laboratory                        ';...
    '  K. N. Toosi University of Technology                       ';...
    '  (Copyrights) ghorbanzade [at] ieee [dot] org               ';...
    '-------------------------------------------------------------']);    
    fprintf('Program Begins in %d seconds...\n',i);
    pause(1);
    clc;
end

%% Selecting Program

List = ['Real-Time Activity Observation                                               ';
        'Real-Time Activity Recognition                                               ';
        'Evaluation: Real-Time Lab-Setting Dataset Acquistion                         ';
        'Evaluation: Accuracy Sweep for Different Elevation Divisions                 ';
        'Evaluation: Confusion Matrix                                                 ';
        'Model: Plot Fluctution of Regional Surfaces for Different Elevation Divisions';
        'Model: Plot Activity Code                                                    ';
        'Evaluation: Accuracy Sweep for Different Time Window Sizes                   ';
        'Number of Total Regions for Different Number of Elevation Divisions          ';
        'Model: Plot Raw Accelerometer Data                                           ';
        'Model: Plot 3D Representation                                                '];

while true
    fprintf('List of Available Programs:\n');
    for i = 1 : size(List,1)
        fprintf('\t%d. %s\n',i,List(i,:));
    end
    Select = input(sprintf('Please select your program [1 - %d] ',size(List,1)),'s');
    if ~isnan(str2double(Select))
        if le(str2double(Select),size(List,1)) && gt(str2double(Select),0)
            Select = round(str2double(Select));
            break
        end
    end
    clc;
    fprintf('Wrong Input\n');
end
clear i List

%% Program Execution

if lt(Select,10)
    run(sprintf('Sub/P25V0%d.m',Select));
elseif lt(Select,100)
    run(sprintf('Sub/P25V%d.m',Select));
end