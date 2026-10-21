function msgs = point_performance(Design_Input,Config,W0_calc,Propulsion_Input,DragPolar_Model,WaveDrag_Data,outputTable,Req_Input,W_S_range,msgs)
    %% Aircraft Design Point Performance / Constraint Sizing Analysis
    % ASEN 4138
    % Author: John Mah, Maggie Wussow, Jonathan Morris

    % Description:  This program estimates the thrust to weight (T/W) and wing loading
    % (W/S) requriements to acheive point performance design requirements for an aircraft.
    % Values for T/W and W/S are based on sea level static thrust (T_sl) and total aircraft weigh (Wo).
    % Constraint analysis provides a plot showing minimum values of T/W and W/S
    % required for multiple user defined point performance requirements which
    % define a "design space" of acceptable T/W and W/S combinations.  The
    % optimal design point is defined as the lowest T/W and highest W/S combo
    % that acheives all point performance requirements.

    %% Current Version:  AY24.00
    % Date Last Change: 1 Aug 24
    % Changes in Current Version: Initial Version.
    % Functions & files required to execute this script
    %4138_Design Input File_V24-00.xlsx
    %ASEN 4138_Aircraft_Design_Aero_Model_Main.m
    %atmos.m
    %DragPolar.m
    %DragPolar_Function.m
    %InducedDrag.m
    %LD.m
    %ParasiteDrag.m
    %Propulsion.m
    %WaveDrag.m
    %WingGeo.m
    %WingLiftDrag.m


    %% Instructions
    % During initial conceptual evaluation, the
    % ASEN4138_Aircraft_Design_Aero_Model_Main.m script and
    % ASEN4138_Aircraft_Mission_Performance_Sizing.m script
    % should be executed prior to utilization of this code to create the drag polar and propulsion
    % properties of the aircraft configuration concept required to run a
    % mission performance sizing. However, after refining and modeling the
    % concept in OPEN VSP, you should hard-code OPEN VSP values into tge drag polar values into the
    % DragPolar_Function.m fuction and update any propulsion static sea level values in
    % the Propulsion.m function.

    %%Initialization
    %Close prior figures


    %Set sea level std atmosphere values & accel of gravity constant
    [rho_sl,a_sl,T_sl,P_sl,nu_sl,z_sl] = atmos(0,'units','US'); %sea level std atmosphere properties
    g = 32.2; %Accel of gravity (ft/s^2)

    %Set aircraft configuration evaluated based on row number in Design Input
    Config_Row = Config; %Sets row of design input spreadsheet being evaluated or if using OPEN VSP, the array index of the configuration being evaluated based on Mission Analysis array setup

    %Set aircraft total weight from mission analysis sizing (or manually)
    Wo = W0_calc; %Pulls final aircraft total weight from value calculated in mission performance sizing. Can manually change if requried.

    %Set aircraft initial wing planform area (if using OpenVSP for aero analysis, make sure Config_Row =1 in line 52)
    Sref_initial = Design_Input.Sref_w(Config_Row); %MUST UPDATE AFTER RESIZING! You will determine actual Sref needed from selected design point from this analysis.

    %Consolidate constants for use in Constraint_Eq function
    Constants = {g,Config_Row,Wo,Sref_initial,rho_sl,a_sl}; %Consolidates needed properties in single array




    [X_Y_req,X_Req_Data,msgs] =Point_Performance_Handler(Req_Input,Constants,W_S_range,Propulsion_Input,Config_Row,DragPolar_Model,WaveDrag_Data,msgs);
    PropType=Propulsion_Input.PropType;
    PropType=PropType(Config_Row);

    reqtype=Req_Input.reqtype;
    if strcmp(PropType,'PROP_Fuel')||strcmp(PropType,'PROP_Electric')||strcmp(PropType,'PROP_Turbocharged')||strcmp(PropType,'PROP_Turboprop')

        figure
        hold on
        for i=1:length(reqtype)
            switch(reqtype(i))

                case "Stall Velocity"
                    xline(X_Y_req(i,1),'-.k')
                case "Landing Distance"
                    xline(X_Y_req(i,1),'--k')

                otherwise
                    plot(W_S_range,X_Y_req(i,:))
            end


        end
        if strcmp(PropType,'PROP_Electric')
            W_S_0=outputTable{1,4};
            P_W_0=outputTable{1,5};
        else
            W_S_0=outputTable{1,5};
            P_W_0=outputTable{1,6};
        end

        plot(W_S_0,P_W_0,'Marker','diamond','MarkerSize',10);
        leg_lab=[Req_Input.labels,"Current DP"];
        legend(leg_lab)
        xlabel('Wing Loading (W/S) - lb/ft^2');
        ylabel('Power to Weight (P/W) - hp/lb (sea level, shaft hp, total weight');
        title('Point Performance Sizing: Constraint Diagram (Power)');


    else


        figure
        hold on
        for i=1:length(reqtype)
            switch(reqtype(i))

                case "Stall Velocity"
                    xline(X_Y_req(i,1),'-.k')
                case "Landing Distance"
                    xline(X_Y_req(i,1),'--k')

                otherwise
                    plot(W_S_range,X_Y_req(i,:))
            end


        end
        W_S_0=outputTable{1,5};
        T_W_0_mil=outputTable{1,6};
        T_W_0_AB=outputTable{1,7};
        plot(W_S_0,T_W_0_mil,'Marker','diamond','MarkerSize',10);
        plot(W_S_0,T_W_0_AB,'Marker','square','MarkerSize',15);
        leg_lab=[Req_Input.labels,"Current DP (mil)","Current DP (AB)"];
        legend(leg_lab)
        xlabel('Wing Loading (W/S) - lb/ft^2');
        ylabel('Thrust to Weight (T/W) - sea level static, total weight');
        title('Point Performance Sizing: Constraint Diagram (Thrust)');
    end






   

end





