fprintf('Loading Locations\n');
cd('../Files');
LOCS = ls;
LOCS(1:2,:) =[];
for i = size(LOCS,1) : -1 : 1
    if ~isdir(LOCS(i,:))
        LOCS(i,:) = [];
    end
end
fprintf('Locations Loaded\n');
NewLoc = false;
while true
    fprintf(' 0. New Location\n');
    for i = 1 : size(LOCS,1)
        fprintf('%2d. %s\n',i,LOCS(i,:));
    end
    ASK = input(sprintf('Sensor Location? [0 -%2d] ',size(LOCS,1)),'s');
    clc;
    if size(ASK,2) == 1 
        if ~isnan(str2double(ASK)) && le(str2double(ASK),size(LOCS,1))
            if ASK == '0'
                while true
                    ASK = input('New Sensor Location? ','s');
                    clc;
                    while ASK(size(ASK,2)) == ' '
                        ASK(size(ASK,2)) = [];
                    end
                    if gt(size(ASK,2),2) && le(size(ASK,2),5)
                        NewLoc = true;
                        for i = 1 : size(ASK,2)
                            if ASK(i) == ' '
                                NewLoc = false;
                            end
                        end
                        if NewLoc
                            LOC = ASK;
                            mkdir(ASK);
                            cd(ASK);
                            mkdir('NTRArray');
                            mkdir('Databases');
                            mkdir('Model');
                            mkdir('Figures');
                            mkdir('Experiment');
                            mkdir('Pic');
                            if lt(size(ASK,2),5)
                                for i = size(ASK,2)+1 : 10
                                    ASK(1,size(ASK,2)+1) = ' ';
                                end
                            end
                            break;
                        end
                    end
                    fprintf('Wrong Input.\n');
                end
                break;
            else
                LOC = LOCS(str2double(ASK),:);
                while LOC(size(LOC,2)) == ' '
                    LOC(size(LOC,2)) = [];
                end
                cd(LOC);
                break; 
            end
        end
    else
        fprintf('Wrong Input.\n');
    end
end %get LOC
clear LOCS i;    

if NewLoc
    NewAct = true;
else
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
                if NewLoc
                    ACTS = ACT;
                    save('Acts.mat','ACTS');
                    break
                else
                    load('Acts.mat','ACTS');
                    ACTS(size(ACTS,1)+1,:) = ACT;
                    save('Acts.mat','ACTS');
                    break
                end
            end
        end
        fprintf('Wrong Input.\n');
    end
    while ACT(size(ACT,2)) == ' '
        ACT(size(ACT,2)) = [];
    end        
end
%now we have both LOC and ACT
%cd is files/LOC/

clear ACTS i Select;

%observation construct database

cd('Databases');
j = 1;
file = sprintf('%s%s',ACT,LOC);
temp = ls;
temp(1:2,:) = [];
if size(temp,1) ~= 0 && ge(size(temp,1),size(file,1))
    for i = 1 : size(temp,1)
        if strcmp(temp(i,1:size(file,2)),file)
            j = j+1;
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
%cd is files/LOC/Databases
%set sample rate

cd('../..');
Rate = load('Rate.mat','Rate');
Rate = Rate.Rate;
while true
    fprintf('Sample Rate set to %.3f\n',Rate);
    Select = input('Change Sample Rate? [Y/N] ','s');
    clc;
    if size(Select,2) == 1
        if Select == 'Y' || Select == 'y'
            fprintf('WARNING: script to filter bad inputs not developed\n');
            Rate = str2double(input('Set Sample Rate to: ','s'));
            if ~isnan(Rate)
                %NEED FURTHER ATTENTION: filter bad inputs
                save('Rate.mat','Rate');
                break;
            end
        elseif Select == 'N' || Select == 'n'
            break;
        end
    end
    fprintf('Wrong Input.\n');
end
clear Select;
cd(LOC);
%cd is files/LOC/
%--------------------------------------
%set real-time data acquisition duration    
while true
    Time = str2double(input('Observation Duration (s)? ','s'));
    clc;
    if ~isnan(Time) && lt(Time,300) && ge(Time,15)
        NP2R = round(Time*Rate);
        break;
    else
        fprintf('Duration to be less than 300(s) greater than 15(s)\n');
        fprintf('Wrong Input.\n');
    end
