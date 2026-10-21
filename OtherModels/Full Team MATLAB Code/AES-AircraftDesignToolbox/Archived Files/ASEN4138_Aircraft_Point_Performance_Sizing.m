%% Aircraft Design Point Performance / Constraint Sizing Analysis
% ASEN 4138
% Author: John Mah

% Description:  This program estimates the thrust to weight (T/W) and wing loading
% (W/S) requriements to acheive point performance design requirements for an aircraft.
% Values for T/W and W/S are based on sea level static thrust (T_sl) and total aircraft weigh (Wo).
% Constraint analysis provides a plot showing minimum values of T/W and W/S
% required for multiple user defined point performance requirements which
% define a "design space" of acceptable T/W and W/S combinations.  The
% optimal design point is defined as the lowest T/W and highest W/S combo
% that acheives all point performance requirements.

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


%% Instructions
% During initial conceptual evaluation, the
% ASEN4138_Aircraft_Design_Aero_Model_Main.m script and
% ASEN4138_Aircraft_Mission_Performance_Sizing.m script
% should be executed prior to utilization of this code to create the drag polar and propulsion
% properties of the aircraft configuration concept required to run a
% mission performance sizing. However, after refining and modeling the
% concept in OPEN VSP, you should hard-code OPEN VSP values into tge drag polar values into the
% DragPolar_Function.m fuction and update any propulsion static sea level values in
% the Propulsion.m function.

%%Initialization
%Close prior figures
close all

%Set sea level std atmosphere values & accel of gravity constant
[rho_sl,a_sl,T_sl,P_sl,nu_sl,z_sl] = atmos(0,'units','US'); %sea level std atmosphere properties
g = 32.2; %Accel of gravity (ft/s^2)

%Set aircraft configuration evaluated based on row number in Design Input
Config_Row = 1; %Sets row of design input spreadsheet being evaluated or if using OPEN VSP, the array index of the configuration being evaluated based on Mission Analysis array setup

%Set aircraft total weight from mission analysis sizing (or manually)
Wo = W0_calc; %Pulls final aircraft total weight from value calculated in mission performance sizing. Can manually change if requried.

%Set aircraft initial wing planform area (if using OpenVSP for aero analysis, make sure Config_Row =1 in line 52)
Sref_initial = Design_Input.Sref_w(Config_Row); %MUST UPDATE AFTER RESIZING! You will determine actual Sref needed from selected design point from this analysis.

%Consolidate constants for use in Constraint_Eq function
Constants = {g,Config_Row,Wo,Sref_initial,rho_sl,a_sl}; %Consolidates needed properties in single array

%Define range of wing loading (independent variable) used in analysis
W_S_range = linspace(20,200,100);

%% USER DEFINED POINT PERFORMANCE REQUIREMENTS
% Takeoff, landing and stall only need updated inputs
% Requirements using constraint master equation can be renamed/re-ordered
% as needed based on type of requirement you are assessing

%% TAKEOFF CONSTRAINT REQUIREMENT
TO_REQ_Label = 'Takeoff Dist (mil)';

Beta = 1; %Weight fraction at time of point performance (W/Wo)
h = 0; %Altitude for point performance requirement (ft)
Throttle = 'MIL'; %Defines if jet afterburner thrust ('AB'), jet mil thrust ('MIL'), or propellor power available ('PROP') is used in performance analysis
CL_max_TO = 1.2; %Max coefficient of lift in takeoff configuration (including flaps)
Roll_Fric = 0.02; %Coefficient of rolling friction based on runway surface
CDx = 0.035; %Defines added parasite drag coefficient value not modeled in clean aerodynamics drag polar values due to configuration (landing gear, flaps) or external stores (attached sensors, fuel tanks, munitions, etc.)
S_TO = 3500; %Takeoff groundroll distance requirement (ft)

TO_Req_Inputs = {Beta,h,Throttle,CL_max_TO,Roll_Fric,CDx,S_TO}; %Consolidates inputs into array for input into constraint equation funciton

%Call Takeoff Constraint Equation Function to evaluate point performance above
[T_W_TOreq,P_W_TOreq,TO_REQ_DATA] = Takeoff_Constraint_EQ(TO_Req_Inputs,Constants,W_S_range,Propulsion_Input,DragPolar_Model,WaveDrag_Data);

%% LANDING REQUIREMENT
Land_REQ_Label = 'Landing Dist';

