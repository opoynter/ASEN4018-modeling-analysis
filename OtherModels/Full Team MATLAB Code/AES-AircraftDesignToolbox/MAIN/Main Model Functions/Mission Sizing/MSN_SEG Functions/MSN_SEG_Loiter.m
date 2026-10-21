function [Loiter_W_fraction,LOITER_DATA,msgs] = MSN_SEG_Loiter(Loiter_Alt,E_loiter,CDx_Loiter,W_start,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data,msgs)
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
    AR = Constants{1,2};
    Sref = Constants{1,3};
    M_max = Constants{1,4};
    g = Constants{1,5};
    PropType = Constants{1,6};
    Prop_Eff = Propulsion_Input.Prop_eff(Config_Row); %Pull prop efficiency from propulsion input table.

    % MSN SEGMENT TYPE: Loiter Weight Fraction Model
       %Loiter Atmospheric Properties
        [rho,a,T,P,nu,z] = atmos(Loiter_Alt,'units','US');

        %Subsonic Loiter Drag Polar (CDo and k1). Direct input if using OPEN VSP
        CDo = DragPolar_Model.CDo_sub(Config_Row); %Over-write with direct values from OPEN VSP if using
        k1 = DragPolar_Model.k1_sub(Config_Row); %Over-write with direct values from OPEN VSP if using

        %Best Loiter Velocity & Coefficient of Lift (hold constant
        %throughout)
        if strcmp(PropType,'PROP_Fuel')||strcmp(PropType,'PROP_Electric')||strcmp(PropType,'PROP_Turbocharged')||strcmp(PropType,'Turboprop')
            CL_best = sqrt(3*CDo/(k1)); %Best coefficient of lift for max prop endurance (min power req)
        else
            CL_best = sqrt(CDo/(k1)); %Best coefficient of lift for max jet endurance (L/D max)
        end

        Loiter_Vel_best = sqrt(2*W_start/(rho*Sref*CL_best)); %Best velocity for max endurance based on prior segment weight (ft/s)
        Loiter_M_best = Loiter_Vel_best/a; %Best mach for max endurance

        %Find Loiter Subsonic Drag
        [CD,CDo_msn,k1_msn,k2_msn,msgs] = DragPolar_Function(Loiter_M_best,CL_best,Config_Row,DragPolar_Model,WaveDrag_Data,msgs);
        CD=CD+CDx_Loiter; %Add any external parasite drag
        D = CD*0.5*rho*Loiter_Vel_best^2*Sref; %Drag (lb) at start altitude

        %Find Fuel Consumption for Loiter
        [TA_mil_max,TA_AB_max,T_mil_lapse,T_AB_lapse,TSFC_lapse,TSFC_mil,TSFC_AB,PA_max,P_lapse,SFC,msgs] =...
    Propulsion(Loiter_Alt,Loiter_M_best,Config_Row,Propulsion_Input,msgs);

        %Subsonic Loiter Weight Fraction Model (model selction based on
        %prop or jet propulsion as defined by PropType variable)

        E_loiter = E_loiter*3600; %Converts design loiter time from hours to seconds

         if strcmp(PropType,'PROP_Fuel')||strcmp(PropType,'PROP_Electric')||strcmp(PropType,'PROP_Turbocharged')||strcmp(PropType,'Turboprop')
            Power_Req = D*Loiter_Vel_best; %Calculate power required during loiter leg
            if PA_max > Power_Req %Check to see if max power available is greater than power required during loiter
                Loiter_W_fraction = exp(-E_loiter*Loiter_Vel_best*SFC/(Prop_Eff*(CL_best/CD))); %Prop loiter weight fraction model
            else
                warning("Power insufficient for loiter based on drag & power required!")
                Loiter_W_fraction = exp(-E_loiter*Loiter_Vel_best*SFC/(Prop_Eff*(CL_best/CD))); %Prop loiter weight fraction model
            end

            %Record Loiter Performance Data
            LOITER_DATA= table(Loiter_Alt,E_loiter,CL_best,Loiter_Vel_best,Loiter_M_best,CD,CDo_msn,k1_msn,k2_msn,D,PA_max,Power_Req,SFC);
         else
             if D > TA_mil_max && D <= TA_AB_max %Does drag produced require afterburner to have sufficient thrust?
                Loiter_W_fraction = exp(-E_loiter*TSFC_AB/(CL_best/CD)); %Jet loiter weight fraction model w/ afterburner TSFC
            elseif D <= TA_mil_max %Only require mil power for drag during loiter
                Loiter_W_fraction = exp(-E_loiter*TSFC_mil/(CL_best/CD)); %Jet loiter weight fraction model w/ mil TSFC
            elseif D > max(TA_AB_max,TA_mil_max) %Drag is greater than max of thrust available (AB or mil)
                warning('Thrust insufficient for loiter based on drag!')
                Loiter_W_fraction = exp(-E_loiter*TSFC_AB/(CL_best/CD)); %Jet loiter weight fraction model w/AB to ensure output of values for review.
             end

            %Record Loiter Performance Data
            LOITER_DATA= table(Loiter_Alt,E_loiter,CL_best,Loiter_Vel_best,Loiter_M_best,CD,CDo_msn,k1_msn,k2_msn,D,TA_mil_max,TA_AB_max,TSFC_mil,TSFC_AB);
         end


end
