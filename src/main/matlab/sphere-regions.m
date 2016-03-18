clear Select

A = zeros(1,36);
for NTR = 1 : 36
    %--------------------------------------
    ST = zeros(1,NTR);               % INIT: Surface of Theta Regions
    TRSM = 0:180/NTR:180;            % INIT: Theta Regions Matrix
    PRSM = ones(1,NTR);              % INIT: Phi Regions Matrix
    for i = 1 : NTR                  % Generate Accumulated Phi Regions Matrix
        ST(i) = 2 * pi * 1e6 * (cosd(TRSM(i))-cosd(TRSM(i+1)));
        PRSM(i) = round(ST(i)/ST(1));
    end
    clear TRSM i ST
    A(NTR) = sum(PRSM);
    %---------------------------------------
end
bar(smooth(A));
grid on
xlabel('Number of Elevation Divisons');
ylabel('Total Number of Regions');
axis([1 size(A,2),0 max(A)+max(A)*0.1]);