%Landing Req Inputs
Beta = 1; %Weight fraction at time of point performance (W/Wo)
h = 0; %Altitude for point performance requirement (ft)
CL_max_land = 1.2; %Max coefficient of lift in landing configuration (including flaps)
Roll_Fric = 0.5; %Coefficient of braking & rolling friction based on runway surface
CDx = 0.045; %Defines added parasite drag coefficient value for landing gear (see Raymer Table 12.6 for landing gear estimates)
S_Land = 4500; %Landing groundroll distance requirement (ft)

Land_Req_Inputs = {Beta,h,CL_max_land,Roll_Fric,CDx,S_Land}; %Consolidates inputs into array for input into constraint equation funciton

%Call Landing Constraint Equation Function to evaluate point performance above
[W_S_Land_req,Land_REQ_DATA] = Landing_Constraint_EQ(Land_Req_Inputs,Constants,DragPolar_Model,WaveDrag_Data);

%% STALL VELOCITY
Stall_REQ_Label = 'Stall Velocity';

%Stall Velocity Req Inputs
h = 0; %Altitude for point performance requirement (ft)
CL_max_stall = 1.2; %Max coefficient of lift for stall (SLUF)
V_stall_req = 160; %Desired stall velocity in knots (nautical miles per hour)

Stall_Req_Inputs = {h,CL_max_stall,V_stall_req}; %Consolidates inputs into array for input into constraint equation funciton

%Call Stall Constraint Equation Function to evaluate point performance above
[W_S_stall_req,Stall_REQ_DATA] = Stall_Constraint_EQ(Stall_Req_Inputs,Constants);

%% REQ #1: MAX MACH
REQ1_Label = 'Max Mach (AB)';

%REQ1 Req Inputs
Beta = 0.852; %Weight fraction at time of point performance (W/Wo)
h = 20000; %Altitude for point performance requirement (ft)
M = 1.0; %Mach for point performance requirement
n = 1; %Load factor for point performance requirement
Throttle = 'AB'; %Defines if jet afterburner thrust ('AB'), jet mil thrust ('MIL'), or propellor power available ('PROP') is used in performance analysis
P_s = 0; %Rate of Climb req (ft/s) or if point performance requirement must be sustained (P_s = 0) or accomplished with remaining excess power available (P_s > 0) or at a deficit (P_s < 0)
Accel = 0; %Defines any acceleration requirement (ft/s^2). Typically zero for most point performance requirements.
CDx = 0; %Defines added parasite drag coefficient value not modeled in clean aerodynamics drag polar values due to configuration (landing gear, flaps) or external stores (attached sensors, fuel tanks, munitions, etc.)

Req1_Inputs = {Beta,h,M,n,Throttle,P_s,Accel,CDx}; %Consolidates inputs into array for input into constraint equation funciton

%Call Constraint Equation Function to evaluate point performance above
[T_W_req1,P_W_req1,REQ1_DATA] = Master_Constraint_EQ(Req1_Inputs,Constants,W_S_range,Propulsion_Input,DragPolar_Model,WaveDrag_Data);

%% REQ #2: ABSOLUTE CEILING
REQ2_Label = 'Absolute Ceiling (AB)';

%REQ2 Req Inputs
Beta = 0.852; %Weight fraction at time of point performance (W/Wo)
h = 40000; %Altitude for point performance requirement (ft)
M = 0.8; %Mach for point performance requirement
n = 1; %Load factor for point performance requirement
Throttle = 'AB'; %Defines if jet afterburner thrust ('AB'), jet mil thrust ('MIL'), or propellor power available ('PROP') is used in performance analysis
P_s = 0; %Rate of Climb req (ft/s) or if point performance requirement must be sustained (P_s = 0) or accomplished with remaining excess power available (P_s > 0) or at a deficit (P_s < 0)
Accel = 0; %Defines any acceleration requirement (ft/s^2). Typically zero for most point performance requirements.
CDx = 0; %Defines added parasite drag coefficient value not modeled in clean aerodynamics drag polar values due to configuration (landing gear, flaps) or external stores (attached sensors, fuel tanks, munitions, etc.)

Req2_Inputs = {Beta,h,M,n,Throttle,P_s,Accel,CDx}; %Consolidates inputs into array for input into constraint equation funciton

%Call Constraint Equation Function to evaluate point performance above
[T_W_req2,P_W_req2,Req2_REQ_DATA] = Master_Constraint_EQ(Req2_Inputs,Constants,W_S_range,Propulsion_Input,DragPolar_Model,WaveDrag_Data);

%% REQ #3: SERVICE CEILING
REQ3_Label = 'Service Ceiling (mil)';

