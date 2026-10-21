function [TA_mil_max,TA_AB_max,T_mil_lapse,T_AB_lapse,TSFC_lapse,TSFC_mil,TSFC_AB,PA_max,P_lapse,SFC,msgs] =...
    Propulsion(Msn_Alt,Msn_Mach,Config_Row,Propulsion_Input,msgs)
%% Propulsion Function Summary
% Outputs thrust or power values using basic models (Brandt) for use in
% mission analysis of a conceptual design.

%% Outputs:
%
% Propulsion_Function:
%   Outputs thrust lapse and TSFC lapse values (if jet engine) or power
%   laspe and SFC lapse (if prop engine) for use in mission analysis and point performance constraint anslysis.  Can
%   only be used with one configuration at a time
%   (so you must designate which row you are assessing in "Config_Row"
%   input).  The mission segment alitidue (MSN_Alt) and mach (MSN_Mach)
%   must be inputted from mission analysis.

% %%Initialize initial values
TA_mil_max=0; %Jet max thrust available no afterburner (lb)
TA_AB_max=0; %Jet max hrust available with afterburner (lb)
T_mil_lapse=0;%Jet Thrust Lapse rate (without afterburner)
T_AB_lapse=0; %Jet Thrust Lapse rate (w/ afterburner)
TSFC_lapse=0; %Jet Thrust Specific Fuel Consumption Lapse Rate 
TSFC_mil = 0; %TSFC no afterburner (lb/s per lb thrust or lb/(lb*s) or 1/s)
TSFC_AB = 0; %TSFC with afterburner (lb/s per lb thrust or lb/(lb*s) or 1/s)
PA_max=0; %Prop max power available (ft*lb/s)
P_lapse=0; %Prop power lapse rate
SFC = 0; %SFC %Prop specific fuel consumption (lb/s per ft*lb/s or lb/(ft*lb) or 1/ft)

%% Establish atmospheric conditions
[rho_alt,a_alt,T_alt,P_alt,nu_alt,z_alt]= atmos(Msn_Alt,'units','US'); %establish mission segment atmospheric properties
[rho_sl,a_sl,T_sl,P_sl,nu_sl,z_sl]= atmos(0,'units','US'); %establish sea level atmospheric properties

%%Convert data in propulsion_input to variables. Script automatically pulls
%these values from the outputs of the ASEN4138_Aircaft_Design_Aero_Model_Main.m code; howver, once you progress
%to more detailed design you may need to manually input these values in
%place of any term from Propulsion_Input.

PropType = Propulsion_Input.PropType{Config_Row}; %Must be 'PROP_Fuel', 'JET_LBP_Turbofan','JET_HBP_Turbofan', 'Turboprop','PROP_Electric, 'PROP_Turbocharge'
NumEng = Propulsion_Input.Number(Config_Row); %Number of engines
PropEff = Propulsion_Input.Prop_eff(Config_Row); %Propellor Efficiency (Prop Engines Only)
PA_shp_sl = 550*Propulsion_Input.PA_shp_sl(Config_Row)*NumEng; %Shaft or brake horsepower for prop engine (converted from hp to ft*lb/s). Assumes PA_shp_sl provided in hp so formula converts using 550 ft*lb/s per hp.
SFC_sl = Propulsion_Input.SFC_sl(Config_Row); %Prop engine specific fuel consumption in (lb/hr/hp)
TA_mil_sl = NumEng*Propulsion_Input.TA_mil_sl(Config_Row); %Jet thrust available no ab at sea level (lb)
TA_AB_sl = NumEng*Propulsion_Input.TA_AB_sl(Config_Row); %Jet thrust available with ab at sea level (lb)
TSFC_dry_sl = Propulsion_Input.TSFC_mil_sl(Config_Row)/3600; %Jet TSFC no ab at sea level. Assume input provided in (1/hr) so must convert to (1/s)
TSFC_AB_sl = Propulsion_Input.TSFC_AB_sl(Config_Row)/3600; %Jet TSFC with ab at sea level. Assume input provided in (1/hr) so must convert to (1/s)
Install_loss = Propulsion_Input.Install_loss(Config_Row); %Jet installation loss (%)

