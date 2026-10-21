function [VTOL_W_Fraction,VTOL_Data,msgs] = MSN_SEG_VTOL(TO_alt,Hover_Time,DeltaH,W_start,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data,msgs)

    %hover time = constant alt hover
    %deltaH= altitude gain
    %you can have either one or both.
    % Unpack Constants
    Config_Row = Constants{1,1};
    AR = Constants{1,2};
    Sref = Constants{1,3};
    M_max = Constants{1,4};
    g = Constants{1,5};
    PropType = Constants{1,6};

    %%model limits
    acc_cap=0.25*g;
    v_cap=50;
    if (Hover_Time > 60)||(DeltaH>1500)
        warning("This segment assumes constant mass throughout. It may be too conservative for longer hover times or large deltaH. Recommend splitting into multiple segments for now.")
    end

    %Takeoff Atmosphere Properties
    [rho,a,T,P,nu,z] = atmos(TO_alt,'units','US'); %takeoff altitude std atmosphere properties

    [TA_mil_max,TA_AB_max,T_mil_lapse,T_AB_lapse,TSFC_lapse,TSFC_mil,TSFC_AB,PA_max,P_lapse,SFC,msgs] =...
        Propulsion(TO_alt,0,Config_Row,Propulsion_Input,msgs);

    if strcmp(PropType,'PROP_Fuel')||strcmp(PropType,'PROP_Electric')||strcmp(PropType,'PROP_Turbocharged')
        %Convert max power output to average thrust during takeoff roll
        T = PA_max/(.1*a); 
    else
        T = TA_mil_max;  %Maximum thrust available military power. Dynamically switches to afterburners if necessary for takeoff.
        TSFC=TSFC_mil;
    end
    
    T_min=W_start;
    if T< T_min
        warning("Thrust Available < Thrust Required for Hover.")
        VTOL_W_Fraction=1;
        VTOL_Data={};
        return;
    end


    if strcmp(PropType,'PROP_Fuel')||strcmp(PropType,'PROP_Electric')||strcmp(PropType,'PROP_Turbocharged')


    else
        %% climb part
        Time_Climb=0;
        if DeltaH>0
            acc=(T-W_start)/ (W_start/g);
            Time_Climb=sqrt(2*DeltaH/acc);
            vf=sqrt(2*acc*DeltaH);
            if (vf>v_cap)|| acc>acc_cap
                T_cap_acc = W_start * (1 + acc_cap/g);
                T_cap_vf = W_start + (W_start/g) * (v_cap^2 / (2*DeltaH));
                T=min(T_cap_acc,T_cap_vf);
                acc=(T-W_start)/ (W_start/g);
                Time_Climb=sqrt(2*DeltaH/acc);
                vf=sqrt(2*acc*DeltaH);

            end

            FuelClimb=TSFC*Time_Climb*T;
        else
            FuelClimb=0;
        end
        %% hover part
        if Hover_Time >0
            FuelHover=TSFC*Hover_Time*T_min;
        else
            FuelHover=0;
        end
    end

    VTOL_W_Fraction=(W_start-FuelHover-FuelClimb)/W_start;
    VTOL_Data=table(DeltaH,Time_Climb,Hover_Time,T_min,T,W_start);



end