end
%--------------------------------------
NPR = 0;
IND = 0;
NPC = 0;
ERR = false;
DB = zeros(NP2R,3);
clear NP2R;
%--------------------------------------
fprintf('Activity to Observe                 %s\n',ACT);
fprintf('Sensor Location                     %s\n',LOC);
fprintf('Filename                            %s\n',file);
fprintf('Number of Packets to Read           %d\n',size(DB,1));
fprintf('Data Acquisition Duration (sec)     %d\n',round(size(DB,1)/Rate));
fprintf('Data Acquisition Sample Rate        %.3f\n',Rate);
input('\nPress Enter to Confirm\n','s');
%--------------------------------------
for i = 5 : -1 : 1
    clc;
    fprintf('Please wait for %d seconds...\n',i);
    pause(1);
end
%--------------------------------------
PORT = serial('COM2');
set(PORT, 'InputBufferSize', 1);
set(PORT, 'FlowControl', 'none');
set(PORT, 'BaudRate', 38400);
set(PORT, 'Parity', 'none');
set(PORT, 'Timeout', 120);
fopen(PORT);    
fprintf('\n%s Opened\n',get(PORT,'Name'));
%--------------------------------------
while lt(NPR,size(DB,1))
    TEXT(i) = char(fread(PORT)');
    if TEXT(i) == 10
        NPR = NPR + 1;
        if ERR == false
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
clear X Y Z START IND ERR i;
%--------------------------------------
fclose(PORT);
fprintf('%s Closed\n\n',get(PORT,'Name'));
clear PORT;
%--------------------------------------
fprintf('------------  REPORT ------------\n');
fprintf(' 1. Activity Observed       %s\n',ACT);
fprintf(' 2. Sensor Location         %s\n',LOC);
fprintf(' 3. Filename                %s\n',file);
fprintf(' 3. Sample Rate             %.3f\n',Rate);
fprintf(' 4. Observation Duration    %d\n',Time);
fprintf(' 5. Characters Read         %d\n',size(TEXT,2));
fprintf(' 6. Packets Read            %d\n',NPR);
fprintf(' 7. Packets Crashed         %d\n',NPC);
fprintf(' 8. Packet Crash Ratio      %d\n',PCR);
%--------------------------------------
clear Time NPR PCR NPC;
while true
    Select = input('\nFigure? [Y/N] ','s');
    clc;
    if size(Select,2) == 1
        if Select == 'Y' || Select == 'y'
            FIGS = [...
                '------------- FIGURE -------------';...
                '00. None | No More                ';...
                '01. X Axis Plot                   ';...
                '02. Y Axis Plot                   ';...
                '03. Z Axis Plot                   ';...
                '04. 3-Axial Acceleration          ';...
                '05. TEXT                          ';...
                '----------------------------------'];
            while true
                disp(FIGS);
                FIGN = str2double(input(sprintf('Which Figure to Plot? [0 - %d] ',size(FIGS,1)-3),'s'));
                clc;
                if ~isnan(FIGN) && le(FIGN,size(FIGS,1)-2)
                    switch FIGN
                        case 0
                            break;
                        case 1
                            figure;
                            plot(DB(:,1))
                            axis([1 size(DB,1) -1100 1100])
                            grid on;
                            xlabel('Packet Number');
                            ylabel('X-Axis Acceleration');
                            title({'X-Axis Acceleration Plot';[LOC,' Sensor'];[ACT,' Activity']});
                        case 2
                            figure;
                            plot(DB(:,2))
                            axis([1 size(DB,1) -1100 1100])
                            grid on;
                            xlabel('Packet Number');
                            ylabel('Y Axis Acceleration');
                            title({'Y-Axis Acceleration Plot';[LOC,' Sensor'];[ACT,' Activity']});
                        case 3
                            figure;
                            plot(DB(:,3))
                            axis([1 size(DB,1) -1100 1100])
                            grid on;
                            xlabel('Packet Number');
                            ylabel('Z Axis Acceleration');
                            title({'Z-Axis Acceleration Plot';[LOC,' Sensor'];[ACT,' Activity']});
                        case 4
                            figure;
                            plot(DB(:,1:3))
                            axis([1 size(DB,1) -1100 1100])
                            grid on;
                            xlabel('Packet Number');
                            ylabel('Raw Acceleration Value');
                            title({'Raw Acceleration Data Plot';[LOC,' Sensor'];[ACT,' Activity']});
                            legend('X-Axis','Y-Axis','Z-Axis');
                        case 5
                            disp(TEXT);
                        otherwise
                            fprintf('Not Defined\n');
                    end
                else
                    fprintf('Respond with [0-%d] Numbers\n',size(FIGS,1)-3);
                end        
            end    
            clear FIGS FIGN;
            %--------------------------------------
            break
        elseif Select == 'N' || Select == 'n'
            break
        end
    end
    fprintf('Wrong Input!\n');
end
clear Select;
ACTS = load('Acts.mat','ACTS');
ACTS = ACTS.ACTS;
%--------------------------------------
while true
    figure;
    plot(DB(:,1:3))
    axis([1 size(DB,1) -1100 1100])
    grid on;
    xlabel('Packet Number');
    ylabel('Raw Acceleration Value');
    title({'Raw Acceleration Data Plot';[LOC,' Sensor'];[ACT,' Activity']});
    legend('X-Axis','Y-Axis','Z-Axis');
    %---------------------------------------------
    Select = input('Append to Database? [Y/N] ','s');
    clc;
    if size(Select,2) == 1
        if Select == 'Y' || Select == 'y'
            save(sprintf('Databases/%s',file),'DB');
            file(size(file,2)-3:size(file,2))=[];
            saveas(gcf,sprintf('Databases/Pic/Ex%s.bmp',file));
            saveas(gcf,sprintf('Databases/Fig/Ex%s.fig',file));
            fprintf('Post Processing\n');
            DATA = zeros(1,3);    
            for i = 1 : str2double(file(size(file,2)-6:size(file,2)-4))
                if lt(i,10)
                    load(sprintf('Databases/%s%s00%d.mat',ACT,LOC,i),'DB');
                elseif lt(i,100)
                    load(sprintf('Databases/%s%s0%d.mat',ACT,LOC,i),'DB');
                else
                    load(sprintf('Databases/%s%s%d.mat',ACT,LOC,i),'DB');
                end
                DATA(size(DATA,1)+1:size(DATA,1)+size(DB,1),:) = DB;
            end
            DATA(1,:)=[];
            DB = DATA;
            clear DATA;
            %--------------------------------------
            fprintf('Regenerating Arrays\n');
            for NTR = 1 : 1 : 36
                clc;
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
                clear X Y Z R P T TR PR NR;
                clear PRSM APRM;
                AAA = AAA';
                %--------------------------------------               
                if lt(NTR,10)
                    file = sprintf('NTRArray/NTR00%d_%s%s',NTR,ACT,LOC);
                elseif lt(NTR,100)
                    file = sprintf('NTRArray/NTR0%d_%s%s',NTR,ACT,LOC);
                elseif lt(NTR,1000)
                    file = sprintf('NTRArray/NTR%d_%s%s',NTR,ACT,LOC);
                end
                save(file,'AAA');
                fprintf('Array %d regenerated.\n',NTR);

                clear file
                %--------------------------------------
                fprintf('Reproducing Recognition Model\n');
                if size(num2str(NTR),2) == 1
                    file = sprintf('00%d',NTR);
                elseif size(num2str(NTR),2) == 2
                    file = sprintf('0%d',NTR);
                else
                    file = sprintf('%d',NTR);
                end                
                if NewLoc
                    ACTM = AAA;
                else
                    for i = 1 : size(ACTS,1)
                        ACT = ACTS(i,:);
                        while ACT(size(ACT,2))==' '
                            ACT(size(ACT,2)) = [];
                        end
                        load(sprintf('NTRArray/NTR%s_%s%s.mat',file,ACT,LOC),'AAA');
                        ACTM(i,1:size(AAA,2)) = AAA;
                    end
                end
                save(sprintf('Model/NTR%s.mat',file),'ACTM');
                fprintf('Recognition Model Updated\n');                
                clear file 
            end
            break
        elseif Select == 'N' || Select == 'n'
            break
        end
    end
end
%--------------------------------------
clear Select NewLoc NewAct NTR i ACTM AAA ACTS;