%REQ3 Req Inputs
Beta = 0.852; %Weight fraction at time of point performance (W/Wo)
h = 35000; %Altitude for point performance requirement (ft)
M = 0.8; %Mach for point performance requirement
n = 1; %Load factor for point performance requirement
Throttle = 'MIL'; %Defines if jet afterburner thrust ('AB'), jet mil thrust ('MIL'), or propellor power available ('PROP') is used in performance analysis
P_s = 1.67; %Rate of Climb req (ft/s) or if point performance requirement must be sustained (P_s = 0) or accomplished with remaining excess power available (P_s > 0) or at a deficit (P_s < 0)
Accel = 0; %Defines any acceleration requirement (ft/s^2). Typically zero for most point performance requirements.
CDx = 0; %Defines added parasite drag coefficient value not modeled in clean aerodynamics drag polar values due to configuration (landing gear, flaps) or external stores (attached sensors, fuel tanks, munitions, etc.)

Req3_Inputs = {Beta,h,M,n,Throttle,P_s,Accel,CDx}; %Consolidates inputs into array for input into constraint equation funciton

%Call Constraint Equation Function to evaluate point performance above
[T_W_req3,P_W_req3,Req3_REQ_DATA] = Master_Constraint_EQ(Req3_Inputs,Constants,W_S_range,Propulsion_Input,DragPolar_Model,WaveDrag_Data);

%% REQ #4: SUSTAIN TURN
REQ4_Label = 'Sustain Turn (AB)';

%REQ4 Req Inputs
Beta = 0.852; %Weight fraction at time of point performance (W/Wo)
h = 20000; %Altitude for point performance requirement (ft)
M = 0.9; %Mach for point performance requirement
n = 5; %Load factor for point performance requirement
Throttle = 'AB'; %Defines if jet afterburner thrust ('AB'), jet mil thrust ('MIL'), or propellor power available ('PROP') is used in performance analysis
P_s = 0; %Rate of Climb req (ft/s) or if point performance requirement must be sustained (P_s = 0) or accomplished with remaining excess power available (P_s > 0) or at a deficit (P_s < 0)
Accel = 0; %Defines any acceleration requirement (ft/s^2). Typically zero for most point performance requirements.
CDx = 0; %Defines added parasite drag coefficient value not modeled in clean aerodynamics drag polar values due to configuration (landing gear, flaps) or external stores (attached sensors, fuel tanks, munitions, etc.)

Req3_Inputs = {Beta,h,M,n,Throttle,P_s,Accel,CDx}; %Consolidates inputs into array for input into constraint equation funciton

%Call Constraint Equation Function to evaluate point performance above
[T_W_req4,P_W_req4,Req4_REQ_DATA] = Master_Constraint_EQ(Req3_Inputs,Constants,W_S_range,Propulsion_Input,DragPolar_Model,WaveDrag_Data);



% %% REQ #5: VTOL (Propeller Based)
% REQ5_Label= 'Vertical Climb';
% % modifying constants for testing:
% constants{1,3}=47500; %V22 MTOW for VTOL
% Propulsion_Input(1,:).PropType={'PROP_Fuel'};
% 
% %REQ5 Req Inputs
% Beta = 1; %Weight fraction at time of point performance (W/Wo)
% h = 5000; %Altitude for point performance requirement (ft)
% V_Climb=25; %Vertical Speed [ft/s]
% Req5_Inputs={Beta,h,V_Climb};
% 
% %REQ 5 VTOL Specific Vehicle Characteristics for Propeller Based Vtol
% A=2200;%Total Propeller disk area [ft^2]
% eta_mechanical=.97; %mechanical efficiency factor
% M=.7; %Figure of Merit 0.6-0.8 Raymer section 21.3.4 (pp797)
% VTOL_Characteristics={A,eta_mechanical,M};
% 
% [T_W_Vtol_req,P_W_Vtol_req,VTOL_REQ_DATA] = Vtol_Constraint_EQ(Req5_Inputs,Constants,Propulsion_Input,VTOL_Characteristics)
% P_W_Vtol_req=P_W_Vtol_req*ones(size(W_S_range));
% 
% 
% figure
% plot(W_S_range,P_W_Vtol_req);
% xlabel('Wing Loading (W/S) - lb/ft^2');
% ylabel('Power to Weight (P/W) - hp/lb (sea level, shaft hp, total weight');
% 
% return