%%Calculate mission segment velocity from Mach input
Msn_V = Msn_Mach*a_alt; %true velocity in ft/s from mach

%% Determine if using a jet or prop engine 
if strcmp(PropType,'PROP_Fuel')
    P_lapse = (((rho_alt/rho_sl)-0.117)/0.883)*PropEff; %Gagg and Ferrar model including propellor efficiency; General Aviation Aircraft Design: Applied Methods and Procedures; Snorri Gudmundsson
    PA_max = PA_shp_sl*P_lapse;%includes number of engines (ft*lb/s)
    SFC = SFC_sl*(1/3600)*(1/550); %Assumes SFC_sl initial provided in lb/hr/hp so must convert to lb/s/(ft*lb/s) using (550 ft*lb/s)/hp & 3600 s/hr.
elseif strcmp(PropType,'JET_LBP_Turbofan')
    T_mil_lapse = (rho_alt/rho_sl); %Valid only for non-AB under Mach 0.9
    T_AB_lapse = (rho_alt/rho_sl)*(1+0.7*Msn_Mach); %afterburner thrust lapse.  
    TA_mil_max = TA_mil_sl*T_mil_lapse*(1-Install_loss);%includes number of engines and installation loss estimates
    TA_AB_max = TA_AB_sl*T_AB_lapse*(1-Install_loss);%includes number of engines and installation loss estimates
    TSFC_lapse = (a_alt/a_sl)*(1+Install_loss); %Includes increase in TSFC due to installation losses
    TSFC_mil = TSFC_dry_sl*TSFC_lapse; %TSFC no afterburner (lb/s per lb thrust or lb/(lb*s) or 1/s)
    TSFC_AB = TSFC_AB_sl*TSFC_lapse; %TSFC with afterburner (lb/s per lb thrust or lb/(lb*s) or 1/s)
elseif strcmp(PropType,'JET_HBP_Turbofan') %Mattingly model ("Aircraft Engine Design", EQ 2.53) valid for M<0.9
% Determine theta_o based on flight condition (altitude and mach)
    if Msn_Mach > 0.9
        warning("Your mission segment mach is > 0.9 which is outside of the bounds for the High Bypass Turbofan engine model. Consider changing to a Low-Bypass Turbfan for your propulsion type.");
    end
    theta_o = (T_alt/T_sl)*(1+(0.4/2)*Msn_Mach^2); %Ratio of Total Temp at alt & mach to sea level static temp
    delta_o = (P_alt/P_sl)*(1+(0.4/2)*Msn_Mach^2)^(1.4/0.4); %Ratio of Total Pressure at alt & mach to sea level static pressure
    TR = 1.0; %Assume a design throttle ratio of 1.0 (max Tt4 and max Pi_c at sea level static)
    if theta_o <= TR
        T_mil_lapse = delta_o*(1-0.49*sqrt(Msn_Mach)); %Mattingly model
    else
        T_mil_lapse = delta_o*(1-0.49*sqrt(Msn_Mach)-(3*(theta_o-TR))/(1.5+Msn_Mach));  %Mattingly model
    end
    TA_mil_max = TA_mil_sl*T_mil_lapse;%includes number of engines and installation loss estimates
    TSFC_mil = (((0.45+0.54*Msn_Mach)*sqrt(T_alt/T_sl))/3600); %TSFC no afterburner; Mattingly Model 3.54 (lb/s per lb thrust or lb/(lb*s) or 1/s)
