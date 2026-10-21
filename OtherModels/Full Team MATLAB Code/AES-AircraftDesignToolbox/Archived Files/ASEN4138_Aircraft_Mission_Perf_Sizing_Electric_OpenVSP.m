%% Aircraft Design Mission Performance Sizing Analysis
% ASEN 4138
% Author: John Mah

% Description:  This program estimates the fuel burn utilized through a
% user defined mission profile through multiple iterations to converge on a
% estimate for aircraft total weight.  User must first model the aircraft
% aerodynamically via the ASEN4138_Aircraft_Design_Aero_Model.m code or via
% Open VSP and provide an initial "guess" at the total aircraft weight to
% begin the iterative process.  The initial guess weight is updated after each
% iteration with the average value between the guess weight and the calculated
% weight at the end of the mission analysis.  Script will stop iterations once the
% aircraft total weight calcluated converges with the initial guess of the
% aircraft total weight within a user defined percentage.

%% Current Version:  AY24.00
% Date Last Change: 1 Aug 24
% Changes in Current Version: Initial Version.
% Functions & files required to execute this script
% All the outputs files from OpenVSP (subsonic 2 files * supersonic 6
% files)
%atmos.m
%DragPolar_OpenVSP.m
%DragPolar_Function.m
%Propulsion.m
%MSN_SEG_TO.m
%MSN_SEG_Climb.m
%MSN_SEG_Cruise.m
%MSN_SEG_Loiter.m


%% Instructions
% Please folow procedure instructions posted to canvas for getting all the
% openVSP analysis integrated into this script. 
% Reminder all variables unique to aircraft configuration should be changes
% in the section right below and the mission segments/profile should be
% changed to reflect YOUR airacfts mission profile. 

%%Initialization
clear; close all; clc; 

%% ALL MANUAL INPUTS LIVE HERE (For each configuration you will need to update these) 
% These inputs allow for varaibles to be input as matrixes which can be switched based
% on the i or iteration number. If only single values leave i as 1. 

Config = 1; %Configuration number

%%% From Design Input Tab or OpenVSP Geometry
% General 
Design_Input.ACType = {'Homebuilt_Composite'}; 
%The options are Jet_Fighter, Jet_Trainer, Jet_Transport, Miliarty_Cargo/Bomber, GA_Single, GA_Twin, Ag_Aircraft, Turboprop_Twin, Flying_Boat, Homebuilt_Metal/wood, Homebuilt_Composite
Design_Input.M_max = [.3];

% Wing
Design_Input.AR_w = [12.04];
Design_Input.Sref_w = [102];
Design_Input.Sweep_w = [0];

% Airfoil
Airfoil.Thick_w = [0.12];

% Propulsion
%Type of propulsion used in design
Propulsion_Input.PropType = {'PROP_Electric'}; 
%The options are PROP_Fuel, PROP_Electric, JET_HBP_Turbofan,JET_LBP_Turbofan
Propulsion_Input.Number = [1]; %Number of engines
Propulsion_Input.TA_mil_sl = [0]; %Per engine static,uninstalled thrust @ s.l.
Propulsion_Input.TSFC_mil_sl = [0]; %TSFC in mil power (lb/hr/lb)
Propulsion_Input.TA_AB_sl = [0]; %Per engine static,uninstalled thrust, w/AB @ s.l.
Propulsion_Input.TSFC_AB_sl = [0]; %TSFC in AB power (lb/hr/lb)
Propulsion_Input.Install_loss = [0]; %Installation loss (% in decimal value)
Propulsion_Input.PA_shp_sl = [70]; %Shaft horsepower for prop engine, uninstalled @ s.l.
Propulsion_Input.SFC_sl = [0]; %SFC (lb/hr/hp)
Propulsion_Input.Prop_eff = [.9]; %Propellor efficiency
Propulsion_Input.Esb_Real = [200.475]; %Battery specific energy after losses (W*hr/kg)
Propulsion_Input.eta_b2s = [.93]; %Battery to shaft efficiency factor. Includes losses due to the following components: motor, motor controller, battery controller, wiring, gearbox (if necessary) etc.  




%%% 
ACType = Design_Input.ACType{Config};
M_max = Design_Input.M_max(Config);
AR = Design_Input.AR_w(Config);
Sref = Design_Input.Sref_w(Config);
Sweep = Design_Input.Sweep_w(Config);
Thick_w = Airfoil.Thick_w(Config);
PropType = Propulsion_Input.PropType{Config};

%%% OpenVSP file names
% all the file names that need to be read in (if subsonic all but the first
% 2 can be left empty)
file_location = "Validation Test Files/C172 VSP Analysis Files/"; %if you have a seperate folder where you store all the output OpenVSP files please put them here. If not leave it as ""

