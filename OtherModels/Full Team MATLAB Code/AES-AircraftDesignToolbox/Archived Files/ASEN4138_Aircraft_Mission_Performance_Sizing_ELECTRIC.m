%% Aircraft Design Mission Performance Sizing Analysis
% ASEN 4138
% Author: John Mah, Jonathan Morris

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
%4138_Design Input File_V24-00.xlsx
%ASEN 4138_Aircraft_Design_Aero_Model_Main.m
%atmos.m
%DragPolar.m
%DragPolar_Function.m
%InducedDrag.m
%LD.m
%ParasiteDrag.m
%Propulsion.m
%WaveDrag.m
%WingGeo.m
%WingLiftDrag.m
%MSN_SEG_TO_Elec.m
%MSN_SEG_Climb_Elec.m
%MSN_SEG_Cruise_Elec.m
%MSN_SEG_Loiter_Elec.m
%WeightModel.m


%% Instructions
% During initial conceptual evaluation, the ASEN4138_Aircraft_Design_Aero_Model_Main.m script
% should be executed prior to utilization of this code to create the drag polar and propulsion
% properties of the aircraft configuration concept required to run a
% mission performance sizing. However, after refining and modeling the
% concept in OPEN VSP, you should hard-code OPEN VSP values into tge drag polar values into the
% DragPolar_Function.m fuction and update any propulsion static sea level values in
% the Propulsion.m function.

%%Initialization
%Clear Mission Analyis Variables
clear SizingStruct Msn_Sizing_Table MsnStruct


%Start Mission Sizing Iterations
i = 1; %Iteration number
Diff_W0 = 1; %Set initial value in total weight difference to 100% or 1

%% AIRCRAFT WEIGHT AND GEOMETRY INPUTS
%Initial Total Aircraft Weight Guess
%Base initial guess on similar type/mission aircraft


%Aircraft Type (For empty weight fraction calculation)


%Crew,Passenger,Payload Weights (Design Requirements)
W_crew = 375; %lb
W_pay_fixed = 0; %lb
W_pay_drop = 0; %lb

%Aircraft Geometry Constants (either from ASEN4138_Aircaft_Design_Aero_Model.m or
%manually inputted via OPEN VSP)
Config_Row = 1; %Pick row in design input file for configuration being evaluated
AR = Design_Input.AR_w(Config_Row);
Sref = Design_Input.Sref_w(Config_Row);
M_max = Design_Input.M_max(Config_Row);
g = 32.2; %Accel of gravity (ft/s^2);
ACType=Design_Input.ACType(Config_Row);

%% PROPULSION INPUTS
%Type of propulsion used in design
PropType = Propulsion_Input.PropType(Config_Row); %Determine if jet or prop propulsion
%Jet Engine Values (if propellor propulsion, set all to zero)
TA_mil_sl = Propulsion_Input.TA_mil_sl(Config_Row);
TA_AB_sl = Propulsion_Input.TA_AB_sl(Config_Row);
TSFC_mil_sl = Propulsion_Input.TSFC_mil_sl(Config_Row);
TSFC_AB_sl = Propulsion_Input.TSFC_AB_sl(Config_Row);
%Prop Engine Values (if jet propulsion, set all to zero)
PA_shp_sl = Propulsion_Input.PA_shp_sl(Config_Row); %shaft horsepower from engine at sea level (hp)
SFC_sl = Propulsion_Input.SFC_sl(Config_Row); %specific fuel consumption for prop engine at sea level (lb/(hp*s))
Prop_Eff = Propulsion_Input.Prop_eff(Config_Row);
NumEng=Propulsion_Input.Number(Config_Row);

%% PACKAGE CONSTANTS AND ATMOSPHERE

Constants = {Config_Row,AR,Sref,M_max,g,PropType}; %Package for use in functions

%Set sea level std atmosphere values
[rho_sl,a_sl,T_sl,P_sl,nu_sl,z_sl] = atmos(0,'units','US'); %sea level std atmosphere properties

%% MISSION ANALYSIS ITERATIVE SIZING
%Set Convergence Criteria
Converge = 0.005; %Sets the percent difference between W0_guess and W0_calc to determine solution has converged

[a,b,c1,c2,c3,c4,c5]= WeightModel(PropType,ACType);
Kvs = 1; %From Raymer Table 6.1 based on variable sweep (1.04) or fixed sweep (1.0)
W0_guess = 2500;
Composite_Factor=.9; %Using the composite homebuilt model it was found that multiplying the empty weight fraction by .8-.9 lined up more closely with serial produced composite aircraft. The Raymer text reccomends a similar approach.
while Diff_W0 >= Converge

    %Calculate Aircraft Parameters & Empty Weight based on Total Weight
    %(W0) and statistical model
    disp("Iteration:"+num2str(i))
    if strcmp(PropType,'PROP_Electric')
        Power_Weight_Ratio = NumEng*PA_shp_sl/W0_guess; %in hp/lb
        V_max = (M_max*a_sl)*(3600/6076); %Max velocity in terms of knots (must convert ft/s to knots using 6076 ft per nautical mile and 3600 sec per hr).
        WingLoading = W0_guess/Sref;
        %WingLoading
        %test=0;
        %Statistical empty weight fraction model for prop aircaft
        We_W0 =Composite_Factor*(a + b*(W0_guess)^c1*(AR)^c2*(Power_Weight_Ratio)^c3*(WingLoading)^c4*(V_max)^c5)*Kvs;
        We = We_W0*W0_guess; %Empty weight of aircraft (lb)
    else
        error("Only PropType: 'PROP_Electric is supported")
    end

    %% MISSION PROFILE START: EDIT SEQUENCING OF SEGMENTS AS REQUIRED
    %% Mission Segment 1
    Constants = {Config_Row,AR,Sref,M_max,g,PropType}; %Package for use in functions
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










