function [W_S_stall_req,Stall_REQ_DATA,msgs] = Stall_Constraint_EQ(Req_Inputs,Constants,msgs)

%Evaluates W/S requirements based on
%point performance inputs for desired stall velocity assuming SLUF at full
%takeoff weight.


%Unpack constants array

g = Constants{1,1};
Config_Row = Constants{1,2};
Wo = Constants{1,3};
Sref_initial = Constants{1,4};
rho_sl = Constants{1,5};
a_sl = Constants{1,6};

%Unpack Point Performance Inputs

h = Req_Inputs{1,1};
CL_max_stall = Req_Inputs{1,2};
V_stall_req = Req_Inputs{1,3}*6076/3600; %Converts desired stall velocity from knots to ft/s

%Calculate atmospheric properties based on input altitude (h)
[rho,a,T,P,nu,z] = atmos(h,'units','US');


%Determine required W/S for Stall Req assuming SLUF at full takeoff weight

W_S_stall_req = V_stall_req^2*(rho*CL_max_stall/2); %Stall velocity req for W/S requried

%Write data used in calculations for analysis
Data_Array = {h,V_stall_req,CL_max_stall,W_S_stall_req};
tablenames = {'h','V_stall_req','CL max stall','W_S_stall_req'};
Stall_REQ_DATA = cell2table(Data_Array,VariableNames=tablenames);

end