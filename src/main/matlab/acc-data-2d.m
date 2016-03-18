clear Select

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

load('Acts.mat');
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

cd('Databases');
load(sprintf('%s%s001.mat',ACT,LOC));
DB = DB/100;
plot(DB,'LineWidth',1.5)
grid on
xlabel('Packet Number')
ylabel('Raw Accelerometer Data (m/s^2)');
legend('X-Axis','Y-Axis','Z-Axis');
axis([100 180,-11 11]);