clear Select;
clc;

%%

cd('../Files');
LOCS = ls;
LOCS(1:2,:) =[];
for i = size(LOCS,1) : -1 : 1
    if ~isdir(LOCS(i,:))
        LOCS(i,:) = [];
    end
end
while true    
    for i = 1 : size(LOCS,1)
        fprintf('%2d. %s\n',i,LOCS(i,:));
    end
    Select = input(sprintf('Sensor Location? [1 -%2d] ',size(LOCS,1)),'s');
    clc;
    if size(Select,2) == 1 
        if ~isnan(str2double(Select)) && le(str2double(Select),size(LOCS,1))
            LOC = LOCS(str2double(Select),:);
            while LOC(size(LOC,2)) == ' '
                LOC(size(LOC,2)) = [];
            end
            cd(LOC);
            break
        end
    else
        fprintf('Wrong Input.\n');
    end
end %get LOC
clear LOCS;

%%

ACTS = load('Acts.mat','ACTS');
ACTS = ACTS.ACTS;
while true
    for i = 1 : size(ACTS,1)
        fprintf('%2d. %s\n',i,ACTS(i,:));
    end
    Select = input(sprintf('What is the activity? [1 -%2d] ',size(ACTS,1)),'s');
    clc;
    if ~isnan(str2double(Select))
        if le(str2double(Select),size(ACTS,1)) && gt(str2double(Select),0)

            ACT = ACTS(str2double(Select),:);
            while ACT(size(ACT,2)) == ' '
                ACT(size(ACT,2)) = [];
            end
            break
        end
    else
        fprintf('Wrong Input.\n');
    end
end
while ACT(size(ACT,2)) == ' '
    ACT(size(ACT,2)) = [];
end
clear ACTS

%%

load('Acts.mat');
cd('Databases');
load(sprintf('%s%s001.mat',ACT,LOC));
cd('../../../');

SNS = 100;
DB = round(DB/SNS)*SNS/100;

scatter3(DB(:,1),DB(:,2),DB(:,3),'b')

grid on
axis([-10 10,-10 10,-10 10]);
xlabel('X-Axis');
ylabel('Y-Axis');
zlabel('Z-Axis');
title({'Raw Accelerometer Data';sprintf('Activity: %s',ACT);sprintf('Sensor Attached to %s',LOC')})
legend(sprintf('%s',ACT));