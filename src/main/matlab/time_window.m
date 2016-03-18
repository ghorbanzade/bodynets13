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

load('Acts.mat');
cd('Experiment');
Temp = ls;
DBnum = 1;NumberOfFiles = zeros(1,size(ACTS,1));
for i = 1 : size(ACTS,1)
    ACT = ACTS(i,:);
    while ACT(size(ACT,2)) == ' '
        ACT(size(ACT,2)) = [];
    end
    %now we have ACT and LOC
    while true
        if lt(DBnum,10)
            file = sprintf('%s%s00%s.mat',ACT,LOC,num2str(DBnum));
        elseif lt(DBnum,100)
            file = sprintf('%s%s0%s.mat',ACT,LOC,num2str(DBnum));
        else
            file = sprintf('%s%s%s.mat',ACT,LOC,num2str(DBnum));
        end
        % now we have the filename to look for
        % first let length of file be extended to size of Temp
        while lt(size(file,2),size(Temp,2))
            file(size(file,2)+1) = ' ';
        end
        % now lets see if this file exists
        Found = false;
        for j = 1 : size(Temp,1)
            if strcmp(file,Temp(j,:))
                DBnum = DBnum + 1;
                Found = true;
                break
            end
        end
        if ~Found
            NumberOfFiles(i) = DBnum - 1;
            break
        end
    end
end
clear Found Temp DBnum

%%

DATA = [];
for i = 1 : size(ACTS,1)
    ACT = ACTS(i,:);
    while ACT(size(ACT,2)) == ' '
        ACT(size(ACT,2)) = [];
    end
    
    for j = 1 : NumberOfFiles(i)
        if lt(j,10)
            file = sprintf('%s%s00%s.mat',ACT,LOC,num2str(j));
        elseif lt(j,100)
            file = sprintf('%s%s0%s.mat',ACT,LOC,num2str(j));
        else
            file = sprintf('%s%s%s.mat',ACT,LOC,num2str(j));
        end
        load(file);
        DB(:,size(DB,2)+1) = i;
        DATA(size(DATA,1)+1:size(DATA,1)+size(DB,1),:) = DB;
    end
end
%%

cd('..');
NTR = 8;
%-------------- load ACTM
if lt(NTR,10)
    ModelNTR = sprintf('Model/NTR00%s.mat',num2str(NTR));
elseif lt(NTR,100)
    ModelNTR = sprintf('Model/NTR0%s.mat',num2str(NTR));
else
    ModelNTR = sprintf('Model/NTR%s.mat',num2str(NTR));
end
load(ModelNTR);
%--------------
clear ModelNTR

%%

fprintf('----- Recognizable Activities -----\n');
fprintf('    Activitiy     Number of Files  \n');
fprintf('    ---------     ---------------  \n');
for i = 1 : size(ACTS,1)
    fprintf('%2d. %s          %d',i,ACTS(i,:),NumberOfFiles(i));
    fprintf('\n');
end
fprintf('-----------------------------------\n');
input('Press any key to begin processing files','s');
clc

%%
Rate = 3.185;
COUNTER = 0;
for TimeWindow = 1 : 96 % 96 is size(DB,1)
    if mod(96,TimeWindow) == 0;
        %--------
        COUNTER = COUNTER + 1;
        %--------
        CM = zeros(size(ACTS,1));
        for Counter = 1 : size(DATA,1)/TimeWindow
            DB = DATA((Counter-1)*TimeWindow+1:Counter*TimeWindow,:);
            i = sum(DB(:,4))/size(DB,1);
            DB(:,4) = [];
            %------------------------------
            DB(:,4:9)=zeros(size(DB,1),6);   % Add columns to Database
            ST = zeros(1,NTR);               % INIT: Surface of Theta Regions
            TRSM = 0:180/NTR:180;            % INIT: Theta Regions Matrix
            PRSM = ones(1,NTR);              % INIT: Phi Regions Matrix
            APRM = zeros(1,NTR+1);           % INIT: Accumulated Phi Regions Matrix
            for u = 1 : NTR                  % Generate Accumulated Phi Regions Matrix
                ST(u) = 2 * pi * 1e6 * (cosd(TRSM(u))-cosd(TRSM(u+1)));
                PRSM(u) = round(ST(u)/ST(1));
                APRM(u+1) = APRM(u) + PRSM(u);
            end
            APRM(NTR+1)=[];                  % Remove last element
            AAA = zeros(APRM(NTR)+1,1);      % INIT: Actual Activity Array
            clear TRSM ST;
            for NPR = 1 : size(DB,1)
                X = DB(NPR,1);
                Y = DB(NPR,2);
                Z = DB(NPR,3);
                P = 180 + atan2d(Y,X);
                T = atan2d(Z,sqrt(X^2 + Y^2));
                TR = abs(floor((T-90)/(180/size(PRSM,2))));
                if gt ( abs ( P - 180 ) , 180 - 180/PRSM(TR) )
                    PR = 1;
                else
                    PR = ceil ( ( P + 180/PRSM(TR) ) / ( 360/PRSM(TR) ) ) ;
                end
                NR = APRM(TR) + PR;
                AAA(NR,1) = AAA(NR,1) + 100/size(DB,1);
            end
            AAA = AAA';
            for u = 1 : size(ACTM,1)
                Sigma(u) = sum(abs(ACTM(u,:) - AAA ).^2);
            end
            [ACRC,ACTN] = min(Sigma);
            CM(i,ACTN) = CM(i,ACTN) + 1;
            clc
            fprintf('Time Window Set to:\t%d seconds\n',round(TimeWindow/Rate));
            fprintf('Number of Activity Instances:\t%d\n',size(DATA,1)/TimeWindow);
            fprintf('Counter:\t%d\n',Counter);
            disp(CM);
             %------------------------------
            Sum = 0;
            for t = 1 : size(CM,1)
                Sum = Sum + CM(t,t);
            end
            disp(Sum/(size(DATA,1)/TimeWindow));
            FIGURE(1,COUNTER)= Sum/(size(DATA,1)/TimeWindow);
            FIGURE(2,COUNTER)= TimeWindow;
        end
    pause(1);
    clc;          
    end  
end

FIGURE = FIGURE';
FIGURE(:,1) = FIGURE(:,1) * 100;
FIGURE(:,2) = round(FIGURE(:,2) / Rate);
plot(FIGURE(:,2),FIGURE(:,1),'LineWidth',2);
grid on;
axis([min(FIGURE(:,2)) max(FIGURE(:,2)),0 100]);
xlabel('Time Window Size (sec)');
ylabel('Recognition Accuracy (%)');

clear DB NPR ACT
clear AAA APRM PRSM ACTM
clear ACRC ACTN Sigma
clear CM NTR TimeWindow Sum Select Rate Counter COUNTER
clear X Y Z P T TR NR PR
clear i j t u
clear file NumberOfFiles