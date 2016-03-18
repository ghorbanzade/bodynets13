clear all; clc;
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
clear Found Temp Select DBnum

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
clc;

%%
CM = zeros(size(ACTS,1));
NTR = 8;
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
        %-------------- load ACTM
        if lt(NTR,10)
            ModelNTR = sprintf('../Model/NTR00%s.mat',num2str(NTR));
        elseif lt(NTR,100)
            ModelNTR = sprintf('../Model/NTR0%s.mat',num2str(NTR));
        else
            ModelNTR = sprintf('../Model/NTR%s.mat',num2str(NTR));
        end
        load(ModelNTR);
        %--------------
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
        CM(i,ACTN) = CM(i,ACTN) + 100/NumberOfFiles(i);
        clc;
        fprintf(sprintf('Confusion Matrix of %s Gestures\n\n',LOC));
        fprintf('       ');
        for u = 1 : size(ACTS,1)
            fprintf('%5s  ',ACTS(u,1:5));
        end
        fprintf('\n');
        for u = 1 : size(ACTS,1)
            fprintf('%5s  ',ACTS(u,1:5));
            for p = 1 : size(ACTS,1)
                fprintf('%5d  ',CM(u,p));
            end
            fprintf('\n');
        end
    end
end

clear X Y Z T P PR TR NR DB
clear ACT
clear Sigma ACTN ACRC
clear APRM ACTM PRSM NPR AAA
clear i j u p
clear ModelNTR NumberOfFiles file