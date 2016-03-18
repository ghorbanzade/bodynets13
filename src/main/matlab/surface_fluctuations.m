clear Select
%--------------------------------------
for NTR = 1 : 36
    %--------------------------------------
    ST = zeros(1,NTR);               % INIT: Surface of Theta Regions
    SR = zeros(1,NTR);               % INIT: Surface of Regions
    TRSM = 0:180/NTR:180;            % INIT: Theta Regions Matrix
    PRSM = ones(1,NTR);              % INIT: Phi Regions Matrix
    for i = 1 : NTR                  % Generate Accumulated Phi Regions Matrix
        ST(i) = 2 * pi * 1e6 * (cosd(TRSM(i))-cosd(TRSM(i+1)));
        PRSM(i) = round(ST(i)/ST(1));
        SR(i) = 2 * pi * 1e6 * (cosd(TRSM(i))-cosd(TRSM(i+1))) / PRSM(i);    
    end
    %--------------------------------------
    Fluc(NTR) = round((max(SR)-min(SR))/(sum(SR)/size(SR,2))*100);
end
plot(smooth(Fluc),'LineWidth',2);
grid on;
xlabel('Number of Theta Divisions');
ylabel('Fluctuation (%)');
title('Smoothed Surface Area Fluctuation for Different Elevation Divisoins');
axis([1 NTR,0 100]);
clear NTR PRSM SR ST APRM TRSM i;