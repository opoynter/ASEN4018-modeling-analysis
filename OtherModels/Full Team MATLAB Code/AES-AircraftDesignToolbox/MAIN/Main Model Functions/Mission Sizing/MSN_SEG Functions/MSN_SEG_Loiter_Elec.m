function [Loiter_bm_fraction,LOITER_DATA,msgs] = MSN_SEG_Loiter_Elec(Loiter_Alt,E_loiter,CDx_Loiter,W_start,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data,msgs)
    %Models weight fraction used during a loiter misson segment.  Model used is
    %based on a max endurance loiter flying best mach for L/D max for a jet at constant altitude,
    %constant CL/CD = Constant angle of attack).  This implies that velocity
    %is varied as fuel is burned.

    %   Required Inputs
    %Loiter_Alt:  Altitude of loiter in ft
    %E_loiter:  Designed loiter time in seconds

    %   Outputs:
    %Loiter_W_fraction:  Weight fraction (end of loiter)/(beginning of
    %loiter).  In call function, "W2_W1" with the numbers changed to represent the
    %mission segment you will cruise (2 = end of segment, 1 = prior
    %segment).
    %LOITER_DATA:  Outputs all values used in calculation for
    %troublshooting & analysis.

    % Unpack Constants
    Config_Row = Constants{1,1};
    Sref = Constants{1,3};
    g = Constants{1,5};
    PropType = Constants{1,6};
    Prop_Eff = Propulsion_Input.Prop_eff(Config_Row); %Pull prop efficiency from propulsion input table.
    Esb_Real=Propulsion_Input.Esb_Real(Config_Row);%note that ESB_Real is the Specific energy of the battery after losses due to installation, lifetime degradation, and loss due to usable capacity.
    nb2s=Propulsion_Input.eta_b2s(Config_Row);%accounts for losses from battery to shaft


    % Convert Imperial units to SI units
    %AR=AR
    Sref=Sref*(1/3.281)^2;
    %M_max=M_max
    g=g/3.281;
    Loiter_Alt=Loiter_Alt/3.281;
    W_start=W_start*4.44822;


    % MSN SEGMENT TYPE: Loiter Weight Fraction Model
    %Loiter Atmospheric Properties
    [rho,a,~,~,~,~] = atmos(Loiter_Alt); %note that this returns SI values

    %Subsonic Loiter Drag Polar (CDo and k1). Direct input if using OPEN VSP
    CDo = DragPolar_Model.CDo_sub(Config_Row); %Over-write with direct values from OPEN VSP if using
    k1 = DragPolar_Model.k1_sub(Config_Row); %Over-write with direct values from OPEN VSP if using

    %Best Loiter Velocity & Coefficient of Lift (hold constant
    %throughout)
    if strcmp(PropType,'PROP_Electric')
        CL_best = sqrt(3*CDo/(k1)); %Best coefficient of lift for max prop endurance (min power req)
    else
        error("Only PropType 'PROP_Electric' supported")
    end

    Loiter_Vel_best = sqrt(2*W_start/(rho*Sref*CL_best)); %Best velocity for max endurance based on prior segment weight (ft/s)
    Loiter_M_best = Loiter_Vel_best/a; %Best mach for max endurance


    %Find Loiter Subsonic Drag
    [CD,CDo_msn,k1_msn,k2_msn,msgs] = DragPolar_Function(Loiter_M_best,CL_best,Config_Row,DragPolar_Model,WaveDrag_Data,msgs);
    CD = CD+CDx_Loiter; %Add any external parasite drag
    D = CD*0.5*rho*Loiter_Vel_best^2*Sref; %Drag (N) at start altitude

    %Find Fuel Consumption for Loiter
    [~,~,~,~,~,~,~,PA_max,~,~,msgs] =...
        Propulsion(Loiter_Alt,Loiter_M_best,Config_Row,Propulsion_Input,msgs);

    %Subsonic Loiter Weight Fraction Model (model selction based on
    %prop or jet propulsion as defined by PropType variable)

    %E_loiter = E_loiter*3600; %Converts design loiter time from hours to seconds

    if strcmp(PropType,'PROP_Electric')
        Power_Req = D*Loiter_Vel_best; %Calculate power required during loiter leg
        if PA_max > Power_Req %Check to see if max power available is greater than power required during loiter
            Loiter_bm_fraction = E_loiter*Loiter_Vel_best*3.6*g/(3.6*Esb_Real*nb2s*Prop_Eff*CL_best/CD);
        else
            msgs.warnings{end+1} = "Power insufficient for loiter based on drag & power required!";
            warning(msgs.warnings{end,:})
            Loiter_bm_fraction = E_loiter*Loiter_Vel_best*3.6*g/(3.6*Esb_Real*nb2s*Prop_Eff*CL_best/CD);

        end

        %Record Loiter Performance Data
        %converts back to imperial units inline
        LOITER_DATA= table(Loiter_Alt*3.281,E_loiter,CL_best,Loiter_Vel_best*3.281,Loiter_M_best,CD,CDo_msn,k1_msn,k2_msn,D/4.448,550*PA_max/745.7,550*Power_Req/745.7,0);
    else
        error("Only PropType PROP_Electric supported")

    end


end