elseif strcmp(PropType,'PROP_Turboprop') %All based on Mattingly model 2.56
    % Determine theta_o based on flight condition (altitude and mach)
    Prop_EFF_static=.55;%conservative hardcoded for now

    T_static = (PA_shp_sl^2*Prop_EFF_static^2*pi*NumEng*Propulsion_Input.Prop_Dia(Config_Row)^2/2*rho_sl)^(1/3);
    % T_static2=NumEng*((PA_shp_sl/NumEng)^2*Prop_EFF_static^2*pi*Propulsion_Input.Prop_Dia(Config_Row)^2/2*rho_sl)^(1/3)
    TA_mil_sl=T_static;
    if Msn_Mach > 0.8
        warning("Your mission segment mach is > 0.8 which is outside of the bounds for the Turboprop engine model. Consider changing to a High-Bypass Turbfan for your propulsion type.");
    end
    theta_o = (T_alt/T_sl)*(1+(0.4/2)*Msn_Mach^2); %Ratio of Total Temp at alt & mach to sea level static temp
    delta_o = (P_alt/P_sl)*(1+(0.4/2)*Msn_Mach^2)^(1.4/0.4); %Ratio of Total Pressure at alt & mach to sea level static pressure
    TR = 1.0; %Assume a design throttle ratio of 1.0 (max Tt4 and max Pi_c at sea level static)
    if Msn_Mach <= 0.1
        T_mil_lapse = delta_o; 
    elseif Msn_Mach <=0.11
        tempMach = 0.11;
        T_mil_lapse = delta_o*(1-0.96*(tempMach-.1)^0.25 - (3*(theta_o-TR))/(8.13*(tempMach-0.1)));
    else
        if theta_o <= TR
            T_mil_lapse = delta_o*(1-0.96*(Msn_Mach-.1)^0.25);
        else
            T_mil_lapse = delta_o*(1-0.96*(Msn_Mach-.1)^0.25 - (3*(theta_o-TR))/(8.13*(Msn_Mach-0.1)));
        end
    end
    TA_mil_max = TA_mil_sl*T_mil_lapse; %Install losses already considered in Mattingly thrust laspe models
    TSFC_mil = ((0.18+0.8*Msn_Mach)*sqrt(T_alt/T_sl))/3600; %TSFC no afterburner; Mattingly Model 3.57 (lb/s per lb thrust or lb/(lb*s) or 1/s)
elseif strcmp(PropType,'PROP_Turbocharged') %Estimation of turbo-normalized piston engine assuming critical altude of 18,000 ft (; General Aviation Aircraft Design: Applied Methods and Procedures; Snorri Gudmundsson)
    if Msn_Alt < 18000
        P_lapse = 1*PropEff; %Assume turbocharger normalizes to sea level static engine power
        PA_max = PA_shp_sl*P_lapse;%includes number of engines (ft*lb/s)
        SFC = SFC_sl*(1/3600)*(1/550); %Assumes SFC_sl initial provided in lb/hr/hp so must convert to lb/s/(ft*lb/s) using (550 ft*lb/s)/hp & 3600 s/hr.
    else
        P_lapse = (((rho_alt/rho_sl)-0.117)/0.883)*PropEff; %Gagg and Ferrar model including propellor efficiency; General Aviation Aircraft Design: Applied Methods and Procedures; Snorri Gudmundsson
        PA_max = PA_shp_sl*P_lapse;%includes number of engines (ft*lb/s)
        SFC = SFC_sl*(1/3600)*(1/550); %Assumes SFC_sl initial provided in lb/hr/hp so must convert to lb/s/(ft*lb/s) using (550 ft*lb/s)/hp & 3600 s/hr.
    end
elseif strcmp(PropType,'PROP_Electric')
    P_lapse=PropEff;%corrects for propeller efficiency
    PA_shp_sl = (745.7/550)*PA_shp_sl; %Shaft or brake horsepower for prop engine (converted from hp to watts). 
    PA_max =PA_shp_sl*P_lapse;%*P_lapse;%includes number of engines (W)
else
    error("Invalid PropType")
end

end
