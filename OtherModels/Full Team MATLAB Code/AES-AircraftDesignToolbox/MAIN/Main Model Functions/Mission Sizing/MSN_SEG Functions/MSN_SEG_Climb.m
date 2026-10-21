function [Climb_W_fraction,CLIMB_DATA,msgs] = MSN_SEG_Climb(Climb_Alt_Start,Climb_Alt_End,Climb_Mach_Start,Climb_Mach_End,CDx_Climb,W_start,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data,msgs)
%Models weight fraction used during a climb misson segment.
%   Detailed explanation goes here

% Unpack Constants
    Config_Row = Constants{1,1}; 
    AR = Constants{1,2};
    Sref = Constants{1,3};
    M_max = Constants{1,4};
    g = Constants{1,5};
    PropType = Constants{1,6};
    Prop_Eff = Propulsion_Input.Prop_eff(Config_Row);

% MSN SEGMENT TYPE: Climb Weight Fraction Model
    %Average Climb Segment Alt and Mach
    Climb_Alt_Avg = (Climb_Alt_End+Climb_Alt_Start)/2; %Average altitude during climb segment
    Climb_Mach_Avg = (Climb_Mach_End+Climb_Mach_Start)/2;

    %Climb Atmospheric Properties
    [rho,a,T,P,nu,z] = atmos(Climb_Alt_Avg,'units','US');
    [rho_start,a_start,T_start,P_start,nu_start,z_start] = atmos(Climb_Alt_Start,'units','US');
    [rho_end,a_end,T_end,P_end,nu_end,z_end] = atmos(Climb_Alt_End,'units','US');

    %Climb Weight Fraction Model (Raymer Eq 19.8,19.9)
        %Change in Energy Height
        Climb_Vel_Start = Climb_Mach_Start*a_start; %ft/s
        Climb_Vel_End = Climb_Mach_End*a_end; %ft/s
        Climb_Vel_Avg = Climb_Mach_Avg*a; %ft/s
        Delta_he = (Climb_Alt_End+(Climb_Vel_End)^2/(2*g))-(Climb_Alt_Start+(Climb_Vel_Start)^2/(2*g)); %Change in enegy height (ft)

        %Average Drag
        Climb_CL = W_start/(0.5*rho*Climb_Vel_Avg^2*Sref); %Assuming L ~ W at start of climb
        [CD,CDo_msn,k1_msn,k2_msn,msgs] = DragPolar_Function(Climb_Mach_Avg,Climb_CL,Config_Row,DragPolar_Model,WaveDrag_Data,msgs);
        CD = CD+CDx_Climb; %Add any external parasite drag
        D = (CD)*(0.5*rho*Climb_Vel_Avg^2*Sref); %Average Drag (lb)

        %Average Thrust or Power & TSFC or SFC
        [TA_mil_max,TA_AB_max,T_mil_lapse,T_AB_lapse,TSFC_lapse,TSFC_mil,TSFC_AB,PA_max,P_lapse,SFC,msgs] =...
    Propulsion(Climb_Alt_Avg,Climb_Mach_Avg,Config_Row,Propulsion_Input,msgs);

        %Average Rate of Climb
        if strcmp(PropType,'PROP_Fuel')||strcmp(PropType,'PROP_Electric')||strcmp(PropType,'PROP_Turbocharged')||strcmp(PropType,'Turboprop')
            if PA_max<(Climb_Vel_Avg*D)
                msgs.warnings{end+1} = "Power insufficient for climb based on drag and power required.";
                warning(msgs.warnings{end,:})
            end
            ROC = (PA_max-Climb_Vel_Avg*D)/W_start; %Rage of climb in ft/s
            TOC = ((Climb_Alt_End - Climb_Alt_Start)/ROC)/60; %Time of climb in minutes
            %Climb Weight Fraction Model
            T = PA_max/Climb_Vel_Avg; %Calculate average thrust during climb out and acceleration
            C = SFC*(Climb_Vel_Avg/Prop_Eff); %Thrust specific fuel consumption. Must converting SFC (fuel burn per power) to TSFC (fuel burn per thrust) by mult (V/Prop_eff).
            Climb_W_fraction = exp((-C*Delta_he)/(Climb_Vel_Avg*(1-D/T)));

        else
            if (TA_mil_max<D)
                warning ("Thrust insufficient for climb based on drag and power required.")
            end
            ROC = (Climb_Vel_Avg)*(TA_mil_max-D)/W_start; %Rage of climb in ft/s
            TOC = ((Climb_Alt_End - Climb_Alt_Start)/ROC)/60; %Time of climb in minutes
             %Climb Weight Fraction Model
            T = TA_mil_max; %Change to TA_AB_max if using afterburner in climb segment
            C = TSFC_mil; %Thrust specific fuel consumption. Change to TFSC_AB if using afterburner in climb segment
            Climb_W_fraction = exp((-C*Delta_he)/(Climb_Vel_Avg*(1-D/T)));
        end

        %Record Climb Performance Data
        CLIMB_DATA= table(Delta_he,Climb_CL,CD,CDo_msn,k1_msn,k2_msn,D,T,C,ROC,TOC);

end
