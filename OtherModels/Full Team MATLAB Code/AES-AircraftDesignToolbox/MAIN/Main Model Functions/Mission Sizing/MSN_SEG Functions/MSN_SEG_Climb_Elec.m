function [Climb_bm_fraction,CLIMB_DATA,msgs] = MSN_SEG_Climb_Elec(Climb_Alt_Start,Climb_Alt_End,Climb_Mach_Start,Climb_Mach_End,CDx_Climb,W_start,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data,msgs)
    %Models battery mass fraction used during a climb misson segment.
    %   Detailed explanation goes here

    % Unpack Constants

    Config_Row = Constants{1,1};
    Sref = Constants{1,3};
    g = Constants{1,5};
    PropType = Constants{1,6};
    Prop_Eff = Propulsion_Input.Prop_eff(Config_Row);
    Esb_Real=Propulsion_Input.Esb_Real(Config_Row);%specific energy of battery after losses (Whr/kg)
    nb2s=Propulsion_Input.eta_b2s(Config_Row);%accounts for losses from battery to shaft


    % convert units
    Sref=Sref*(1/3.281)^2;
    g=g/3.281;
    Climb_Alt_Start=Climb_Alt_Start/3.281;
    Climb_Alt_End=Climb_Alt_End/3.281;
    W_start=W_start*4.44822;

    % MSN SEGMENT TYPE: Climb Weight Fraction Model
    %Average Climb Segment Alt and Mach
    Climb_Alt_Avg = (Climb_Alt_End+Climb_Alt_Start)/2; %Average altitude during climb segment (m)
    Climb_Mach_Avg = (Climb_Mach_End+Climb_Mach_Start)/2; %



    %Climb Atmospheric Properties
    [rho,a,~,~,~,~] = atmos(Climb_Alt_Avg);
    [~,a_start,~,~,~,~] = atmos(Climb_Alt_Start);
    [~,a_end,~,~,~,~] = atmos(Climb_Alt_End);

    %Climb Weight Fraction Model (Raymer Eq 19.8,19.9)
    %Change in Energy Height
    Climb_Vel_Start = Climb_Mach_Start*a_start; %m/s
    Climb_Vel_End = Climb_Mach_End*a_end; %m/s
    Climb_Vel_Avg = Climb_Mach_Avg*a; %m/s
    Delta_he = (Climb_Alt_End+(Climb_Vel_End)^2/(2*g))-(Climb_Alt_Start+(Climb_Vel_Start)^2/(2*g)); %Change in enegy height (m)

    %Average Drag
    Climb_CL = W_start/(0.5*rho*Climb_Vel_Avg^2*Sref); %Assuming L ~ W at start of climb
    [CD,CDo_msn,k1_msn,k2_msn,msgs] = DragPolar_Function(Climb_Mach_Avg,Climb_CL,Config_Row,DragPolar_Model,WaveDrag_Data,msgs);
    CD = CD+CDx_Climb; %Add any external parasite drag
    D = (CD)*(0.5*rho*Climb_Vel_Avg^2*Sref); %Average Drag (N)


    if strcmp(PropType,'PROP_Electric')

        %Average Thrust or Power & TSFC or SFC
        %%NOTE INPUTS TO THIS FUNCTION HAVE TO BE IN US CUSTOMARY UNITS
        %conversions back done inline
        %output PA_max output for electric will be in units of W

        [~,~,~,~,~,~,~,PA_max,~,~,msgs] =...
            Propulsion(Climb_Alt_Avg*3.281,Climb_Mach_Avg,Config_Row,Propulsion_Input,msgs);



        P_req=Climb_Vel_Avg*D;
        if (P_req>PA_max)
            msgs.warnings{end+1} = 'Power insufficient for climb based on drag & power required!';
            warning(msgs.warnings{end,:})
        end
        ROC = (PA_max-Climb_Vel_Avg*D)/W_start; %Rate of climb in m/s
        TOC = ((Climb_Alt_End - Climb_Alt_Start)/ROC)/60; %Time of climb in min
        T = PA_max/Climb_Vel_Avg; %Calculate average thrust during climb out and acceleration

        %Climb Weight Fraction Model
        %the h term has to be in units of km. Raymer 20.9
        Climb_bm_fraction=(Climb_Alt_End/1000-Climb_Alt_Start/1000)/((3.6)*ROC*Esb_Real*nb2s) *P_req/(Prop_Eff*W_start/g);


    else
        error("Only PROP_Electric propulsion types supported.")

    end

    %Record Climb Performance Data
    C=0; %C=TSFC
    %conversions back to imperial units done inline
    CLIMB_DATA= table(Delta_he*3.281,Climb_CL,CD,CDo_msn,k1_msn,k2_msn,D/4.448,T,C,ROC*3.281,TOC*3.281);

end
