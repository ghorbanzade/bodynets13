clear Select;
clc;
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
    fprintf(' 0. New Activity\n');
    for i = 1 : size(ACTS,1)
        fprintf('%2d. %s\n',i,ACTS(i,:));
    end
    Select = input(sprintf('What is the activity? [0 -%2d] ',size(ACTS,1)),'s');
    clc;
    if size(Select,2) == 1
        if Select == '0'
            NewAct = true;
            break
        end
    end
    if ~isnan(str2double(Select)) && le(str2double(Select),size(ACTS,1))
        NewAct = false;
        ACT = ACTS(str2double(Select),:);
        while ACT(size(ACT,2)) == ' '
            ACT(size(ACT,2)) = [];
        end
        break
    else
        fprintf('Wrong Input.\n');
    end
end
if NewAct
    while true
        ACT = input('Name of New Activity? ','s');
        clc;
        while ACT(size(ACT,2)) == ' '
            ACT(size(ACT,2)) = [];
        end
        if gt(size(ACT,2),2) && le(size(ACT,2),10)
            for i = 1 : size(ACT,2)
                if ACT(i) == ' '
                    NewAct = false;
                end
            end
            if NewAct
                while lt(size(ACT,2),10)
                    ACT(size(ACT,2)+1) = ' ';
                end
                load('Acts.mat','ACTS');
                ACTS(size(ACTS,1)+1,:) = ACT;
                save('Acts.mat','ACTS');
                break
            end
        end
        fprintf('Wrong Input.\n');
    end
    while ACT(size(ACT,2)) == ' '
        ACT(size(ACT,2)) = [];
    end        
end
clear ACTS NewAct;

cd('Experiment');
j = 1;
file = sprintf('%s%s',ACT,LOC);
temp = ls;
temp(1:2,:) = [];
if size(temp,1) ~= 0 && ge(size(temp,1),size(file,1))
    for i = 1 : size(temp,1)
        if ~isdir(temp(i,:))
            if strcmp(temp(i,1:size(file,2)),file)
                j = j+1;
            end
        end
    end
end
if lt(j,10)
    file = sprintf('%s00%d.mat',file,j);
elseif lt(j,100)
    file = sprintf('%s0%d.mat',file,j);
elseif lt(j,1000)
    file = sprintf('%s%d.mat',file,j);
end
clear temp j;

%%
ListeningTime = 30; %sec
Rate = 3.185;

%--------------------------------------

fprintf('----------- Report ----------\n');
fprintf('Sensor Location:           %s\n',LOC);
fprintf('Activity:                  %s\n',ACT);
fprintf('File Name:                 %s\n',file);
fprintf('Characters:                %d\n',i);
fprintf('Sampling Rate:             %.3f\n',Rate);
fprintf('Listening Time:            %d\n',ListeningTime);
fprintf('Number of Packets to Read  %d\n',ceil(Rate*ListeningTime))
input  ('Press Any Key to Continue... \n','s');

%--------------------------------------

PORT = serial('COM2');
set(PORT, 'InputBufferSize', 1);
set(PORT, 'FlowControl', 'none');
set(PORT, 'BaudRate', 38400);
set(PORT, 'Parity', 'none');
set(PORT, 'Timeout', 120);

%--------------------------------------

fprintf('Launching Data Acquisition\n');
for i = 5 : -1 : 1
    clc;
    fprintf('Please wait for %d seconds...\n',i);
    pause(1);
end

DB = zeros(ceil(Rate*ListeningTime),3);
NPR = 0;IND = 0;i = 1;ERR = false;NPC = 0;

%--------------------------------------

clc;
fopen(PORT);    
fprintf('\n%s Opened\n',get(PORT,'Name'));

%--------------------------------------

while lt(NPR,size(DB,1))
    TEXT(i) = char(fread(PORT)');
    if TEXT(i) == 10
        NPR = NPR + 1;
        if ~ERR
            DB(NPR,:) = [X,Y,Z];
            fprintf('NPR: %4d.\tTime:%3ds  ',NPR,round(NPR/Rate));
        else
            NPC = NPC + 1;
            DB(NPR,:) = DB(NPR-1,:);
            ERR = false;
            fprintf('NPR: %4d.\tTime:%3ds *',NPR,round(NPR/Rate));
        end
        PCR = round(NPC/NPR*100);
        if lt(PCR,25)
            fprintf('\tPCR: %2d%%\n',PCR);
        else
            fprintf('\tPCR: %2d%%\t*\n',PCR);
        end
    elseif TEXT(i) == 124
        IND = IND + 1;
        switch IND
            case 2
                X = str2double(TEXT(1,START:i-1));
                if isnan(X)
                    IND = 1;
                elseif gt(abs(X),1100)
                    ERR = true;
                end
            case 3
                 Y = str2double(TEXT(1,START:i-1));
                if gt(abs(Y),1100)
                    ERR = true;                                
                end
            case 4
                Z = str2double(TEXT(1,START:i-1));
                if gt(abs(Z),1100)
                    ERR = true;
                end
                IND = 0;
            otherwise
        end
        START = i+1;
    end
    i=i+1;
end%REAL-TIME

%--------------------------------------

fclose(PORT);
fprintf('%s Closed\n\n',get(PORT,'Name'));
clear PORT Rate
clear X Y Z
clear NPR NPC START IND ERR

%--------------------------------------

fprintf('----------- Report 2 ----------\n');
fprintf('Sensor Location:             %s\n',LOC);
fprintf('Activity:                    %s\n',ACT);
fprintf('File Name:                   %s\n',file);
fprintf('Listening Time:              %d\n',ListeningTime);
fprintf('Number of Packets to Read    %d\n',size(DB,1));
fprintf('Packet Crash Ratio           %d\n',PCR);
input  ('Press Any Key to Continue...   \n','s');

%---------------------------------------

while true
    Select = input('Figure? [Y/N] ','s');
    if size(Select,1) == 1
        if Select == 'Y' || Select == 'y'
            plot(DB);
            grid on
            xlabel('Packet Number');
            ylabel('Raw Accelerometer Data (m/s^2)');
            title({'Raw Acceleration Data Plot';[LOC,' Sensor'];[ACT,' Activity']});
            legend('X-Axis','Y-Axis','Z-Axis'); 
            break
        elseif Select == 'n' || Select == 'N'
            break
        end
    end
    fprintf('Wrong Input\n');
end

while true
    Select = input('Save to Database? [Y/N] ','s');
    if size(Select,2) == 1
        if Select == 'Y' || Select == 'y'
            save(file,'DB');
            file(size(file,2)-3:size(file,2))=[];
            saveas(gcf,sprintf('Pic/Ex%s.bmp',file));
            saveas(gcf,sprintf('Fig/Ex%s.fig',file));
            break
        elseif Select == 'N' || Select == 'n'
            break
        end
    end
    fprintf('Wrong Input.\n');
end
clear Select i;