sub_parasite_file_name = {"X_parasite_C172_M03"};
sub_aero_file_name = {"X_c172_M03.xlsx"};

peakWave_wave_file_name = {""};
peakWave_parasite_file_name = {""};
maxDesign_wave_file_name = {""};
maxDesign_parasite_file_name = {""};

%% AIRCRAFT WEIGHT AND GEOMETRY INPUTS

%Start Mission Sizing Iterations
Diff_W0 = 1; %Set initial value in total weight difference to 100% or 1

%Initial Total Aircraft Weight Guess
W0_guess = 2500; %Base initial guess on similar type/mission aircraft

%Crew,Passenger,Payload Weights (Design Requirements)
W_crew = 250; %lb
W_pay_fixed = 0; %lb
W_pay_drop = 0; %lb

%Constants 
g = 32.2; %Accel of gravity (ft/s^2);

% Added to ensure the Drag Function still functions properly without any
% changes
WaveDrag_Data.M_DD = 1 - 0.065*(cosd(Design_Input.Sweep_w)).^0.6.*(100*Airfoil.Thick_w).^0.6 + 0.08; %Estimation of critical mach value (Brandt)
WaveDrag_Data.M_max_design = Design_Input.M_max;

for wd = 1:length(Design_Input.M_max) %needs to run through all configs seperately 
    if WaveDrag_Data.M_DD(wd) < WaveDrag_Data.M_max_design(wd)
        WaveDrag_Data.M_wave_max(wd) = 1/(cosd(Design_Input.Sweep_w(wd)).^0.2); %Estimation of mach for max wave drag rise (Brandt). Value ~1.05 typically.
    else
        WaveDrag_Data.M_wave_max(wd) = 0;
    end
end

%% PROPULSION INPUTS
%Jet Engine Values (if propellor propulsion, set all to zero)
TA_mil_sl = Propulsion_Input.Number(Config)*Propulsion_Input.TA_mil_sl(Config); %Uninstalled Mil power total thrust at sea level (all engines)
TA_AB_sl = Propulsion_Input.Number(Config)*Propulsion_Input.TA_AB_sl(Config); %Uninstalled AB power total thrust at sea level (all engines)
TSFC_mil_sl = Propulsion_Input.TSFC_mil_sl(Config);
TSFC_AB_sl = Propulsion_Input.TSFC_AB_sl(Config);
%Prop Engine Values (if jet propulsion, set all to zero)
PA_shp_sl = Propulsion_Input.Number(Config)*Propulsion_Input.PA_shp_sl(Config); %shaft horsepower from engine at sea level (hp) total (all engines)
SFC_sl = Propulsion_Input.SFC_sl(Config); %specific fuel consumption for prop engine at sea level (lb/(hp*s))
Prop_Eff = Propulsion_Input.Prop_eff(Config);

%% PACKAGE CONSTANTS AND ATMOSPHERE
Constants = {Config,AR,Sref,M_max,g,PropType}; %Package for use in functions

%Set sea level std atmosphere values
[rho_sl,a_sl,T_sl,P_sl,nu_sl,z_sl] = atmos(0,'units','US'); %sea level std atmosphere properties

%% OPEN VSP FUNCTION TO MAKE DRAG POLARS
% need to loop through all the configs to make string arrays with all the
% names of the files so drag polar open vsp can pul the correct files
for dp = 1:length(Design_Input.M_max)
    sub_parasite{dp} = strcat(file_location,sub_parasite_file_name{dp});
    sub_aero{dp} = strcat(file_location,sub_aero_file_name{dp});
    
    peakWave_wave{dp} = strcat(file_location,peakWave_wave_file_name{dp});
    peakWave_parasite{dp} = strcat(file_location,peakWave_parasite_file_name{dp});
    maxDesign_wave{dp} = strcat(file_location,maxDesign_wave_file_name{dp});
    maxDesign_parasite{dp} = strcat(file_location,maxDesign_parasite_file_name{dp});
end

DragPolar_Model = DragPolar_OpenVSP(Design_Input,WaveDrag_Data,sub_parasite,sub_aero,peakWave_wave,peakWave_parasite,maxDesign_wave,maxDesign_parasite,length(Design_Input.M_max)); 

%% MISSION ANALYSIS ITERATIVE SIZING
%Set Convergence Criteria
Converge = 0.005; %Sets the percent difference between W0_guess and W0_calc to determine solution has converged

[a,b,c1,c2,c3,c4,c5]= WeightModel(PropType,ACType);
Kvs = 1; %From Raymer Table 6.1 based on variable sweep (1.04) or fixed sweep (1.0)
Composite_Factor=.9;

i=1; %Weight iteration number initlization

