clear all;
close all;
clc;

%% PRE-ANALYSIS SECTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Code section where we will read all the data for the analysis in order  %
% to be evaluated later with Bland-Altman Method                          %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Final Data table loading
load FinalHRData.mat;
load FinalSpO2Data.mat;

% Choose the folder where you saved your data
cd("C:\Users\Toni\Desktop\Dycare\Script_datos\Voluntarios\")

% Read The .mat file reference obtained through Wellue Oximeter
load(uigetfile('.mat'));

% Read The .mat file reference obtained through Biopac MP36
load(uigetfile('.mat'));

% Read The .txt file with the data obtained by LifeVit Vital
[LifeVit_Vital_HR, LifeVit_Vital_SpO2]= transformLifevitFile();


% In this part of code we want to filter the ECG data and obtain the R
% component of it. We select the column #1 that correspons to ECG recorded
% by Biopac MP36 and then we filter the signal obtained.
fs = 5000;
[r,~,~]=qrsDetector(data(:,1),fs);
b=ones(10,1)/10;a=1;
biopac_HR = filter(b,a,fs*60./diff(r));
biopac_HR_df= filtfilt(b,a,fs*60./diff(r));

% As we must manage the data over the time, here it is created a synthetic
% timestamps with LifeVit reference and taken into account the fs and
% the length of tha data obtained.
start_time = datetime(LifeVit_Vital_HR.("Time HR")(1));
duration = (length(data) - 1) / fs;
timestamps = linspace(start_time, ...
    start_time+seconds(round(duration)), ...
    length(biopac_HR));

Biopac_HR=table2timetable(table(timestamps',biopac_HR', ...
    'VariableNames', {'Time','HR'}));
BiopacDF_HR=table2timetable(table(timestamps', biopac_HR_df', ...
    'VariableNames', {'Time','HR_DF'}));

% Selection of the respiration signal
Biopac_BR = data(:,2);


% Now we clear the workspace in order to work more comfortably with all the
% data
clear a b data isi isi_units k labels r start_sample units yfdds biopac_HR ...
start_time timestamps duration biopac_HR_df;

%% ANALYSIS SECTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Code section where we will analyze the data recorded for all the devices%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% HR SECTION
% Part of code to adjust the signal previously to analyze with Bland-Altman
% method. Firstly, we will do a plot to see how is the delay between
% signals
figure;
plot((Biopac_HR.Time),Biopac_HR.HR, ...
    (BiopacDF_HR.Time),BiopacDF_HR.HR_DF, ...
    (Wellue_Data.Time),Wellue_Data.Heart_Rate, ...
    (LifeVit_Vital_HR.("Time HR")),LifeVit_Vital_HR.HR,"LineWidth",1.5);
xlim ([LifeVit_Vital_HR.("Time HR")(1) LifeVit_Vital_HR.("Time HR")(end)])
legend('Biopac', 'Biopac 2','Wellue Oximeter','LifeVit Vital');
title("Volunteer 0 | Position: Lie Down | HR adjustment")

% Creation of delay between signals in order to adjust
BiopacDelay = seconds(0); 
BiopacDFDelay = seconds(0);
WellueDelay = seconds(0);
LifevitDelay = seconds(0);

% Plots to see if the adjustment was correct or not for HR
figure;
plot((Biopac_HR.Time-BiopacDelay),Biopac_HR.HR, ...
    (BiopacDF_HR.Time-BiopacDFDelay),BiopacDF_HR.HR_DF, ...
    (Wellue_Data.Time-WellueDelay),Wellue_Data.Heart_Rate, ...
    (LifeVit_Vital_HR.("Time HR")-LifevitDelay),LifeVit_Vital_HR.HR,"LineWidth",1.5);
if (LifevitDelay > 0)
    xlim ([LifeVit_Vital_HR.("Time HR")(1) LifeVit_Vital_HR.("Time HR")(end)-LifevitDelay]);
else
    xlim ([LifeVit_Vital_HR.("Time HR")(1)-LifevitDelay LifeVit_Vital_HR.("Time HR")(end)-LifevitDelay]);
end
legend('Biopac', 'Biopac 2','Wellue Oximeter','LifeVit Vital');
title("Volunteer 3 | Position: Stand | HR adjustment")


% Now, we adjust all the time with the delay created previously taken into
% account that the evaluation time must be adjusted
if (LifevitDelay > 0)
    evaluationTimeWindow = timerange(LifeVit_Vital_HR.("Time HR")(1), ...
    LifeVit_Vital_HR.("Time HR")(end)-LifevitDelay);
else
    evaluationTimeWindow = timerange(LifeVit_Vital_HR.("Time HR")(1)-LifevitDelay, ...
    LifeVit_Vital_HR.("Time HR")(end)-LifevitDelay);
end

Biopac_HR.Time = Biopac_HR.Time - BiopacDelay;
BiopacDF_HR.Time = BiopacDF_HR.Time - BiopacDFDelay;
Wellue_Data.Time = Wellue_Data.Time -  WellueDelay;
LifeVit_Vital_HR.("Time HR") = LifeVit_Vital_HR.("Time HR") - LifevitDelay;


% Filter the four data vectors with the evaluation time created previously
Biopac_HR = Biopac_HR(evaluationTimeWindow,:);
BiopacDF_HR = BiopacDF_HR(evaluationTimeWindow,:);
Wellue_Data = Wellue_Data(evaluationTimeWindow,:);
LifeVit_Vital_HR = LifeVit_Vital_HR(evaluationTimeWindow,:);

% In this step, we will delete all the zero-peaks that we have on the
% signal due to the reset of the wearable in order to evaluate properly 
deleteRows = [93];
LifeVit_Vital_HR(deleteRows,:) = [];
Biopac_HR(deleteRows,:) = [];
BiopacDF_HR(deleteRows,:) = [];
Wellue_Data(deleteRows,:) = [];

% Check to see if the adjustment was correct after delete the previous value
figure;
plot((Biopac_HR.Time),Biopac_HR.HR, ...
    (BiopacDF_HR.Time),BiopacDF_HR.HR_DF, ...
    (Wellue_Data.Time),Wellue_Data.Heart_Rate, ...
    (LifeVit_Vital_HR.("Time HR")),LifeVit_Vital_HR.HR,"LineWidth",1.5);
xlim ([LifeVit_Vital_HR.("Time HR")(1) LifeVit_Vital_HR.("Time HR")(end)])
legend('Biopac', 'Biopac 2','Wellue Oximeter','LifeVit Vital');
title("Volunteer 3 | Position: Sit | HR adjustment")

% As we need to evaluate the data with a Bland-Altman method we need to
% interpolate all the vectors, for that reason I create a interpolation
% time vector with the time of interest and then I interpolate all the data
% to have the same number of values in each data vector
%interpolationTime=LifeVit_Vital_HR.("Time HR")(1)+LifevitDelay: ...
%                   seconds(1):LifeVit_Vital_HR.("Time HR")(end);
interpolationTime=LifeVit_Vital_HR.("Time HR")(1):seconds(1):LifeVit_Vital_HR.("Time HR")(end);
Biopac_HR_int = interp1(Biopac_HR.Time,Biopac_HR.HR,interpolationTime);
BiopacDF_HR_int = interp1(BiopacDF_HR.Time,BiopacDF_HR.HR_DF,interpolationTime);
Wellue_Data_int = interp1(Wellue_Data.Time,double(Wellue_Data.Heart_Rate), ...
                           interpolationTime);
LifeVit_Vital_HR_int = interp1(LifeVit_Vital_HR.("Time HR"), ...
    LifeVit_Vital_HR.HR,interpolationTime);

% The las figure to check if the interpolation was good or not
figure;
plot(interpolationTime,Biopac_HR_int, ...
    interpolationTime,BiopacDF_HR_int, ...
    interpolationTime,Wellue_Data_int, ...
    interpolationTime,LifeVit_Vital_HR_int,"LineWidth",1.5);
xlim ([interpolationTime(1) interpolationTime(end)])
legend('Biopac', 'Biopac 2','Wellue Oximeter','LifeVit Vital');
title("Volunteer 3 | Position: Sit | HR interpolation");

% Sometimes due to the interpolation can appear new NaN values that we
% don't want to analyze for that reason we will delete all this values
deleteR = [1];
interpolationTime (deleteR) = [];
Biopac_HR_int (deleteR) = [];
BiopacDF_HR_int (deleteR) = [];
Wellue_Data_int (deleteR) = [];
LifeVit_Vital_HR_int (deleteR) = [];

% If all is correct we will save the data to the final vector, for this aim
% we need to return to previous folder where the final data is located
% For some volunteers we don't have Wellue data and fill this values with
% an empty vector zeros(length(LifeVit_Vital_HR_int),0)
cd ..

% Creation of new table with HR values of interest
HRFinal = table(Biopac_HR_int', ... % Biopac HR Final Data
    BiopacDF_HR_int', ... % Biopac HR Final Data 2
    Wellue_Data_int',... %Wellue HR Final Data
    LifeVit_Vital_HR_int', ... % LifeVit Vital HR Final Data
    NaN*ones(length(LifeVit_Vital_HR_int),1), ... % Respiration Final Data
    21*ones(length(LifeVit_Vital_HR_int),1), ... % Volunteer #
    repmat("Workout",length(LifeVit_Vital_HR_int),1), ... % Position of Data
    'VariableNames', FinalHRData.Properties.VariableNames);

% Concatenation of previous table and new HR data
FinalHRData = [FinalHRData; HRFinal];

%% SpO2 Section
% Read again the .mat file reference obtained through Wellue Oximeter
load(uigetfile('.mat'));

% Part of code to adjust the signal previously to analyze with Bland-Altman
% method. Firstly, we will do a plot to see how is the delay between
% signals
figure;
plot(Wellue_Data.Time,Wellue_Data.SpO2, ...
    LifeVit_Vital_SpO2.("Time SpO2"),LifeVit_Vital_SpO2.SpO2,"LineWidth",1.5);
xlim ([LifeVit_Vital_SpO2.("Time SpO2")(1) LifeVit_Vital_SpO2.("Time SpO2")(end)])
legend('Wellue Oximeter','LifeVit Vital');

% Creation of delay between signals in order to adjust
LifevitDelay = seconds(0);
WellueDelay = seconds(0); 

% Plots to see if the adjustment was correct or not for SpO2
figure;
plot((Wellue_Data.Time-WellueDelay),Wellue_Data.SpO2, ...
    (LifeVit_Vital_SpO2.("Time SpO2")-LifevitDelay),LifeVit_Vital_SpO2.SpO2,"LineWidth",1.5);
if (LifevitDelay > 0)
    xlim ([LifeVit_Vital_SpO2.("Time SpO2")(1) LifeVit_Vital_SpO2.("Time SpO2")(end)-LifevitDelay]);
else
    xlim ([LifeVit_Vital_SpO2.("Time SpO2")(1)-LifevitDelay LifeVit_Vital_SpO2.("Time SpO2")(end)-LifevitDelay]);
end
legend('Wellue Oximeter','LifeVit Vital');
title("Volunteer 3 | Porsition: Lay | SpO2 adjustment")

% Now, we adjust all the time with the delay created previously taken into
% account that the evaluation time must be adjusted
if (LifevitDelay > 0)
    evaluationTimeWindow = timerange(LifeVit_Vital_SpO2.("Time SpO2")(1), ...
        LifeVit_Vital_SpO2.("Time SpO2")(end)-LifevitDelay);
else
    evaluationTimeWindow = timerange(LifeVit_Vital_SpO2.("Time SpO2")(1)-LifevitDelay, ...
        LifeVit_Vital_SpO2.("Time SpO2")(end)-LifevitDelay);
end

Wellue_Data.Time = Wellue_Data.Time -  WellueDelay;
LifeVit_Vital_SpO2.("Time SpO2") = LifeVit_Vital_SpO2.("Time SpO2") - LifevitDelay;

% Filter the four data vectors with the evaluation time created previously
Wellue_Data = Wellue_Data (evaluationTimeWindow,:);
LifeVit_Vital_SpO2 = LifeVit_Vital_SpO2(evaluationTimeWindow,:);

% In this step, we will delete all the zero-peaks that we have on the
% signal due to the reset of the wearable in order to evaluate properly 
deleteRows = [1];
LifeVit_Vital_SpO2(deleteRows,:) = [];
Wellue_Data(deleteRows,:) = [];

% Check to see if the adjustment was correct after delete the previous
% values
figure;
plot(Wellue_Data.Time,Wellue_Data.SpO2, ...
    LifeVit_Vital_SpO2.("Time SpO2"),LifeVit_Vital_SpO2.SpO2,"LineWidth",1.5);
xlim ([LifeVit_Vital_SpO2.("Time SpO2")(1) LifeVit_Vital_SpO2.("Time SpO2")(end)])
legend('Wellue Oximeter','LifeVit Vital');
title("Volunteer 3 | Position: Lay | SpO2 adjustment")

% As we need to evaluate the data with a Bland-Altman method we need to
% interpolate all the vectors, for that reason I create a interpolation
% time vector with the time of interest and then I interpolate all the data
% to have the same number of values in each data vector
%interpolationTime=LifeVit_Vital_SpO2.("Time SpO2")(1)+LifevitDelay: ...
%                   seconds(1):LifeVit_Vital_SpO2.("Time SpO2")(end);
interpolationTime=LifeVit_Vital_SpO2.("Time SpO2")(1):seconds(1):LifeVit_Vital_SpO2.("Time SpO2")(end);
Wellue_Data_int = interp1(Wellue_Data.Time,double(Wellue_Data.SpO2), ...
                           interpolationTime);
LifeVit_Vital_SpO2_int = interp1(LifeVit_Vital_SpO2.("Time SpO2"), ...
    LifeVit_Vital_SpO2.SpO2,interpolationTime);

% The las figure to check if the interpolation was good or not
figure;
plot(interpolationTime,Wellue_Data_int, ...
    interpolationTime,LifeVit_Vital_SpO2_int,"LineWidth",1.5);
xlim ([interpolationTime(1) interpolationTime(end)])
legend('Wellue Oximeter','LifeVit Vital');
title("Volunteer 3 | Position: Lay | SpO2 interpolation");

% Sometimes due to the interpolation can appear new NaN values that we
% don't want to analyze for that reason we will delete all this values
interpolationTime (1) = [];
Wellue_Data_int (1) = [];
LifeVit_Vital_SpO2_int(1) = [];

cd ..

% Creation of new table with SpO2 values of interest
SpO2Final = table(Wellue_Data_int', ...  % Wellue SpO2 Final Data
    LifeVit_Vital_SpO2_int', ...  % LifeVit Vital SpO2 Final Data
    NaN*ones(length(LifeVit_Vital_SpO2_int),1), ... % Respiration Final Data
    2*ones(length(LifeVit_Vital_SpO2_int),1), ... % Volunteer #
    repmat("Workout",length(LifeVit_Vital_SpO2_int),1), ... % Position of Data (Lay, Sit, Stand or Workout)
    'VariableNames', FinalSpO2Data.Properties.VariableNames);

% Concatenation of previous table and new SpO2 data
FinalSpO2Data = [FinalSpO2Data; SpO2Final];

%% POST-ANALYSIS SECTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Short code section that provide the researcher to save the new tables   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

save('FinalHRData.mat', 'FinalHRData');
save('FinalSpO2Data.mat', 'FinalSpO2Data');

%% FUNCTIONS SECTION
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Section which contains all the functions used in the script porperly    %
% commented.                                                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Function that transforms the .txt file recorded by the LifeVit Vital
% wearable to matlab format.
function [LifeVit_Vital_HR, LifeVit_Vital_SpO2] = transformLifevitFile ()

    % Read The .txt file with the data obtained by LifeVit Vital and obtain
    % the index of the HR and SpO2 data.
    LifeVit_Vital = table2cell(readtable(uigetfile('.txt'),Delimiter='\r\n', Encoding='UTF-8'));
    IndexHR = find(contains(LifeVit_Vital(:,1), 'Heart_Rate_Data_Obtained:'));
    IndexSpO2 = find(contains(LifeVit_Vital(:,1), 'SpO2_Data_Obtained:'));
    
    % To split and delete caracters not desired and relocate the data 
    % per biosignals.
    LifeVit_Vital_HR = regexprep(strsplit(LifeVit_Vital{IndexHR+1,1}),"[[],]"," ");
    LifeVit_Vital_SpO2 = regexprep(strsplit(LifeVit_Vital{IndexSpO2+1,1}),"[[],]"," ");
    
    % Arranged the different biosignal data into two columns
    % differentiating the data type as time or measure
    LifeVit_Vital_HR = [LifeVit_Vital_HR(1:2:end)' LifeVit_Vital_HR(2:2:end)'];
    LifeVit_Vital_SpO2 = [LifeVit_Vital_SpO2(1:2:end)' LifeVit_Vital_SpO2(2:2:end)'];
    
    % Now, we create two different tables allocating time in the
    % following format "HH:mm:ss.SSS" in order to evaluate better the data recorded and
    % in the second column the value of SpO2 or HR in double type
    LifeVit_Vital_HR = table(...
        datetime(str2double(LifeVit_Vital_HR(:,1))./1000, ...
        'ConvertFrom', 'posixtime', 'Format', 'HH:mm:ss.SSS','TimeZone','Europe/Madrid'), ...
        str2double(LifeVit_Vital_HR(:,2)), ...
        'VariableNames', {'Time HR','HR'});
    
    LifeVit_Vital_SpO2 = table(...
        datetime(str2double(LifeVit_Vital_SpO2(:,1))./1000, ...
        'ConvertFrom', 'posixtime', 'Format', 'HH:mm:ss.SSS','TimeZone','Europe/Madrid'), ...
        str2double(LifeVit_Vital_SpO2(:,2)), ...
        'VariableNames', {'Time SpO2','SpO2'});
    
    % As we want to plot the data over the time, we cast the previous table
    % to timetable in order to be able to plot correctly and compare as we
    % want
    
    LifeVit_Vital_HR = table2timetable(LifeVit_Vital_HR);
    LifeVit_Vital_SpO2 = table2timetable(LifeVit_Vital_SpO2);
    
end

function [r,yfdds,k]=qrsDetector(y,fs)

    [b,a]=butter(4,30*2/fs);
    yf=filtfilt(b,a,y);
    yfd=diff(yf);
    yfds=(round(yfd/max(yfd)));
    yfdds=diff(yfds);
    k=find(yfdds);
    l=length(k);
    t=1;
    
    for i=1:l-1
	    %if (k(i+1)-k(i))>round(300*fs/(2*fs)) %All the volunteers excepts #19 and Workout
        if (k(i+1)-k(i))>round(0.300*fs/2) % Only #19 and workout
		    t=t+1;
	    end
	    r(t)=k(i);	
    
    end
    
    %d=round(200*fs/(2*fs)); %All the volunteers excepts #19 and Workout
    d=round(0.200*fs/2); % Only #19 and workout
    for i=1:length(r) 
	    
        a=yf(r(i)-d:r(i));
	    [m,n]=max(a);
	    r(i)=r(i)+n-d;
    
    end
    
    rr=diff(r);
    [q,s]=min(rr);
    
    if q<(mean(rr)-3*std(rr))
	    p(1:s-1)=r(1:s-1);
	    p(s:length(r)-1)=r(s+1:length(r));
	    r=p;
    end

end

