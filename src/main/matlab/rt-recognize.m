clear all; clc;
cd('..');

%--------------------------------------  

fprintf('Loading Locations\n');
cd('Files');
LOCS = ls;
LOCS(1:2,:) =[];
for i = size(LOCS,1) : -1 : 1
    if ~isdir(LOCS(i,:))
        LOCS(i,:) = [];
    end
end
fprintf('Locations Loaded\n');

%--------------------------------------  

while true
    for i = 1 : size(LOCS,1)
        fprintf('%2d. %s\n',i,LOCS(i,:));
    end
    ASK = input(sprintf('Sensor Location? [0 -%2d] ',size(LOCS,1)),'s');
    clc;
    if size(ASK,2) == 1
        if ~isnan(str2double(ASK)) && le(str2double(ASK),size(LOCS,1))
            LOC = LOCS(str2double(ASK),:);
            while LOC(size(LOC,2)) == ' '
                LOC(size(LOC,2)) = [];
            end
            break;
        end
    else
        fprintf('Wrong Input.\n');
    end
end %get LOC
clear LOCS ASK;

%--------------------------------------
%future development: recognition be done in three categories:
%future development: Real-Time Lab, Real-World, File
%for Real-Time Lab:
%--------------------------------------
while true
    Select = input('Listening Time (sec)? ','s');
    if ~isnan(str2double(Select))
        if le(str2double(Select),5)
            fprintf('Not to be less than 5 seconds\n');
        elseif ge(str2double(Select),30)
            fprintf('Not to be greater than 30 seconds\n');
        else
            ListeningTime = round(str2double(Select));
            break
        end
    end
    fprintf('Wrong Input.');
end
%--------------------------------------
while true
    clc;
    Select = input('Recognition Time (sec)? ','s');
    if ~isnan(str2double(Select))
        if gt(str2double(Select),ListeningTime)
            RecognitionTime = round(str2double(Select));
            break
        end
    end
end
%--------------------------------------
CountTo = round(RecognitionTime/ListeningTime);
%--------------------------------------
load('Rate.mat','Rate');
%--------------------------------------
while true
    fprintf('Sample Rate set to %.3f\n',Rate);
    Select = input('Change Sample Rate? [Y/N] ','s');
    clc;
    if size(Select,2) == 1
        if Select == 'Y' || Select == 'y'
            Rate = str2double(input('Set Sample Rate to: ','s'));
            if ~isnan(Rate)
                save('Rate.mat','Rate');
                break;
            end
        elseif Select == 'N' || Select == 'n'
            break;
        end
    end
    fprintf('Wrong Input.\n');
