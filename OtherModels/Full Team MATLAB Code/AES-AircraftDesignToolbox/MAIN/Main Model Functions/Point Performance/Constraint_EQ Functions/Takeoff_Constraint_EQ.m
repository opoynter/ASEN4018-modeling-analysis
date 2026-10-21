function [T_W_TOreq,P_W_TOreq,TO_REQ_DATA,msgs] = Takeoff_Constraint_EQ(Req_Inputs,Constants,W_S_range,Propulsion_Input,DragPolar_Model,WaveDrag_Data,msgs)

%Master Constraint Equation function evaluates T/W or P/W requirements based on
%point performance inputs for a wide range of performance requirements.
%Equation is based on specific excess power models and will determine the
%minmum T/W or P/W ratios required for a range of user defined wing loading
%options.


%Unpack constants array

g = Constants{1,1};
Config_Row = Constants{1,2};
Wo = Constants{1,3};
Sref_initial = Constants{1,4};
rho_sl = Constants{1,5};
a_sl = Constants{1,6};

%Unpack Point Performance Inputs

Beta = Req_Inputs{1,1};
h = Req_Inputs{1,2};
Throttle = Req_Inputs{1,3};
CL_max_TO = Req_Inputs{1,4};
Roll_Fric = Req_Inputs{1,5};
CDx = Req_Inputs{1,6};
S_TO = Req_Inputs{1,7};

%Calculate atmospheric properties based on input altitude (h)
[rho,a,T,P,nu,z] = atmos(h,'units','US');

 %Takeoff velocity estimation
 V_stall = sqrt(2*Wo*Beta/(rho*CL_max_TO*Sref_initial)); %Estimation of stall velocity (ft/s)
 V_TO = 1.2*V_stall; %Estimated takeoff velocity (ft/s)
 M = V_TO/a; %Convert takeoff velocity to mach for propulsion function
      
 %Takeoff Propulsion Properties
 [TA_mil_max,TA_AB_max,T_mil_lapse,T_AB_lapse,TSFC_lapse,TSFC_mil,TSFC_AB,PA_max,P_lapse,SFC] =...
        Propulsion(h,M,Config_Row,Propulsion_Input);

%Set thrust or power lapse model based on throttle input
if strcmp(Throttle,'AB')
    alpha_lapse = T_AB_lapse;
elseif strcmp(Throttle,'MIL')
    alpha_lapse = T_mil_lapse;
elseif strcmp(Throttle,'PROP');
    alpha_lapse = P_lapse;
else
     msg = 'Set proper Takeoff THROTTLE variable value based if AB, MIL, or PROP is used';
     errordlg(msg,'THROTTLE VARIABLE ERROR','non-modal');
end

%Calculate drag polar using DragPolar_Function and input mach
[CD,CDo_msn,k1_msn,k2_msn] = DragPolar_Function(M,CL_max_TO,Config_Row,DragPolar_Model,WaveDrag_Data);

%Determine required T/W and P/W for Req using Takeoff Constraint Equation
%(Based on constant force acceleration takeoff groundroll model)

T_W_TOreq = (1.44*Beta^2)/(alpha_lapse*rho*CL_max_TO*g*S_TO).*(W_S_range)+(0.7*(CDo_msn+CDx)/(Beta*CL_max_TO))+Roll_Fric;
Ve = (V_TO/(sqrt(rho_sl/rho))); %Adjust velocity down to sea level equivalent velocity for same dyn pressure at altitude for Power at sea level req.
P_W_TOreq = (T_W_TOreq*Ve)/550; %Converts T/W to P/W ratio and converts P/W to horsepower/lb.

%Write data used in calculations for analysis
Data_Array = {Beta,h,M,V_TO,Ve,Throttle,alpha_lapse,Roll_Fric,CDx,CL_max_TO,CDo_msn,k1_msn,S_TO};
tablenames = {'Beta','h','M','V_TO','Ve','Throttle','alpha_lapse','Roll_Fric','CDx','CL_max_TO','CDo','k1','S_TO'};
TO_REQ_DATA = cell2table(Data_Array,VariableNames=tablenames);

end