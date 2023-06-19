clc;
close all;
clear all;

%% Data loading
% First as we want to manage the final data for Bland-Altman method for that reason
% we load the Final Data and it is associated the specific column of final data matrix

% Final Data table loading
load FinalHRData.mat;
load FinalSpO2Data.mat;

%% Selecting part
% This part of code was created to select or delete the part of dataset
% without interest. It is commented by default.

FinalHRData = FinalHRData(~(FinalHRData.Position=="Workout"),:);
FinalSpO2Data = FinalSpO2Data(~(FinalSpO2Data.Position=="Workout"),:);

%% Some arranges previous to extract Bland-Altman Method
% Due to both volunteers were fill with NaN values we must evaluate taken
% that into account
Wellue = FinalHRData.WellueHR(~(FinalHRData.Volunteer==0 | (FinalHRData.Volunteer==7 & FinalHRData.Position=="Stand")));
LifeVit_Vital = FinalHRData.LifeVitHR;
LifeVit_Vital2 = FinalHRData.LifeVitHR(~(FinalHRData.Volunteer==0 | (FinalHRData.Volunteer==7 & FinalHRData.Position=="Stand")));
Biopac = FinalHRData.BiopacHR;
BiopacDF = FinalHRData.DFBiopacHR;

WellueSpo2 = FinalSpO2Data.WellueSpO2;
LifeVit_Vital_SpO2 = FinalSpO2Data.LifeVitSpO2;

%% Previous calculations to plot correctly the Bland-Altman method
% Diferences between the LifeVit Vital vs Biopac/Wellue Oximeter
diffVitalVSBiopac = LifeVit_Vital - Biopac;
diffVitalVSBiopac2 = LifeVit_Vital - BiopacDF;
diffVitalVSWellue = LifeVit_Vital2 - Wellue;
diffVitalVSWellueSpO2 = LifeVit_Vital_SpO2 - WellueSpo2;

% Average value between the two measurements
averageVitalVSBiopac = (LifeVit_Vital + Biopac) / 2;
averageVitalVSBiopac2 = (LifeVit_Vital + BiopacDF) / 2;
averageVitalVSWellue = (LifeVit_Vital2 + Wellue) / 2;
averageVitalVSWellueSpO2 = (LifeVit_Vital_SpO2 + WellueSpo2) / 2;

% Mean value of both differences
meanVitalVSBiopac = mean(diffVitalVSBiopac);
meanVitalVSBiopac2 = mean(diffVitalVSBiopac2);
meanVitalVSWellue = mean(diffVitalVSWellue);
meanVitalVSWellueSpO2 = mean(diffVitalVSWellueSpO2);

% Upper and lower limit with a 95% of confidence
limVitalVSBiopac = 1.96*std(diffVitalVSBiopac);
limVitalVSBiopac2 = 1.96*std(diffVitalVSBiopac2);
limVitalVSWellue = 1.96*std(diffVitalVSWellue);
limVitalVSWellueSpO2 = 1.96*std(diffVitalVSWellueSpO2);

%% Finally, we will plot all Bland-Altman methods

% Heart Rate Plots
blandAltmanPlot(averageVitalVSBiopac,diffVitalVSBiopac,meanVitalVSBiopac,limVitalVSBiopac, ...
    "Heart Rate Bland-Altman method against Biopac");
corLVvsB = corrcoef(Biopac,LifeVit_Vital);

blandAltmanPlot(averageVitalVSBiopac2,diffVitalVSBiopac2,meanVitalVSBiopac2,limVitalVSBiopac2, ...
    "Heart Rate Bland-Altman method against Biopac 2");
corLVvsB2 = corrcoef(BiopacDF,LifeVit_Vital);

blandAltmanPlot(averageVitalVSWellue,diffVitalVSWellue,meanVitalVSWellue,limVitalVSWellue, ...
    "Heart Rate Bland-Altman method against Wellue Oximeter");
corLVvsW = corrcoef(Wellue,LifeVit_Vital2);

% SpO2 Plots
blandAltmanPlot(averageVitalVSWellueSpO2,diffVitalVSWellueSpO2,meanVitalVSWellueSpO2, ...
    limVitalVSWellueSpO2, "SpO2 Bland-Altman method against Wellue Oximeter")
corLVvsWSpO2 = corrcoef(WellueSpo2,LifeVit_Vital_SpO2);

%% Functions
% Bland-Altman plot function
% Function that will plot the method against the reference method selected
function blandAltmanPlot(average,difference,mean,lim,titleText)
   
    lm = fitlm(average, difference);

    figure;
    plot(average,difference,".","MarkerSize",10);

    hold on;
    plot([min(average) max(average)], [mean mean],'-', "LineWidth",1.5,"Color","#FEB827");
    text(max(average)+0.3,max(mean),num2str(mean),"Color","#FEB827");

    plot(average, lm.Fitted,'-',"LineWidth",1.5,"Color","#F6821F");
    equationFitted = strcat(num2str(lm.Coefficients.Estimate(2),'%+.2f'),'*x', ...
        num2str(lm.Coefficients.Estimate(1),'%+.2f'));
    text(max(average)+0.3, max(lm.Fitted)+0.3,equationFitted,"Color","#F6821F");

    plot([min(average) max(average)], [mean+lim mean+lim],'--',"LineWidth",1.5,"Color","r");
    text(max(average)+0.3, mean+lim+1, num2str(mean+lim), "Color", "r");

    plot([min(average) max(average)], [mean-lim mean-lim],'--',"LineWidth",1.5,"Color","r");
    text(max(average)+0.3, mean-lim, num2str(mean-lim), "Color", "r");
    
    xlim([min(average) max(average)]);
    xlabel('Average between measurements');
    ylabel('Difference between measurements');
    title(titleText);
    legend('Differences', 'Mean value','Mean Trend','95% Confidence limits');
    
end