%% DESIGN POINT & CONSTRAINT DIAGRAM PLOT
PropType=Propulsion_Input.PropType
%Determine if aircraft being assessed is a jet or prop
if strcmp(PropType,'PROP_Fuel')|strcmp(PropType,'PROP_Electric')
    %Current Design Point (PROP) based on design geometry used in analysis
    NumEng = Propulsion_Input.Number(Config_Row); %Number of engines. Pull from propulsion input or manually set.
    PA_shp_sl = Propulsion_Input.PA_shp_sl(Config_Row); %(hp) Shaft HP of engine at sea level. Pull from propulsion input or manually set.
    P_W_0 = (PA_shp_sl*NumEng)/Wo;
    W_S_0 = Wo/Sref_initial;

    % Next Design Point (PROP) based on review of constraint diagram
    P_W_1 = 0;
    W_S_1 = 0;

    % P/W CONSTRAINT DIAGRAM PLOT
    figure
    hold on

    %Takeoff, Landing, & Stall Plots
    plot(W_S_range,P_W_TOreq);
    PW_Range = [0 2];
    Land_WS_Plot = [W_S_Land_req W_S_Land_req];
    Stall_WS_Plot = [W_S_stall_req W_S_stall_req];
    line(Land_WS_Plot,PW_Range);
    line(Stall_WS_Plot,PW_Range);

    %Constraint Equation Perf Requirements
    plot(W_S_range,P_W_req1);
    plot(W_S_range,P_W_req2);
    plot(W_S_range,P_W_req3);
    plot(W_S_range,P_W_req4);

    %Design Point Plot
    plot(W_S_0,P_W_0,'Marker','diamond','MarkerSize',10);
    plot(W_S_1,P_W_1,'Marker','square','MarkerSize',10);

    %Labels & Legends
    legend_names = {TO_REQ_Label,Land_REQ_Label,Stall_REQ_Label,REQ1_Label,REQ2_Label,REQ3_Label,REQ4_Label,'Current DP','Next DP'};
    xlabel('Wing Loading (W/S) - lb/ft^2');
    ylabel('Power to Weight (P/W) - hp/lb (sea level, shaft hp, total weight');
    legend(legend_names);
    title('Point Performance Sizing: Constraint Diagram (Power)');
    hold off

else
    % Current Design Point (JET) based on design geometry used in analysis
    NumEng = Propulsion_Input.Number(Config_Row); %Number of engines. Pull from propulsion input or manually set.
    TA_mil_sl = Propulsion_Input.TA_mil_sl(Config_Row); %(lb) Sea level static thrust (no AB). Pull from propulsion input or manually set.
    TA_AB_sl = Propulsion_Input.TA_AB_sl(Config_Row); %(lb) Sea level static thrust (w/AB). Pull from propulsion input or manually set.
    T_W_0_AB = (TA_AB_sl*NumEng)/Wo;
    T_W_0_mil = (TA_mil_sl*NumEng)/Wo;
    W_S_0 = Wo/Sref_initial;

    % Next Design Point (JET) based on review of constraint diagram plot
    T_W_1_AB = 0; %User selected point off plot
    T_W_1_mil= 0; %User selected point off plot
    W_S_1 = 0; %User selected point off plot

    % T/W CONSTRAINT DIAGRAM PLOT
    figure
    hold on

    %Takeoff, Landing, & Stall Plots
    plot(W_S_range,T_W_TOreq);
    TW_Range = [0 2];
    Land_WS_Plot = [W_S_Land_req W_S_Land_req];
    Stall_WS_Plot = [W_S_stall_req W_S_stall_req];
    line(Land_WS_Plot,TW_Range);
    line(Stall_WS_Plot,TW_Range);

    %Constraint Equation Perf Requirements
    plot(W_S_range,T_W_req1);
    plot(W_S_range,T_W_req2);
    plot(W_S_range,T_W_req3);
    plot(W_S_range,T_W_req4);

    %Design Point Plot
    plot(W_S_0,T_W_0_mil,'Marker','diamond','MarkerSize',10);
    plot(W_S_0,T_W_0_AB,'Marker','square','MarkerSize',15);
    plot(W_S_1,T_W_1_mil,'Marker','pentagram','MarkerSize',10);
    plot(W_S_1,T_W_1_AB,'Marker','o','MarkerSize',15);

    %Labels & Legend
    legend_names = {TO_REQ_Label,Land_REQ_Label,Stall_REQ_Label,REQ1_Label,REQ2_Label,REQ3_Label,REQ4_Label,'Current DP (mil)','Current DP (AB)','Next DP (mil)','Next DP (AB)'};
    xlabel('Wing Loading (W/S) - lb/ft^2');
    ylabel('Thrust to Weight (T/W) - sea level static, total weight');
    legend(legend_names);
    title('Point Performance Sizing: Constraint Diagram (Thrust)');

    hold off

end