end
%--------------------------------------
cd(LOC);    
DB = zeros(ceil(Rate*ListeningTime),3);
RM = zeros(1,CountTo);
clear ListeningTime RecognitionTime NP2R Select;
%--------------------------------------
PORT = serial('COM3');
set(PORT, 'InputBufferSize', 1);
set(PORT, 'FlowControl', 'none');
set(PORT, 'BaudRate', 38400);
set(PORT, 'Parity', 'none');
set(PORT, 'Timeout', 120);
%--------------------------------------
%future development: give report
input('Press Any Key to Being Data Acquisition','s');
%--------------------------------------
fprintf('Launching Data Acquisition\n');
for Counter = 1 : CountTo
    % pause for 5 seconds so user is ready (only in Lab Setting)
    for i = 5 : -1 : 1
        clc;
        fprintf('Please wait for %d seconds...\n',i);
        pause(1);
    end
    % initial parameters
    clc;
    NPR = 0;IND = 0;i = 1;ERR = false;NPC = 0;
    % begin
    fopen(PORT);    
    fprintf('\n%s Opened\n',get(PORT,'Name'));
    % ---------------------
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
    clear X Y Z
    clear NPR NPC PCR START IND ERR NTR
    %-------------------------------------- 
    fprintf('------------ Post Processing ------------\n');
    %--------------------------------------
    load('Acts.mat','ACTS');
    NTR = 8;
    DB(:,4:9)=zeros(size(DB,1),6);   % Add columns to Database
    ST = zeros(1,NTR);               % INIT: Surface of Theta Regions
    TRSM = 0:180/NTR:180;            % INIT: Theta Regions Matrix
    PRSM = ones(1,NTR);              % INIT: Phi Regions Matrix
    APRM = zeros(1,NTR+1);           % INIT: Accumulated Phi Regions Matrix
    for i = 1 : NTR                  % Generate Accumulated Phi Regions Matrix
        ST(i) = 2 * pi * 1e6 * (cosd(TRSM(i))-cosd(TRSM(i+1)));
        PRSM(i) = round(ST(i)/ST(1));
        APRM(i+1) = APRM(i) + PRSM(i);
    end
    APRM(NTR+1)=[];                  % Remove last element
    AAA = zeros(APRM(NTR)+1,1);      % INIT: Actual Activity Array
    clear TRSM ST;
    %--------------------------------------
    for i = 1 : size(DB,1)
        X = DB(i,1);
        Y = DB(i,2);
        Z = DB(i,3);
        P = 180 + atan2d(Y,X);
        T = atan2d(Z,sqrt(X^2 + Y^2));
        R = sqrt(X^2 + Y^2 + Z^2);
        TR = abs(floor((T-90)/(180/size(PRSM,2))));
        if gt ( abs ( P - 180 ) , 180 - 180/PRSM(TR) )
            PR = 1;
        else
            PR = ceil ( ( P + 180/PRSM(TR) ) / ( 360/PRSM(TR) ) ) ;
        end
        NR = APRM(TR) + PR;
        DB(i,:) = [X,Y,Z,P,T,R,PR,TR,NR];
        AAA(NR,1) = AAA(NR,1) + 100/size(DB,1);
    end
    AAA = AAA';
    clear X Y Z R P T TR PR NR;
    clear PRSM APRM;
    %--------------------------------------
    if lt(NTR,10)
        ACTM = load(sprintf('Model/NTR00%d.mat',NTR),'ACTM');
    elseif lt(NTR,100)
        ACTM = load(sprintf('Model/NTR0%d.mat',NTR),'ACTM');
    else
        ACTM = load(sprintf('Model/NTR%d.mat',NTR),'ACTM');
    end
    ACTM = ACTM.ACTM;
    for i = 1 : size(ACTM,1)
        Sigma(i) = sum(abs(ACTM(i,:) - AAA ).^2);
    end
    [ACRC,ACTN] = min(Sigma);
    RM(Counter) = ACTN;
    fprintf('(ACT) %5s\t\t(ACRC) %.f\n',ACTS(ACTN,:),ACRC);
    clear NTR Sigma ACTN ACRC ACTM AAA TEXT
    %--------------------------------------
    if Counter ~= CountTo
%         input('Press Any Key to Run Again','s');
        pause(2);
    end
    DB(:,4:9)=[];
    %--------------------------------------
end
clc
fprintf('Data Acquisition Complete\n');
%--------------------------------------
Counter = 1;
GT = zeros(1,CountTo);
for Counter = 1 : CountTo
    while true
        clc;
        fprintf('---- Recognizable Activities ----\n');
        for i = 1 : size(ACTS,1)
            fprintf('%2d. %s',i,ACTS(i,:))
            if mod(i,3) == 0
                fprintf('\n');
            else
                fprintf('\t');
            end        
        end
        ASK = input(sprintf('\n\nWhat was activity %2d? ',Counter),'s');
        if ~isnan(str2double(ASK))
            if le(str2double(ASK),size(ACTS,1)) && gt(str2double(ASK),0)
                GT(Counter) = str2double(ASK);
                break;
            end
        end
        fprintf('Wrong Input\n');
    end
end
%--------------------------------------
ACRC = 0;
for i = 1 : CountTo
    if GT(i) == RM(i)
        ACRC = ACRC + 100/size(RM,2);
    end
end
fprintf('Recognition Accuracy: %2.f %%\n',ACRC);
%--------------------------------------
clear Rate RecognitionTime i PORT DB Counter CountTo ASK