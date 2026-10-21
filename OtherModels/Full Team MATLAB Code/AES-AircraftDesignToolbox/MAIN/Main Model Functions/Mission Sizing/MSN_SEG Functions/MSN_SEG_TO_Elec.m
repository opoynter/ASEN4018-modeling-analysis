function [TO_bm_fraction,TO_DATA,msgs] = MSN_SEG_TO_Elec(TO_alt,CL_max_TO,Roll_Fric,CDx_TO,W_start,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data,msgs)
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
    Sref = Constants{1,3};
    g = Constants{1,5};
    PropType = Constants{1,6};
    Esb_Real=Propulsion_Input.Esb_Real(Config_Row);%note that ESB_Real is the Specific energy of the battery after losses due to installation, lifetime degradation, and loss due to usable capacity.
    nb2s=Propulsion_Input.eta_b2s(Config_Row);%accounts for losses from battery to shaft
    PropEff=Propulsion_Input.Prop_eff(Config_Row);



    % convert units
    Sref=Sref*(1/3.281)^2;
    g=g/3.281;
    TO_alt=TO_alt/3.281;
    W_start=W_start*4.44822;


    % Takeoff & Acceleration Weight Fraction Model

    %Takeoff Atmosphere Properties
    [rho,a,~,~,~,~] = atmos(TO_alt); %takeoff altitude std atmosphere properties (SI units rho[kg/m^3])

    %Takeoff velocity estimation
    V_stall = sqrt(2*W_start/(rho*CL_max_TO*Sref)); %Estimation of stall velocity (m/s)
    V_TO = 1.2*V_stall; %Estimated takeoff velocity (m/s)

    %Takeoff Velocity Accelerated to
    TO_mach = V_TO/a; %Convert takeoff velocity to mach

    %Takeoff Propulsion Properties
    [~,~,~,~,~,~,~,PA_max,~,~,msgs] =...
        Propulsion(TO_alt,TO_mach,Config_Row,Propulsion_Input,msgs);

    %Determine thrust during takeoff depending on jet or prop propulsion type (PropType)
    %this function only supports electric!
    if strcmp(PropType,'PROP_Electric')
        %Convert max power output to average thrust during takeoff roll
        T = PA_max/(0.7*V_TO); %Average thrust from prop during takeoff at 70% V_TO
    else
        error("Only PropType PROP_Electric supported")
    end

    %Takeoff Average Drag
    [CD,~,~,~,msgs] = DragPolar_Function(TO_mach,CL_max_TO,Config_Row,DragPolar_Model,WaveDrag_Data,msgs);
    CD=CD+CDx_TO; %Add any external parasite drag
    D = CD*0.5*rho*(.7*V_TO)^2*Sref; %Drag at 70% V_TO

    %Takeoff Average Lift
    L = CL_max_TO*0.5*rho*(0.7*V_TO)^2*Sref; %Lift at 70% V_TO

    %Takeoff ground roll calculation
    S_TO = (1.44*W_start^2)/(rho*Sref*CL_max_TO*g*(T-(D+Roll_Fric*(W_start-L)))); %Takeoff Groundroll (m)
    TO_time = S_TO/(0.7*V_TO); %Estimate of takeoff time duration in seconds

    %power required for takeoff
    Preq=D*V_TO;
    if Preq>PA_max
        warning("Required takeoff power is less than maximum available power!")
    end


    %Takeoff Weight Fraction Model Depending on jet or prop propulsion type (PropType) (Raymer 19.7)
    if  strcmp(PropType,'PROP_Electric')
        T = PA_max/V_TO; %Calculate average thrust during climb out and acceleration

        TO_bm_fraction=Preq*(TO_time/3600)/(Esb_Real*nb2s*PropEff*W_start/g);
        %Record Takeoff Performance Data
        SFC=0;

        TO_DATA= table(V_stall*3.281,V_TO*3.281,TO_mach,550*PA_max/745.7,T/4.448,SFC,D/4.448,L/4.448,S_TO*3.281,TO_time);
    else
        error("Only PropType PROP_Electric supported")

    end

end
