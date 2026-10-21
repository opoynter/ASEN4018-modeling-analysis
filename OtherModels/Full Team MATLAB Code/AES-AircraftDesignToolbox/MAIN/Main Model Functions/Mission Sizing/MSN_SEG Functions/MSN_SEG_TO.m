function [TO_W_fraction,TO_DATA,msgs] = MSN_SEG_TO(TO_alt,CL_max_TO,Roll_Fric,CDx_TO,W_start,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data,msgs)
    %Models weight fraction used during a takeoff and acceleration misson segment.
    %   Required Inputs
    %TO_altr:  Altitude of takeoff and acceleration segment (ft)
    %CL_max_TO:  Maximum coefficient of lift of aircraft in takeoff
    %configuration (typically with flaps)
    %Roll_Fric:  Rolling friction coeffiecient for runway
    %W_start:  Starting weight of takeoff and acceleration segment (lb)

    %   Outputs:
    %TO_W_fraction:  Weight fraction (end of takeoff+acceleration)/(beginning of
    %takeoff).  In call function, "W2_W1" with the numbers changed to represent the
    %mission segment you will cruise (2 = end of segment, 1 = prior
    %segment).
    %TO_DATA:  Outputs all values used in calculation for
    %troublshooting.

    % Unpack Constants
    Config_Row = Constants{1,1};
    AR = Constants{1,2};
    Sref = Constants{1,3};
    M_max = Constants{1,4};
    g = Constants{1,5};
    PropType = Constants{1,6};

    % Takeoff & Acceleration Weight Fraction Model

    %Takeoff Atmosphere Properties
    [rho,a,T,P,nu,z] = atmos(TO_alt,'units','US'); %takeoff altitude std atmosphere properties

    %Takeoff velocity estimation
    V_stall = sqrt(2*W_start/(rho*CL_max_TO*Sref)); %Estimation of stall velocity (ft/s)
    V_TO = 1.2*V_stall; %Estimated takeoff velocity (ft/s)

    %Takeoff Velocity Accelerated to
    TO_mach = V_TO/a; %Convert takeoff velocity to mach

    %Takeoff Propulsion Properties
    [TA_mil_max,TA_AB_max,T_mil_lapse,T_AB_lapse,TSFC_lapse,TSFC_mil,TSFC_AB,PA_max,P_lapse,SFC,msgs] =...
        Propulsion(TO_alt,TO_mach,Config_Row,Propulsion_Input,msgs);

    %Determine thrust during takeoff depending on jet or prop propulsion type (PropType)

    if strcmp(PropType,'PROP_Fuel')||strcmp(PropType,'PROP_Electric')||strcmp(PropType,'PROP_Turbocharged')||strcmp(PropType,'Turboprop')
        %Convert max power output to average thrust during takeoff roll
        T = PA_max/(0.7*V_TO); %Average thrust from prop during takeoff at 70% V_TO
    else
        T = TA_mil_max;  %Maximum thrust available military power. Dynamically switches to afterburners if necessary for takeoff.
        TSFC=TSFC_mil;
    end

    %Takeoff Average Drag
    [CD,CDo_msn,k1_msn,k2_msn,msgs] = DragPolar_Function(TO_mach,CL_max_TO,Config_Row,DragPolar_Model,WaveDrag_Data,msgs);
    CD = CD+CDx_TO; %Add any external parasite drag
    D = (CD)*0.5*rho*(0.7*V_TO)^2*Sref; %Drag at 70% V_TO

    %Takeoff Average Lift
    L = CL_max_TO*0.5*rho*(0.7*V_TO)^2*Sref; %Lift at 70% V_TO

    %Takeoff ground roll calculation
    S_TO = (1.44*W_start^2)/(rho*Sref*CL_max_TO*g*(T-(D+Roll_Fric*(W_start-L)))); %Takeoff Groundroll (ft)
    TO_time = S_TO/(0.7*V_TO); %Estimate of takeoff time duration in seconds

    %Takeoff Weight Fraction Model Depending on jet or prop propulsion type (PropType) (Raymer 19.7)
    Preq=D*V_TO;


    if strcmp(PropType,'PROP_Fuel')||strcmp(PropType,'PROP_Electric')||strcmp(PropType,'PROP_Turbocharged')||strcmp(PropType,'Turboprop')
        if Preq>PA_max
            warning("Required takeoff power is more than maximum available power!")
        end
        TO_W_fraction = 1 - SFC*TO_time*(PA_max/W_start);
        %Record Takeoff Performance Data
        TO_DATA= table(V_stall,V_TO,TO_mach,PA_max,T,SFC,D,L,S_TO,TO_time);
    else
        if D>TA_mil_max
            if D>TA_AB_max  %if afterburner thrust is not great enough to overcome drag
                warning("Required takeoff thrust is less than maximum military thrust!")
            else %if afterburner thrust can overcome drag sets thrust and TSFC to the AB values.
                disp("Afterburner thrust necessary for takeoff")
                T=TA_AB_max;
                TSFC=TSFC_AB;
                %have to recalculate S_TO and TO_time since we switched to
                %afterburner
                S_TO = (1.44*W_start^2)/(rho*Sref*CL_max_TO*g*(T-(D+Roll_Fric*(W_start-L)))); %Takeoff Groundroll (ft)
                TO_time = S_TO/(0.7*V_TO); %Estimate of takeoff time duration in seconds
            end
        end
        TO_W_fraction = 1 - TSFC*TO_time*(T/W_start); %If using afterburners duirng takeoff, must change to TFSC_AB.
        %Record Takeoff Performance Data
        TO_DATA= table(V_stall,V_TO,TO_mach,T,TSFC,D,L,S_TO,TO_time,TO_W_fraction);
    end

end
