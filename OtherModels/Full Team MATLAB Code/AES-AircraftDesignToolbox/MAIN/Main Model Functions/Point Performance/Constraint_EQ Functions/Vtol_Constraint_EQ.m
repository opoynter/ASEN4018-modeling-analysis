function [P_W_Vtol_req,VTOL_REQ_DATA,msgs] = Vtol_Constraint_EQ(Req_Inputs,Constants,Propulsion_Input,VTOL_Characteristics,msgs)
    %VTOL Constraint Equation function evaluates P/W requirements
    %based on user inputs. Only Valid for Propeller based VTOL. 
    %Based on Raymer Ch 21
    %ASEN 4138
    %Jonathan Morris
 

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
    V_climb=Req_Inputs{1,3};
    %Calculate Weight for Constraint
    W=Wo*Beta;

    % Unpack VTOL Specific Characteristics
    A=pi*(38/2)^2;%%VTOL_Characteristics{1,1};
    eta_mechanical=.95;%Propulsion_Input.Prop_eff(Config_Row,:);%VTOL_Characteristics{1,2};
    M=.75;%VTOL_Characteristics{1,3};
    %Calculate atmospheric properties based on input altitude (h)
    [rho,~,~,~,~,~] = atmos(h,'units','US');

    PropType=Propulsion_Input(Config_Row,:).PropType;
    if strcmp(PropType,'PROP_Fuel')||strcmp(PropType,'PROP_Electric')||strcmp(PropType,'PROP_Turbocharged')||strcmp(PropType,'PROP_Turboprop')
        %Determine P/W req for vertical climb (Raymer 21.14)
        f=1.03;%adjustment for downwash on fuselage
        P_req=( ((f*W/M)*sqrt(f*W/(A*2*rho))) +W*V_climb/2)*(1/eta_mechanical);
        P_req=P_req/550;%converts to Hp
        P_W_Vtol_req=P_req/W;
    else
        error("Only Propeller Based VTOL supported by this function.");

    end

    %Write data used in calculations for analysis
    Data_Array = {Beta,h,V_climb,P_req};
    tablenames = {'Beta','h','V_Climb [ft/s]','P_Req [hp]'};
    VTOL_REQ_DATA = cell2table(Data_Array,VariableNames=tablenames);




end