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
%MSN_SEG_TO.m
%MSN_SEG_Climb.m
%MSN_SEG_Cruise.m
%MSN_SEG_Loiter.m


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
W0_guess = 3000; %Base initial guess on similar type/mission aircraft


%Crew,Passenger,Payload Weights (Design Requirements)
W_crew = 250; %lb
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
TA_mil_sl = Propulsion_Input.Number(Config_Row)*Propulsion_Input.TA_mil_sl(Config_Row); %Uninstalled Mil power total thrust at sea level (all engines)
TA_AB_sl = Propulsion_Input.Number(Config_Row)*Propulsion_Input.TA_AB_sl(Config_Row); %Uninstalled AB power total thrust at sea level (all engines)
TSFC_mil_sl = Propulsion_Input.TSFC_mil_sl(Config_Row);
TSFC_AB_sl = Propulsion_Input.TSFC_AB_sl(Config_Row);
%Prop Engine Values (if jet propulsion, set all to zero)
PA_shp_sl = Propulsion_Input.Number(Config_Row)*Propulsion_Input.PA_shp_sl(Config_Row); %shaft horsepower from engine at sea level (hp) total (all engines)
SFC_sl = Propulsion_Input.SFC_sl(Config_Row); %specific fuel consumption for prop engine at sea level (lb/(hp*s))
Prop_Eff = Propulsion_Input.Prop_eff(Config_Row);

%% PACKAGE CONSTANTS AND ATMOSPHERE
if strcmp(PropType,'PROP_Fuel')|strcmp(PropType,'PROP_Electric')
    Constants = {Config_Row,AR,Sref,M_max,g,PropType}; %Package for use in functions
else
    Constants = {Config_Row,AR,Sref,M_max,g,PropType}; %Package for use in functions
end

%Set sea level std atmosphere values
[rho_sl,a_sl,T_sl,P_sl,nu_sl,z_sl] = atmos(0,'units','US'); %sea level std atmosphere properties

%% MISSION ANALYSIS ITERATIVE SIZING
%Set Convergence Criteria
Converge = 0.005; %Sets the percent difference between W0_guess and W0_calc to determine solution has converged

