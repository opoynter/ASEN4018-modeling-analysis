function [Supercruise_W_fraction,SUPERCRUISE_DATA,msgs] = MSN_SEG_Supercruise(Cruise_Alt_Start,R_cruise,Cruise_M,CDx_Cruise,W_start,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data,msgs)
%Models weight fraction used during a cruise misson segment.  Model used is
%based on a supercruise climb where mach and L/D ratio is held constant
%(constant CL/CD = Constant angle of attack).  This implies that altitude
%is varied as fuel is burned therefore end altitude is higher than start
%altitude.  Throttle is restricted to MIL power (no AB) to force
%supercruise.

%   Required Inputs
    %Cruise_Alt_Start:  Altitude at start of cruise in ft
    %R_cruise:  Designed cruise range based on mission profile in ft
    %Cruise_Mach:  Designed cruise mach number
%   Outputs:
    %Cruise_W_fraction:  Weight fraction (end of cruise)/(beginning of
    %cruise).  In call function, "W2_W1" with the numbers changed to represent the
    %mission segment you will cruise (2 = end of segment, 1 = prior
    %segment).
    %SUPERCRUISE_DATA: Outputs all values used in caluclations for
    %troubleshooting.
  

% Unpack Constants
    Config_Row = Constants{1,1}; 
    AR = Constants{1,2};
    Sref = Constants{1,3};
    M_max = Constants{1,4};
    g = Constants{1,5};
    PropType = Constants{1,6};

    % MSN SEGMENT TYPE: Supercruise Weight Fraction Model
        %Cruise Atmospheric Properties
        [rho,a,T,P,nu,z] = atmos(Cruise_Alt_Start,'units','US');

        %Design Cruise Velocity & Coefficient of Lift (hold constant
        %throughout)
        Cruise_Vel = Cruise_M*a; %Desired design velocity for cruise leg (ft/s)
        CL = W_start/(0.5*rho*Cruise_Vel^2*Sref); %Coefficient of lift based on start of cruise weight and mach    
        
        %Find Cruise Drag
        [CD,CDo_msn,k1_msn,k2_msn,msgs] = DragPolar_Function(Cruise_M,CL,Config_Row,DragPolar_Model,WaveDrag_Data,msgs);
        CD = CD+CDx_Cruise; %Add any external parasite drag
        D = (CD)*0.5*rho*Cruise_Vel^2*Sref; %Drag (lb) at start altitude

        %Find TSFC for Cruise
        [TA_mil_max,TA_AB_max,T_mil_lapse,T_AB_lapse,TSFC_lapse,TSFC_mil,TSFC_AB,PA_max,P_lapse,SFC,msgs] =...
    Propulsion(Cruise_Alt_Start,Cruise_M,Config_Row,Propulsion_Input,msgs);

        %Cruise Weight Fraction Model (model used depends on prop or jet propulsion by checking PropType variable)
        R_cruise = R_cruise*6076.12; %Convert design input range from nautical miles to ft
        
        if strcmp(PropType,'PROP_Fuel')||strcmp(PropType,'PROP_Electric')||strcmp(PropType,'PROP_Turbocharged')||strcmp(PropType,'Turboprop')
            warning('Supercruise not possible with propellor based propulsion!'); %Code will break if prop is selected
        else %Calculation of weight fraction if jet engine
            if D > TA_mil_max %Is drag produced greater than thrust w/out afterburner?
                Supercruise_W_fraction = exp(-R_cruise*TSFC_mil/(Cruise_Vel*(CL/CD)));%Calculate anyway to ensure data is written for analysis only
                warning('Supercruise not possible. Drag > MIL thrust!'); 
            elseif D <= TA_mil_max %Only require mil power for drag during cruise
                Supercruise_W_fraction = exp(-R_cruise*TSFC_mil/(Cruise_Vel*(CL/CD)));
            end
            %Record Cruise Performance Data
            SUPERCRUISE_DATA= table(Cruise_Alt_Start,Cruise_M,Cruise_Vel,CL,CD,CDo_msn,k1_msn,k2_msn,D,TA_mil_max,TA_AB_max,TSFC_mil,TSFC_AB,PA_max,SFC);
        end

end
