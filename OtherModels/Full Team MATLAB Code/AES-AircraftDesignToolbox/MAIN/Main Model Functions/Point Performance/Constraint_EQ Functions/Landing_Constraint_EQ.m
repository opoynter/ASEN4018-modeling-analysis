function [W_S_Land_req,Land_REQ_DATA,msgs] = Landing_Constraint_EQ(Req_Inputs,Constants,DragPolar_Model,WaveDrag_Data,msgs)

%Landing Constraint Equation function evaluates W/S requirements based on
%point performance inputs for constant force deceleration landing
%groundroll model.  Assumes zero lift on touchdown, no thrust reversal.


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
CL_max_land = Req_Inputs{1,3};
Roll_Fric = Req_Inputs{1,4};
CDx = Req_Inputs{1,5};
S_Land = Req_Inputs{1,6};

%Calculate atmospheric properties based on input altitude (h)
[rho,a,T,P,nu,z] = atmos(h,'units','US');

%Landing approach velocity estimation
V_stall = sqrt(2*Wo*Beta/(rho*CL_max_land ...
     *Sref_initial)); %Estimation of stall velocity (ft/s)
V_Land = 1.3*V_stall; %Estimated landing velocity (ft/s)
M = V_Land/a; %Conversion to Mach for landing velocity
      
%Calculate drag polar using DragPolar_Function and input mach
[CD,CDo_msn,k1_msn,k2_msn] = DragPolar_Function(M,CL_max_land,Config_Row,DragPolar_Model,WaveDrag_Data);

%Determine required W/S for Req using Landing Constraint Equation
%(Based on constant force decceleration landing groundroll model)

W_S_Land_req = (S_Land*rho*g*(Roll_Fric*Beta*CL_max_land+0.083*(CDo_msn+CDx))/(1.69*Beta^2)); %Landing contstraint eq for W/S requried

%Write data used in calculations for analysis
Data_Array = {Beta,h,V_stall,V_Land,Roll_Fric,CL_max_land,CDx,CDo_msn,S_Land,W_S_Land_req};
tablenames = {'Beta','h','V_stall','V_Land','Roll_Fric','CL max land','CDx','CDo','S_Land','W_S_Land_req'};
Land_REQ_DATA = cell2table(Data_Array,VariableNames=tablenames);

end