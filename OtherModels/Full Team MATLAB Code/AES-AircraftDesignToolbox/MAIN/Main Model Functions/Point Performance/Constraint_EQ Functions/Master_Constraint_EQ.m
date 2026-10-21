function [T_W_req,P_W_req,PP_REQ_DATA,msgs] = Master_Constraint_EQ(Req_Inputs,Constants,W_S_range,Propulsion_Input,DragPolar_Model,WaveDrag_Data,msgs)

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
M = Req_Inputs{1,3};
n = Req_Inputs{1,4};
Throttle = Req_Inputs{1,5};
P_s = Req_Inputs{1,6};
Accel = Req_Inputs{1,7};
CDx = Req_Inputs{1,8};

%Calculate atmospheric properties based on input altitude (h)
[rho,a,T,P,nu,z] = atmos(h,'units','US');

%Calculate velocity from mach input
V = M*a; %ft/s

%Run propulsion function model for given inputs

[TA_mil_max,TA_AB_max,T_mil_lapse,T_AB_lapse,TSFC_lapse,TSFC_mil,TSFC_AB,PA_max,P_lapse,SFC] =...
    Propulsion(h,M,Config_Row,Propulsion_Input);

%Set thrust or power lapse model based on throttle input
if strcmp(Throttle,'AB')
    alpha_lapse = T_AB_lapse;
elseif strcmp(Throttle,'MIL')
    alpha_lapse = T_mil_lapse;
elseif strcmp(Throttle,'PROP')
    alpha_lapse=P_lapse;

else
     msg = 'Set proper THROTTLE variable value based if AB, MIL, or PROP is used';
     errordlg(msg,'THROTTLE VARIABLE ERROR','non-modal');
end

%Calculate Dynamic Pressure based on inputs
q = 0.5*rho*V^2; %Dynamic pressure (lb/ft^2)

%Calculate coefficient of lift based on input total weight and load factor
CL = (n*Wo*Beta)/(q*Sref_initial); %Note, Sref is based on current geometry and is needed for using the DragPolar_Function.m to function, however, it is not used in the Constraint Analysis so it doesn't matter the value

%Calculate drag polar using DragPolar_Function and input mach
[CD,CDo_msn,k1_msn,k2_msn] = DragPolar_Function(M,CL,Config_Row,DragPolar_Model,WaveDrag_Data);

%Determine required T/W and P/W for Req using Constraint Master Equation

T_W_req = (Beta/alpha_lapse)*((q/Beta)*((CDo_msn+CDx)./W_S_range+k1_msn*(n*Beta/q)^2.*W_S_range)+(1/V)*(P_s)+(1/g)*(Accel));
Ve = (V/(sqrt(rho_sl/rho))); %Adjust velocity down to sea level equivalent velocity for same dyn pressure at altitude for Power at sea level req.
P_W_req = (T_W_req*Ve)/550; %Converts T/W to P/W ratio and converts P/W to horsepower/lb. 

%Write data used in calculations for analysis
Data_Array = {Beta,h,M,V,Ve,n,Throttle,P_s,Accel,CDx,CL,CDo_msn,k1_msn};
tablenames = {'Beta','h','M','V','Ve','n','Throttle','P_s','Accel','CDx','CL','CDo','k1'};
PP_REQ_DATA = cell2table(Data_Array,VariableNames=tablenames);

end