[a,b,c1,c2,c3,c4,c5]= WeightModel(PropType,ACType);
Kvs = 1; %From Raymer Table 6.1 based on variable sweep (1.04) or fixed sweep (1.0)
Composite_Factor=1;
while Diff_W0 >= Converge

    %Calculate Aircraft Parameters & Empty Weight based on Total Weight
    %(W0) and statistical model
    disp("Iteration:"+ num2str(i))
    if strcmp(PropType,'PROP_Fuel')|strcmp(PropType,'PROP_Electric')
        Power_Weight_Ratio = PA_shp_sl/W0_guess; %in hp/lb (shaft hp at sea level)
        V_max = (M_max*a_sl)*(3600/6076); %Max velocity in terms of knots (must convert ft/s to knots using 6076 ft per nautical mile and 3600 sec per hr).
        WingLoading = W0_guess/Sref;

        %Statistical empty weight fraction model for prop aircaft
        We_W0 = (a + b*(W0_guess)^c1*(AR)^c2*(Power_Weight_Ratio)^c3*(WingLoading)^c4*(V_max)^c5)*Kvs;
        We = We_W0*W0_guess; %Empty weight of aircraft (lb)
    else
        Thrust_Weight_Ratio_mil = TA_mil_sl/W0_guess; %Uninstalled thrust at sea level/Wo
        Thrust_Weight_Ratio_AB = TA_AB_sl/W0_guess; %Uninstalled thrust at sea level/Wo
        Thrust_Weight_Ratio = max(Thrust_Weight_Ratio_AB,Thrust_Weight_Ratio_mil); %Size based on max value of T/W
        WingLoading = W0_guess/Sref;
        %Statistical empty weight fraction model for jet aircaft
        We_W0 = (a + b*(W0_guess)^c1*(AR)^c2*(Thrust_Weight_Ratio)^c3*(WingLoading)^c4*(M_max)^c5)*Kvs;
        We = We_W0*W0_guess; %Empty weight of aircraft (lb)
    end
    %correction for serial composite production when using homebuilt
    %composite model
    We_W0=We_W0*Composite_Factor;
    %% MISSION PROFILE START: EDIT SEQUENCING OF SEGMENTS AS REQUIRED
    %% Mission Segment 1

    % Start, Taxi, Weight Fraction Model
    W1_W0 = 0.97; %Historical estimate of start, taxi (typically between 0.97 - 0.99)

    % Segment 1 Weights
    W1 = W1_W0*W0_guess; %Aircraft weight at end of segment 1 (lb)
    W_fuel_1 = W0_guess-W1; %Fuel used during segment 1 (lb)

    %% Mission Segment 2

    % MSN SEGMENT TYPE: Takeoff & Acceleration Weight Fraction Model
    %Takeoff-Acceleration Inputs
    TO_alt = 0; %Takeoff altitude (ft)
    CL_max_TO = 1.2; %Max coefficient of lift obtained in takeoff configuration
    Roll_Fric = 0.02; %Coefficient of rolling friction based on runway type
    W_start = W1; %Aircraft weight at start of segment

    %Call Segment Type Function ((Make sure to update Weight Fraction
    %output variable to reflect mssion segment and W_start input to
    %be prior segment weight variable)
    [W2_W1,TO_DATA] = MSN_SEG_TO(TO_alt,CL_max_TO,Roll_Fric,W_start,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data);

    %Record Takeoff Performance Data
    MsnStruct.Seg2(i) = table2struct(TO_DATA);

    %Segment 2 Weights
    W2 = W2_W1*W1; %Aircraft weight at end of segment 2 (lb)
    W_fuel_2 = W1 - W2; %Fuel Used during segment 2 (lb)

    %% Mission Segment 3

    % MSN SEGMENT TYPE: Climb Weight Fraction Model
    %Climb Inputs
    Climb_Alt_Start = 0; %Starting climb altitude (ft)
    Climb_Alt_End = 6000; %Ending Climb altitude (ft)
    Climb_M_Start = 0.1; %Starting climb mach
    Climb_M_End = 0.18; %Ending climb mach
    W_start = W2; %Update with prior segment end weight variable

    %Call Segment Type Function (Make sure to update Weight Fraction
    %output variable to reflect mssion segment and W_start input to
    %be prior segment weight variable)
    [W3_W2,CLIMB_DATA_1] = MSN_SEG_Climb(Climb_Alt_Start,Climb_Alt_End,Climb_M_Start,Climb_M_End,W_start,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data);
    %Record Segment 3 Data
    MsnStruct.Seg3(i) = table2struct(CLIMB_DATA_1);

    %Segment 3 Weights
    W3 = W3_W2*W2; %Aircraft weight at end of segment 3 (lb)
    W_fuel_3 = W2 - W3; %Fuel Used during segment 3 (lb)

    %% Mission Segment 4

    % MSN SEGMENT TYPE: Climb Weight Fraction Model
    %Inputs
    Climb_Alt_Start = 6000; %Starting climb altitude (ft)
    Climb_Alt_End = 12000; %Ending Climb altitude (ft)
    Climb_Mach_Start = 0.18; %Starting climb mach
    Climb_Mach_End = 0.18; %Ending climb mach
    W_start = W3; %Update with prior segment end weight variable

    %Call Segment Type Function (Make sure to update Weight Fraction
    %output variable to reflect mssion segment and W_start input to
    %be prior segment weight variable)
    [W4_W3,CLIMB_DATA_2] = MSN_SEG_Climb(Climb_Alt_Start,Climb_Alt_End,Climb_Mach_Start,Climb_Mach_End,W_start,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data);


    %Record Segment 4 Data
    MsnStruct.Seg4(i) = table2struct(CLIMB_DATA_2);

    %Segment 4 Weights
    W4 = W4_W3*W3; %Aircraft weight at end of segment 4 (lb)
    W_fuel_4 = W3 - W4; %Fuel Used during segment 4 (lb)

    %% Mission Segment 5

    % Cruise Weight Fraction Model (Constant velocity, Constant L/D,
    % Changing Altitude)
    %Inputs
    Cruise_Alt_Start = 12000; %Starting cruise altitude (ft).  Will vary as fuel burns.
    R_cruise = 675; %Design cruise range for segment (in nautical miles)
    Cruise_M = 0.172; %Desired design mach for cruise leg
    W_start = W4; %Update with prior segment end weight variable

    %Call Segment Type Function (Make sure to update Weight Fraction
    %output variable to reflect mssion segment and W_start input to
    %be prior segment weight variable)
    [W5_W4,CRUISE_DATA] = MSN_SEG_Cruise(Cruise_Alt_Start,R_cruise,Cruise_M,W_start,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data);

    %Record Segment 5 Data
    MsnStruct.Seg5(i) = table2struct(CRUISE_DATA);

    %Segment 5 Weights
    W5 = W5_W4*W4; %Aircraft weight at end of segment 5 (lb)
    W_fuel_5 = W4 - W5; %Fuel Used during segment 5 (lb)

    %% Mission Segment 6

    % Descent Fraction Model
    W6_W5 = 0.99; %Historical estimate of decent fuel fraction

    %Record Segment 6 Data
    %MsnStruct.Seg6(i) = table2struct(SEG_DATA);

    %Segment 6 Weights
    W6 = W6_W5*W5; %Aircraft weight at end of segment 6 (lb)
    W_fuel_6 = W5 - W6; %Fuel Used during segment 6 (lb)

    %% Mission Segment 7

    % Land Weight Fraction Model
    W7_W6 = 0.992; %Historical estimate of landing fuel fraction (typically between 0.992 - 0.997)

    %Record Segment 7 Data
    %MsnStruct.Seg7(i) = table2struct(SEG_DATA);

    %Segment 7 Weights
    W7 = W7_W6*W6; %Aircraft weight at end of segment 7 (lb)
    W_fuel_7 = W6 - W7; %Fuel Used during segment 7 (lb)

    %% Calculate Total Fuel Weight Used
    %Total mission fuel (plus additional 6% for trapped fuel and reserve)
    W_f_msn = [W_fuel_1,W_fuel_2,W_fuel_3,W_fuel_4,W_fuel_5,W_fuel_6,W_fuel_7];
    W_f_total = 1.06*sum(W_f_msn); %Extra 6% accounts for trapped fuel and reserves

    %% Calculate New W0
    W0_calc = W_crew + W_pay_fixed + W_pay_drop + W_f_total + We;

    %% Calc Difference Between W0_guess and W0_calc
    Diff_W0 = abs(W0_guess-W0_calc)/W0_guess;

    %% Write Weight Iteration Data

    SizingStruct.W0_guess(i) = W0_guess;
    SizingStruct.W1_W0(i) = W1_W0;
    SizingStruct.W1(i) = W1;
    SizingStruct.Wf_1(i) = W_fuel_1;
    SizingStruct.W2_W1(i) = W2_W1;
    SizingStruct.W2(i) = W2;
    SizingStruct.Wf_2(i) = W_fuel_2;
    SizingStruct.W3_W2(i) = W3_W2;
    SizingStruct.W3(i) = W3;
    SizingStruct.Wf_3(i) = W_fuel_3;
    SizingStruct.W4_W3(i) = W4_W3;
    SizingStruct.W4(i) = W4;
    SizingStruct.Wf_4(i) = W_fuel_4;
    SizingStruct.W5_W4(i) = W5_W4;
    SizingStruct.W5(i) = W5;
    SizingStruct.Wf_5(i) = W_fuel_5;
    SizingStruct.W6_W5(i) = W6_W5;
    SizingStruct.W6(i) = W6;
    SizingStruct.Wf_6(i) = W_fuel_6;
    SizingStruct.W7_W6(i) = W7_W6;
    SizingStruct.W7(i) = W7;
    SizingStruct.Wf_7(i) = W_fuel_7;
    SizingStruct.Wf_tot(i) = W_f_total;
    SizingStruct.We_W0(i) = We_W0;
    SizingStruct.We(i) = We;
    SizingStruct.W0_calc(i) = W0_calc;
    SizingStruct.Diff_W0(i) = Diff_W0;

    %% Next Iteration Update
    i = i + 1;
    W0_guess = (W0_guess+W0_calc)/2;

end

%%Data Tables and Visualizations
%Convert data structure to table
T_SizingStruct = structfun(@transpose, SizingStruct, 'UniformOutput', false); %transpose data in structues for ease of reading
Msn_Sizing_Table = struct2table(T_SizingStruct);

% % Added in tables for easy display purposes (for jet aircraft, comment out
% % for prop)
% fprintf("Table with Relevent Information\n\n")
% tableNames = {'W0', 'Wf total', 'We', 'Wing Loading','T/W mil', 'T/W AB'};
% outputTable = table(W0_calc,W_f_total,We,WingLoading,Thrust_Weight_Ratio_mil,Thrust_Weight_Ratio_AB, 'VariableNames', tableNames);
% disp(outputTable)

% Added in tables for easy display purposes (changes to P/W if prop vs T/W
% for jet)
if strcmp(PropType,'PROP_Fuel')|strcmp(PropType,'PROP_Electric')
    fprintf("Table with Relevant Information\n\n")
    tableNames = {'W0(lb)', 'Wf total(lb)', 'We(lb)', 'Wing Loading(lb/ft^2)','P/W(hp/lb)'};
    outputTable = table(W0_calc,W_f_total,We,WingLoading,Power_Weight_Ratio, 'VariableNames', tableNames);
    disp(outputTable)
else
    fprintf("Table with Relevant Information\n\n")
    tableNames = {'W0(lb)', 'Wf total(lb)', 'We(lb)', 'Wing Loading(lb)','T/W mil(lb/lb)', 'T/W AB (lb/lb)'};
    outputTable = table(W0_calc,W_f_total,We,WingLoading,Thrust_Weight_Ratio_mil,Thrust_Weight_Ratio_AB, 'VariableNames', tableNames);
    disp(outputTable)
end














