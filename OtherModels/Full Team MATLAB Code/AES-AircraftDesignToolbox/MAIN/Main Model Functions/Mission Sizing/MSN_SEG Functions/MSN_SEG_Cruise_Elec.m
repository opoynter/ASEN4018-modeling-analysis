function [Cruise_bm_fraction,CRUISE_DATA,msgs] = MSN_SEG_Cruise_Elec(Cruise_Alt_Start,R_cruise,Cruise_M,CDx_Cruise,W_start,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data,msgs)
    %Models weight fraction used during a cruise misson segment.  Model used is
    %based on a cruise climb where mach and L/D ratio is held constant
    %(constant CL/CD = Constant angle of attack).  This implies that altitude
    %is varied as fuel is burned therefore end altitude is higher than start
    %altitude.

    %   Required Inputs
    %Cruise_Alt_Start:  Altitude at start of cruise in ft
    %R_cruise:  Designed cruise range based on mission profile in ft
    %Cruise_Mach:  Designed cruise mach number
    %   Outputs:
    %Cruise_W_fraction:  Weight fraction (end of cruise)/(beginning of
    %cruise).  In call function, "W2_W1" with the numbers changed to represent the
    %mission segment you will cruise (2 = end of segment, 1 = prior
    %segment).
    %CRUISE_DATA: Outputs all values used in caluclations for
    %troubleshooting.


    % Unpack Constants
    Config_Row = Constants{1,1};
    Sref = Constants{1,3};
    g = Constants{1,5};
    PropType = Constants{1,6};
    Esb_Real=Propulsion_Input.Esb_Real(Config_Row);%note that ESB_Real is the Specific energy of the battery after losses due to installation, lifetime degradation, and loss due to usable capacity.
    PropEff=Propulsion_Input.Prop_eff(Config_Row);
    nb2s=Propulsion_Input.eta_b2s(Config_Row);%accounts for losses from battery to shaft



    % convert units
    %AR=AR
    Sref=Sref*(1/3.281)^2;
    %M_max=M_max
    g=g/3.281;
    Cruise_Alt_Start=Cruise_Alt_Start/3.281;
    R_cruise=R_cruise*1.852; %Nautical miles to km
    W_start=W_start*4.44822; %lbf to Ns

    % MSN SEGMENT TYPE: Cruise Weight Fraction Model
    %Cruise Atmospheric Properties
    [rho,a,~,~,~,~] = atmos(Cruise_Alt_Start);

    %Design Cruise Velocity & Coefficient of Lift (hold constant
    %throughout)
    Cruise_Vel = Cruise_M*a; %Desired design velocity for cruise leg (m/s)
    CL = W_start/(0.5*rho*Cruise_Vel^2*Sref); %Coefficient of lift based on start of cruise weight and mach

    %Find Cruise Drag
    [CD,CDo_msn,k1_msn,k2_msn] = DragPolar_Function(Cruise_M,CL,Config_Row,DragPolar_Model,WaveDrag_Data);
    CD=CD+CDx_Cruise; %Add any external parasite drag
    D = (CD)*0.5*rho*Cruise_Vel^2*Sref; %Drag (lb) at start altitude

    %Find TSFC for Cruise
    [~,~,~,~,~,~,~,PA_max,~,~,msgs] =...
        Propulsion(Cruise_Alt_Start,Cruise_M,Config_Row,Propulsion_Input,msgs);

    %Cruise Weight Fraction Model (model used depends on prop or jet propulsion by checking PropType variable)

    if strcmp(PropType,'PROP_Electric')
        Power_Req = D*Cruise_Vel; %Calculate power required during cruise leg
        if PA_max > Power_Req %Check to see if max power available is greater than power required during cruise
            %calculate cruise battery mass fraction
            Cruise_bm_fraction=R_cruise*g/(3.6*Esb_Real*nb2s*PropEff*CL/CD);
        else
            msgs.warnings{end+1} = 'Power insufficient for cruise based on drag & power required!';
            warning(msgs.warnings{end,:})
            Cruise_bm_fraction=R_cruise*g/(3.6*Esb_Real*nb2s*PropEff*CL/CD);

        end
        %Record Cruise Performance Data
        SFC=0;
        %converting cruise data back into imperial units inline
        CRUISE_DATA= table(Cruise_Alt_Start*3.281,Cruise_M,Cruise_Vel*3.281,CL,CD,CDo_msn,k1_msn,k2_msn,D/4.448,550*PA_max/745.7,550*Power_Req/745.7,SFC);

    else %Calculation of weight fraction if jet engine
        error("Only PropType PROP_Electric supported")
    end

end