while Diff_W0 >= Converge

    %Calculate Aircraft Parameters & Empty Weight based on Total Weight
    %(W0) and statistical model
    disp("Weight Sizing Iteration:"+ num2str(i))
    if strcmp(PropType,'PROP_Electric')
        Power_Weight_Ratio = PA_shp_sl/W0_guess; %in hp/lb (shaft hp at sea level)
        V_max = (M_max*a_sl)*(3600/6076); %Max velocity in terms of knots (must convert ft/s to knots using 6076 ft per nautical mile and 3600 sec per hr).
        WingLoading = W0_guess/Sref;

        %Statistical empty weight fraction model for prop aircaft
        We_W0 =(a + b*(W0_guess)^c1*(AR)^c2*(Power_Weight_Ratio)^c3*(WingLoading)^c4*(V_max)^c5)*Kvs;
        We = We_W0*W0_guess; %Empty weight of aircraft (lb)
    else
        error("Only Propulsion Type 'PROP_Electric' is supported")
    end

    We_W0=Composite_Factor*We_W0;
   %% MISSION PROFILE START: EDIT SEQUENCING OF SEGMENTS AS REQUIRED
    %% Mission Segment 1
    TO_alt=0;%take off altitude [ft]
    CL_max_TO = 1.4; %Max coefficient of lift obtained in takeoff configuration
    Roll_Fric = 0.02; %Coefficient of rolling friction based on runway type

    W_start=W0_guess;

    %Takeoff Segment: Takeoff
    [bmf1,TO1_DATA] = MSN_SEG_TO_Elec(TO_alt,CL_max_TO,Roll_Fric,W_start,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data);

    %Climb Segment: Climb from 0 to 10000ft
    Climb_Alt_Start=0;%[ft]
    Climb_Alt_End=1500;%[ft]
    Climb_Mach_Start=0.10;
    Climb_Mach_End=.1;
    [bmf2,CLIMB1_DATA]=MSN_SEG_Climb_Elec(Climb_Alt_Start,Climb_Alt_End,Climb_Mach_Start,Climb_Mach_End,W_start,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data);

    %Stated endurance of aircraft
    Loiter_Alt=1500;%[feet]
    E_loiter=(50)/60;%[hours]
    [bmf3,LOITER1_DATA] = MSN_SEG_Loiter_Elec(Loiter_Alt,E_loiter,W_start,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data);

    %Cruise Phase for demonstration of a cruise mission segment
    Cruise_Alt_Start=1500;
    R_Cruise=15;
    Cruise_M=.08;
    [bmf4,CRUISE1_DATA]= MSN_SEG_Cruise_Elec(Cruise_Alt_Start,R_Cruise,Cruise_M,W_start,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data);

    %Landing and Reserves has been modeled as a short Loiter Segment.
    Loiter_Alt=1500;%[feet]
    E_loiter=(10)/60;%[hours]
    [bmf5,LOITER2_DATA] = MSN_SEG_Loiter_Elec(Loiter_Alt,E_loiter,W_start,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data);

    %summing total BMF and calculating W0
    BMF=bmf1+bmf2+bmf3+bmf4+bmf5; %total BMF
    W0_calc=(W_crew+W_pay_fixed)/(1-BMF-We_W0);
    if W0_calc<0
        error("W0_calc <0: Mission profile failed to converge. This could be due to a physically impossible mission profile, a bad initial guess, or limitations of the model (e.g weight model).")
    end
    %calculating error from last W0 guess
    Diff_W0 = abs(W0_guess-W0_calc)/W0_guess;
    %% Write Weight iteration Data
    %this will need to be updated with bmfn for the nth mission segment
    SizingStruct(i).W0_guess=W0_guess; %#ok<*SAGROW> 
    SizingStruct(i).bmf1=bmf1;
    SizingStruct(i).bmf2=bmf2;
    SizingStruct(i).bmf3=bmf3;
    SizingStruct(i).bmf4=bmf4;
    SizingStruct(i).bmf5=bmf5;

    SizingStruct(i).BMF=BMF;


    %% Next Iteration Update
    
    i=i+1;
    W0_guess=(W0_calc+W0_guess)/2;
end
%% Table sizing for electric Prop only
Msn_Sizing_Table=struct2table(SizingStruct);
disp(Msn_Sizing_Table)
if strcmp(PropType,'PROP_Electric')
    fprintf("Table with Relevant Information\n\n")
    tableNames = {'W0 (lb)', 'Battery weight(lb)', 'We(lb)', 'Wing Loading(lb/ft^2)','P/W(hp/lb)'};
    outputTable = table(W0_calc,BMF*W0_calc,We,WingLoading,Power_Weight_Ratio, 'VariableNames', tableNames);
    disp(outputTable)
else
    error("Only PropType 'PROP_Electric' is supported")
end














