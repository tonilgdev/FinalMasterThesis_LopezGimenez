clear all;
clc;

%%Iterator for save all the data
i = 1;

%%Check the devices names, Address ,etc. It will be commented due to it's
%%not necessary for our current measurement.
%blelist;

%%Connect to the device with a specific MAC address
device = ble("BA:03:8C:20:27:65");

%% creates an object for a characteristic using its UUID and the service UUID. 
% Identify serviceUUID and characteristicUUID
% c = characteristic(deviceName,serviceUUID,characteristicUUID)
carac = characteristic(device,"FFE0","FFE4"); %Characteristic that returns HR and SpO2.

%% Subscription to "data" chracteristic
subscribe(carac);
reply=read(carac); %We measure one time to control the following while loop

%reply(1)="254" in DEC (FE in HEX) is the value that represents a new notification value
%reply(3)==86 or 85 are the values that valid data
while(reply(1)==254)
  
    if(length(reply)==10) % That is the length that allow us to obtain the relevant information for this aim
        Heart_Rate (i,:)= typecast([uint8(reply(5)),uint8(reply(4))],'uint16');
        SpO2(i,:) = uint16(reply(6));
        Perfusion_Index(i,:)= typecast([uint8(reply(8)),uint8(reply(7))],'uint16')/1000;
        Time(i,:) = datetime('now','TimeZone','Europe/Madrid','Format','HH:mm:ss.SSS');
        Wellue_Data = table(Heart_Rate,SpO2,Perfusion_Index,Time)
        i = i+1;
    end

    reply=read(carac); %Reading continuosly the notifications

    if(length(reply)==10 && reply(6)==127) % If the Wellue Oximeter send us an abnormal value the code must stop
        break;
    end

end

Wellue_Data = table2timetable(Wellue_Data); % Cast the format to a timetable to manage better the data

