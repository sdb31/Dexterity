%% Anil 4-AP Work
% December 15, 2015

%% Load Variables
MEP = readtable('Area_under.xlsx', 'Sheet', 1);
MEP_High = MEP{1,:}; MEP_Low = MEP{2,:}; MEP_Control = MEP{3,:};
MEP_PTX = MEP{4,:};

SE = readtable('Area_under.xlsx', 'Sheet', 2);
SE_High = SE{1,:}; SE_Low = SE{2,:}; SE_Control = SE{3,:};
SE_PTX = SE{4,:};

figure(1); clf;
hold on;
plot(0:1:8, MEP_High, 'k-o')
plot(0:1:8, MEP_Low, 'b-o')
plot(0:1:8, MEP_Control, 'r-o')
plot(0:1:8, MEP_PTX, 'g-o');
hold off;
legend('High', 'Low', 'Control', 'PTX', 0);
title('MEP');

figure(2); clf;
hold on;
plot(0:1:8, SE_High, 'k-o')
plot(0:1:8, SE_Low, 'b-o')
plot(0:1:8, SE_Control, 'r-o')
plot(0:1:8, SE_PTX, 'g-o');
hold off;
legend('High', 'Low', 'Control', 'PTX', 0);
title('SE');