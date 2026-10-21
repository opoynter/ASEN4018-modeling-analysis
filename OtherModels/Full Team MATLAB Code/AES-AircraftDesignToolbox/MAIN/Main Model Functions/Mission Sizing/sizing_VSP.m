function [W0,FinalWeightData,IterationData,FinalSegmentData,outputTable,DragPolar_Model,WaveDrag_Data,msgs]=sizing_VSP(MSN_Profile,Config_Row,W0_guess,Design_Input,Propulsion_Input,W_crew,W_pay_fixed,W_pay_drop,file_location,sub_parasite_file_name,sub_aero_file_name,peakWave_wave_file_name,peakWave_parasite_file_name,maxDesign_wave_file_name,maxDesign_parasite_file_name,msgs)
    %% Aircraft Design Mission Performance Sizing Analysis
    % ASEN 4138
    % Author: John Mah, Maggie Wussow, Jonathan Morris

    % Description:  This function estimates the fuel burn utilized through a
    % user defined mission profile through multiple iterations to converge on a
    % estimate for aircraft total weight.  The user must first model the aircraft
    % aerodynamically via Open VSP and provide an initial "guess" at the 
    % total aircraft weight to begin the iterative process. 
    % The mission profile should be defined in
    % an excel sheet (e.g. Mission_Profile_Template.xlsx). The initial
    % guess weight is updated after each iteration with the average value
    % between the guess weight and the calculated weight at the end of the
    % mission analysis.  Script will stop iterations once the aircraft total
    % weight calcluated converges with the initial guess of the
    % aircraft total weight within a user defined percentage.

    %% Current Version:  AY24.??
    % Date Last Change: 23 Nov 24
    % Changes in Current Version: Refactored as a function from main
    % script. Now the code expects a mission profile defined by an excel
    % sheet. This sheet should be read in with Read_MSN_Profile.m which
    % returns a MSN_Profile structure. This profile is then interpreted by
    % the MSN_SEG_Handler.m function which calls the appropriate MSN_SEG
    % funtion and returns weight/battery mass fraction data.
    %
    % Functions & files required to execute this function
    %4138_Design Input File_V24-00.xlsx
    %aero_analyis.m (and its outputs)
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
    %MSN_SEG_TO.m
    %MSN_SEG_Climb.m
    %MSN_SEG_Cruise.m
    %MSN_SEG_Loiter.m
    %MSN_SEG_Handler.m


    %% Instructions
    % Please folow procedure instructions posted to canvas for getting all the
    % openVSP analysis integrated into this script.
    % Reminder all variables unique to aircraft configuration should be changes
    % in the section right below and the mission segments/profile should be
    % changed to reflect YOUR airacfts mission profile.


    %%%%%%%%%%%%%%%%%%TWEAKABLES%%%%%%%%%%%%%%%%%%%%%%
    %These are factors that may need to be editted for certain designs.
    Converge = 0.005; %Sets the percent difference between W0_guess and W0_calc to determine solution has converged
    Kvs = 1; %From Raymer Table 6.1 based on variable sweep (1.04) or fixed sweep (1.0)
    Composite_Factor=1; %Using the composite homebuilt model it was found that multiplying the empty weight fraction by 0.8-0.9 lined up more closely with serial produced composite aircraft. The Raymer text reccomends a similar approach.
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


    %%Initialization
    Config=Config_Row;

    %%%
    ACType = Design_Input.ACType{Config};
    M_max = Design_Input.M_max(Config);
    AR = Design_Input.AR_w(Config);
    Sref = Design_Input.Sref_w(Config);
    %Sweep = Design_Input.Sweep_w(Config);
    Thick_w = Design_Input.AirfoilThick_w(Config);
    PropType = Propulsion_Input.PropType{Config};

    %% AIRCRAFT WEIGHT AND GEOMETRY INPUTS

    %Start Mission Sizing Iterations
    Diff_W0 = 1; %Set initial value in total weight difference to 100% or 1



    %Constants
    g = 32.2; %Accel of gravity (ft/s^2);

    % Added to ensure the Drag Function still functions properly without any
    % changes
    
    WaveDrag_Data.M_max_design = Design_Input.M_max;
    WaveDrag_Data.M_cr = 1 - 0.065*(cosd(Design_Input.Sweep_w)).^0.6*(100*Thick_w).^0.6; %Estimation of critical mach value (Brandt)
    WaveDrag_Data.M_DD=WaveDrag_Data.M_cr+0.08;
    for wd = 1:length(Design_Input.M_max) %needs to run through all configs seperately
        if WaveDrag_Data.M_DD(wd) < WaveDrag_Data.M_max_design(wd)
            WaveDrag_Data.M_wave_max(wd) = 1/(cosd(Design_Input.Sweep_w(wd)).^0.2); %Estimation of mach for max wave drag rise (Brandt). Value ~1.05 typically.
        else
            WaveDrag_Data.M_wave_max(wd) = 0;
        end
    end

    %% PROPULSION INPUTS
    %Jet Engine Values (if propellor propulsion, set all to zero)
    TA_mil_sl = Propulsion_Input.Number(Config)*Propulsion_Input.TA_mil_sl(Config); %Uninstalled Mil power total thrust at sea level (all engines)
    TA_AB_sl = Propulsion_Input.Number(Config)*Propulsion_Input.TA_AB_sl(Config); %Uninstalled AB power total thrust at sea level (all engines)
    %TSFC_mil_sl = Propulsion_Input.TSFC_mil_sl(Config);
    %TSFC_AB_sl = Propulsion_Input.TSFC_AB_sl(Config);
    %Prop Engine Values (if jet propulsion, set all to zero)
    PA_shp_sl = Propulsion_Input.Number(Config)*Propulsion_Input.PA_shp_sl(Config); %shaft horsepower from engine at sea level (hp) total (all engines)
    %SFC_sl = Propulsion_Input.SFC_sl(Config); %specific fuel consumption for prop engine at sea level (lb/(hp*s))
    %Prop_Eff = Propulsion_Input.Prop_eff(Config);
    NumEng=Propulsion_Input.Number(Config);


    %% PACKAGE CONSTANTS AND ATMOSPHERE
    Constants = {Config,AR,Sref,M_max,g,PropType}; %Package for use in functions

    %Set sea level std atmosphere values
    [~,a_sl,~,~,~,~] = atmos(0,'units','US'); %sea level std atmosphere properties

    %% OPEN VSP FUNCTION TO MAKE DRAG POLARS

    % need to loop through all the configs to make string arrays with all the
    % names of the files so drag polar open vsp can pul the correct files
    for dp = 1:length(Design_Input.M_max)
        sub_parasite{dp} = strcat(file_location,sub_parasite_file_name{dp});
        sub_aero{dp} = strcat(file_location,sub_aero_file_name{dp});

        peakWave_wave{dp} = strcat(file_location,peakWave_wave_file_name{dp});
        peakWave_parasite{dp} = strcat(file_location,peakWave_parasite_file_name{dp});
        maxDesign_wave{dp} = strcat(file_location,maxDesign_wave_file_name{dp});
        maxDesign_parasite{dp} = strcat(file_location,maxDesign_parasite_file_name{dp});
    end

    [DragPolar_Model,msgs] = DragPolar_OpenVSP(Design_Input,WaveDrag_Data,sub_parasite,sub_aero,peakWave_wave,peakWave_parasite,maxDesign_wave,maxDesign_parasite,length(Design_Input.M_max),msgs);

    %% MISSION ANALYSIS ITERATIVE SIZING
    %Set Convergence Criteria

    [a,c1,c2,c3,c4,c5,msgs]= WeightModel(PropType,ACType,msgs);

    i = 1; %Weight iteration number initlization

    while Diff_W0 >= Converge

        %Calculate Aircraft Parameters & Empty Weight based on Total Weight
        %(W0) and statistical model
        disp("Iteration "+ num2str(i)+ ": Gross Takeoff Weight Guess: "+ W0_guess)

        if strcmp(PropType,'PROP_Fuel')|strcmp(PropType,'PROP_Electric')
            Power_Weight_Ratio = PA_shp_sl/W0_guess; %in hp/lb shaft hp at sea level/Wo

            V_max = (M_max*a_sl)*(3600/6076); %Max velocity in terms of knots (must convert ft/s to knots using 6076 ft per nautical mile and 3600 sec per hr).
            WingLoading = W0_guess/Sref;

            %Statistical empty weight fraction model for prop aircaft
            We_W0 = (a*(W0_guess)^c1*(AR)^c2*(Power_Weight_Ratio)^c3*(WingLoading)^c4*(V_max)^c5)*Kvs;
            We_W0=We_W0*Composite_Factor;

            We = We_W0*W0_guess; %Empty weight of aircraft (lb)
        else
            Thrust_Weight_Ratio_mil = TA_mil_sl/W0_guess; %Uninstalled thrust at sea level / Wo
            Thrust_Weight_Ratio_AB = TA_AB_sl/W0_guess; %Uninstalled thrust at sea level / Wo
            Thrust_Weight_Ratio = max(Thrust_Weight_Ratio_AB,Thrust_Weight_Ratio_mil); %Size based on max value of T/W
            WingLoading = W0_guess/Sref;
            %Statistical empty weight fraction model for jet aircaft
            We_W0 = (a*(W0_guess)^c1*(AR)^c2*(Thrust_Weight_Ratio)^c3*(WingLoading)^c4*(M_max)^c5)*Kvs;
            We_W0=We_W0*Composite_Factor;

            We = We_W0*W0_guess; %Empty weight of aircraft (lb)
        end
        %correction for serial composite production when using homebuilt
        %composite model
        %MSN_SEG_Handler replaces past versions of the code where the users
        %editted calls to MSN_SEG functions manually. MSN_SEG_Handler takes
        %in the mission profile and calls different MSN_SEG functions based
        %on user inputs. Returns weight/battery mass fraction and debugging
        %data for each segment and each convergence iteration.
        [W_Mat,BMF_Mat,DATA,msgs]=MSN_SEG_Handler(MSN_Profile,W0_guess,Constants,Propulsion_Input,DragPolar_Model,WaveDrag_Data,msgs);
        config=Constants{1};
        PropType=Propulsion_Input.PropType(config);
        if strcmp(PropType,"PROP_Electric")
            BMF=sum(BMF_Mat);
            W0_calc=(W_crew+W_pay_fixed)/(1-BMF-We_W0);
            %% Calc Difference Between W0_guess and W0_calc
            Diff_W0 = abs(W0_guess-W0_calc)/W0_guess;
            IterationData(i,:)=[i,W0_calc,We,BMF]; %#ok<AGROW>
            %% Next Iteration Update
            i = i + 1;
            W0_guess = (W0_guess+W0_calc)/2;


        else

            W_f_total_used=sum(W_Mat(:,3)); %Total amount of fuel burned for mission
            W_f_total_refuel=sum(W_Mat(:,5)); %Total amount of air refuel added in mission
            W_f_req_internal=W_f_total_used-W_f_total_refuel; %Total amount of fuel that must be carried internally
            W0_calc = W_crew + W_pay_fixed + W_pay_drop + W_f_req_internal + We; %Calcuated aircraft total weight based on mission

            %% Calc Difference Between W0_guess and W0_calc
            Diff_W0 = abs(W0_guess-W0_calc)/W0_guess;
            IterationData(i,:)=[i,W0_calc,We,W_f_total_used]; %#ok<AGROW>

            %% Next Iteration Update
            i = i + 1;
            W0_guess = (W0_guess+W0_calc)/2;


        end



    end

    if strcmp(PropType,"PROP_Electric")
        W0=W0_calc;

        FinalWeightData=[MSN_Profile.legtype',BMF_Mat'];
        FinalWeightData=array2table(FinalWeightData);
        FinalWeightData.Properties.VariableNames=["Leg Type","BMF"];
        IterationData=array2table(IterationData);
        IterationData.Properties.VariableNames=["Iteration Number","W0 [lb]","Empty Weight [lb]","BMF"];
        FinalSegmentData=DATA;

    else
        W0=W0_calc;
        FinalWeightData=[MSN_Profile.legtype',W_Mat];
        FinalWeightData=array2table(FinalWeightData);
        FinalWeightData.Properties.VariableNames=["Leg Type","Starting Weight [lb]","Ending Weight [lb]", "Fuel Weight [lb]", "Weight Fraction", "Fuel Added"];

        IterationData=array2table(IterationData);
        IterationData.Properties.VariableNames=["Iteration Number","W0 [lb]","Empty Weight [lb]","Total Fuel Weight [lb]"];
        FinalSegmentData=DATA;

    end
    %%Data Tables and Visualizations
    %Convert data structure to table
    %T_SizingStruct = structfun(@transpose, SizingStruct, 'UniformOutput', false); %transpose data in structues for ease of reading
    %Msn_Sizing_Table = struct2table(T_SizingStruct);

    % Added in tables for easy display purposes (changes to P/W if prop vs T/W
    % % for jet)
    if strcmp(PropType,'PROP_Fuel')||strcmp(PropType,'PROP_Turbocharged')||strcmp(PropType,'PROP_Turboprop')
        %recalculate wing loading and power to weight ratio for final W0
        WingLoading = W0_calc/Sref;
        Power_Weight_Ratio =PA_shp_sl/W0_calc;
        % construct output table
        tableNames = {'W0(lb)', 'Wf req internal(lb)', 'Wf total air refuel(lb)', 'We(lb)', 'Wing Loading(lb/ft^2)','P/W(hp/lb)'};
        outputTable = table(W0_calc,W_f_req_internal,W_f_total_refuel,We,WingLoading,Power_Weight_Ratio, 'VariableNames', tableNames);
    elseif strcmp(PropType,'PROP_Electric')
        %recalculate wing loading and power to weight ratio for final W0
        WingLoading = W0_calc/Sref;
        Power_Weight_Ratio =PA_shp_sl/W0_calc;
        % construct output table
        tableNames = {'W0(lb)', 'Battery Mass (lb)', 'We(lb)', 'Wing Loading(lb/ft^2)','P/W(hp/lb)'};
        outputTable = table(W0_calc,BMF*W0_calc,We,WingLoading,Power_Weight_Ratio, 'VariableNames', tableNames);
    else
        %recalculate wing loading and thrust to weight ratio for final W0
        WingLoading = W0_calc/Sref;
        Thrust_Weight_Ratio_mil =TA_mil_sl/W0_calc;
        Thrust_Weight_Ratio_AB = TA_AB_sl/W0_calc;
        % construct output table
        tableNames = {'W0(lb)', 'Wf req internal(lb)', 'Wf total air refuel(lb)', 'We(lb)', 'Wing Loading(lb/ft^2)','T/W mil(lb/lb)', 'T/W AB (lb/lb)'};
        outputTable = table(W0_calc,W_f_req_internal,W_f_total_refuel,We,WingLoading,Thrust_Weight_Ratio_mil,Thrust_Weight_Ratio_AB, 'VariableNames', tableNames);
    end


end













