function [WaveDrag_Data,msgs] = ...
        WaveDrag(Design_Input,Airfoil,InducedDrag_Data,Count,Plot_WaveDrag_Data,Parasite_Drag_Data,msgs)
    %%  Wave Drag Summary
    % This function utilized the Sear-Haack body wave drag model (outlined in Raymer, 12.5.9)
    % based on the aircraft configuration geometry information from the Design Input,
    % Airfoil, and WingGeo_Data tables.  Additionally, it leverages the
    % standard atmosphere properties from the ATMOS table. The output table
    % for this function includes the wave drag coefficient (CDw), and
    % a breakdown of the critical mach and drag divergence mach estimations using
    % Brandt's methodology.
    % All these calculation are done for each configruation in the Design Input spreadsheet.

    %% Outputs:
    %
    % Wave Drag Data:
    %   Table containing wave drag coefficient at key Mach values


    %% Preallocate variables of interest

    EWD = zeros(Count, 1); % Emperical Wave Drag Efficiency Factor
    M_cr = zeros(Count, 1); % Critical Mach
    M_DD = zeros(Count, 1); % Drag divergence mach
    M_wave_max = zeros(Count, 1); %Mach where wave drag rise is maximized
    M_max_design = zeros(Count, 1); %Maximum design mach (user defined via design input spreadsheet)
    Dq_sears = zeros(Count, 1); %
    Dq_wave_max = zeros(Count, 1); %
    Dq_M_max = zeros(Count, 1); %
    CDw_max = zeros(Count, 1); % Total wave drag coefficient at mach for max wave drag rise
    CDw_M_max = zeros(Count, 1); % Total wave drag coefficient at mach for max wave drag rise
    k1_super = zeros(Count, 1); % Supersonic induced drag constant at max wave drag
    k2_super = zeros(Count, 1); % No impact of camber during supersonic flight on drag polar (values stay at zero)
    k1_super_M_max=zeros(Count,1);
    k2_super_M_max=zeros(Count,1);
    k1_super_w_max=zeros(Count,1);
    k2_super_w_max=zeros(Count,1);


    %% Loop through different configurations
    for n = 1:Count
        
        %Estimate critical mach value
        M_cr(n) = 1 - 0.065*(cosd(Design_Input.Sweep_w(n)))^0.6*(100*Airfoil.Thick_w(n))^0.6; %Estimation of critical mach value (Brandt)
        %Estimation of drag divergence mach value
        M_DD(n) = M_cr(n)+0.08; %Estimation of drag divergence mach (Boeing via Raymer); Douglas & AF use 0.06 above Mcrit

        %Estimation of maximum wave drag rise mach value
        M_wave_max(n) = 1/(cosd(Design_Input.Sweep_w(n))^0.2); %Estimation of mach for max wave drag rise (Brandt). Value ~1.05 typically

        if Design_Input.M_max(n)>M_DD(n)

            
            %Define max designed mach
            M_max_design(n) = Design_Input.M_max(n); %Design input for maximum mach of aircraft


            if Design_Input.M_max(n)>M_DD(n) && Design_Input.M_max(n)<1.2
                msgs.warnings{end+1} = "For aircraft configuration in row " +num2str(n)+ ": Drag Divergence Mach < Design Input Mach < M=1.2. Proceeding using M=1.2 as design mach for wave drag calculations.";
                warning(msgs.warnings{end,:})
                M_max_design_used=1.2;
            else
                M_max_design_used=M_max_design(n);
            end


            % Emperical Wave Drag Efficiency Factor
            EWD(n) = Design_Input.EWD(n); %Emperical wave drag efficiency factor pulled from design input spreadsheet file. Ratio of actual vs Sears-Haack value.

            %Estimate Sears-Haack Body Wave Drag (D/q)_sears
            Dq_sears(n) = 9*pi/2*(Design_Input.Amax_f(n)/Design_Input.Length_f(n))^2; %Sears-Haack Body wave drag

            %Estimate Maximum Aircraft Wave Drag (D/q)_wave_max at M = 1.2 &
            %M_wave_max
            Dq_wave_max(n) = EWD(n)*Dq_sears(n); %Value varies with mach above 1.2;

            %Estimate Aircraft Wave Drag at max design mach (D/q)_M_max
            Dq_M_max(n) = EWD(n)*(1-0.386*(M_max_design_used-1.2)^0.57*(1-(pi*Design_Input.Sweep_w(n)^0.77)/100))*Dq_sears(n); %Wave drag at design mach

            %Calculate wave drag coefficients
            CDw_max(n) = Dq_wave_max(n)/Design_Input.Sref_w(n);
            CDw_M_max(n) = Dq_M_max(n)/Design_Input.Sref_w(n);


            %Calculate induced drag k1 value for max design max mach
            k1_super_M_max(n) = (Design_Input.AR_w(n)*(M_max_design_used^2-1))/(4*Design_Input.AR_w(n)*sqrt(M_max_design_used^2-1)-2)*cosd(Design_Input.Sweep_w(n));
            k2_super_M_max(n) = 0;

            %Calculate induced drag k1 value for mach at peak wave drag
            %(M_wave_max)

            k1_super_model = (Design_Input.AR_w(n)*(M_wave_max(n)^2-1))/(4*Design_Input.AR_w(n)*sqrt(M_wave_max(n)^2-1)-2)*cosd(Design_Input.Sweep_w(n));
            k1_super_avg = (k1_super_M_max(n)+InducedDrag_Data.k1_sub(n))/2; %Average between max mach k1 and subsonic k1 values
            k1_super_w_max(n) = max(k1_super_model,k1_super_avg);
            k2_super_w_max(n) = 0;
        else
            M_max_design(n) = Design_Input.M_max(n); %Design input for maximum mach of aircraft
            CDw_max(n) = 3*Parasite_Drag_Data.CDo(n); %set max wave drag to analytical estimate
            k1_super_M_max(n)=0;
            k2_super_M_max(n)=0;
            k1_super_w_max(n)=InducedDrag_Data.k1_sub(n);
            k2_super_w_max(n)=0;
        end



    end

    %% Oraganize into tables for output
    WaveDrag_Data = table(M_cr,M_DD,M_wave_max,M_max_design,EWD,Dq_sears,Dq_wave_max,Dq_M_max,CDw_max,k1_super_w_max,k2_super_w_max,CDw_M_max,k1_super_M_max,k2_super_M_max);

    %% Plots for this function (Fig 500 - 599)
    % if Plot_Parasite_Data == 1
    %     figure(500)
    % end

end

