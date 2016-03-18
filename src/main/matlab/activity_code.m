clear Select; 
clc;close all;

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

%--------------------------------------
load(sprintf('Databases/%s%s001.mat',ACT,LOC));
%--------------------------------------
NTR = 8;
%--------------------------------------
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
clear TRSM i
%--------------------------------------
for NPR = 1 : size(DB,1)
    X = DB(NPR,1);
    Y = DB(NPR,2);
    Z = DB(NPR,3);
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
    DB(NPR,:) = [X,Y,Z,P,T,R,PR,TR,NR];

    AAA(NR,1) = AAA(NR,1) + 100/size(DB,1);
end
AAA = AAA';
clear X Y Z P T R TR PR NR NPR PRSM

bar(AAA);
grid on;
xlabel('Region Number');
ylabel('Occurance (%)');
title({sprintf('Recognition Code of %s',ACT);sprintf('Sensor attached to %s',LOC)});
axis([1 size(AAA,2),0 100]);
clear NTR DB APRM ST;