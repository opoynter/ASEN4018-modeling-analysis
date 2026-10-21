function [Parasite_Data,FF_Table,msgs] = ...
    ParasiteDrag(Design_Input,Airfoil,WingGeo_Data,ATMOS,Count,Plot_Parasite_Data,msgs)
%%  Parasite Drag Summary
% This function performs the Raymer Component Drag Buildup Method to
% determine total and component parasite drag coefficients using the
% aircraft configuration geometry information from the Design Input,
% Airfoil, and WingGeo_Data tables.  Additionally, it leverages the
% standard atmosphere properties from the ATMOS table. The output table
% for this function includes the total parasite drag coefficient (CDo), and
% a breakdown of the contribution to CDo for the fuselage (f), wing (w),
% horizontal stabilizers (h1, h2), vertical stablizers (v1,v2), misc base
% drag (misc), and leakage and proturbance drag (lp).  This function also
% outputs the total wetted area for the entire aircraft (Swet_total).
% Finally, the FF_Table consolidates the form factors (FF) which account
% for zero lift pressure drag for each component for evaluation.
% Note that no FF should be < 1.0.  All these calculation are done for each
% configruation in the Design Input spreadsheet.

%% Outputs:
%
% Parasite Data:
%   Table containing total parasite drag and a component breakdown of
%   contributions to that total (columns), for each input case (rows)
%
% FF_Table:
%   Table containing total form factor and a component breakdown of
%   contributions to that total (columns), for each input case (rows)

%% Preallocate variables of interest
CDo = zeros(Count, 1); % Total parasite drag coefficient
CDo_f = zeros(Count, 1); % Fusalage parasite drag coefficient contribution
CDo_w = zeros(Count, 1); % Wing parasite drag coefficient contribution
CDo_h1 = zeros(Count, 1); % Horizontal stabilizer 1 parasite drag coefficient contribution
CDo_h2 = zeros(Count, 1); % Horizontal stabilizer 2 parasite drag coefficient contribution
CDo_v1 = zeros(Count, 1); % Vertical stabilizer 1 parasite drag coefficient contribution
CDo_v2 = zeros(Count, 1); % Vertical stabilizer 2 parasite drag coefficient contribution
CDo_misc = zeros(Count, 1); % Misc. parasite drag coefficient contribution
CDo_lp = zeros(Count, 1); % Leakage and purturbance parasite drag coefficient contribution
Swet_tot = zeros(Count, 1); % Total wetted area [m^2]

FF_f = zeros(Count, 1); % Fusalage form factor
FF_w = zeros(Count, 1); % Wing form factor
FF_h1 = zeros(Count, 1); % Horizontal stabilizer 1 form factor
FF_h2 = zeros(Count, 1); % Horizontal stabilizer 2 form factor
FF_v1 = zeros(Count, 1); % Vertical stabilizer 1 form factor
FF_v2 = zeros(Count, 1); % Vertical stabilizer 2 form factor

%% Loop through different configurations
for n = 1:Count
    % /////////////////////////////////////////////////////////////////////////
    % MODIFY THIS SECTION
    % /////////////////////////////////////////////////////////////////////////

    %Convert Mach to True Velocity
    V_o(n) = Design_Input.M_o(n)*ATMOS.a(n); %Convert design mach to velocity in feet/s

    %% Fuselage Contribution To CDo
    k_surface = 3.33*10^-5; %paint on aluminum (ft)
    Re_f_L = Design_Input.Length_f(n)*V_o(n)/ATMOS.nu(n); %Re for fuselage
    Re_f_cutoff = 38.21*(Design_Input.Length_f(n)/k_surface)^1.053; %Re model using surface roughness
    Re_f = [Re_f_L;Re_f_cutoff];
    Cf_f = 0.455/((log10(min(Re_f)))^2.58); %Leaving off mach correction
    FF_f(n) = 0.9+5/(Design_Input.Fine_f(n)^1.5)+Design_Input.Fine_f(n)/400; %Fuselage Form Factor
    CDo_f(n) = (Cf_f*FF_f(n)*Design_Input.Q_f(n)*Design_Input.Swet_f(n))/Design_Input.Sref_w(n); %Contribution of Fuselage to CDo

    %% Wing Contribution to CDo
    Re_w = V_o(n)*WingGeo_Data.MAC_w(n)/ATMOS.nu(n); %Wing Re
    Cf_w = 0.074/(Re_w^0.2); %Wing Flat Plate Coef of Friction for Turbulent Flow
    FF_w(n) = (1+(0.6/Airfoil.X_thick_w(n))*Airfoil.Thick_w(n)+100*(Airfoil.Thick_w(n)^4))*(1.35*(V_o(n)/ATMOS.a(n))^0.18*cosd(Design_Input.Sweep_w(n))^0.28); %Wing Form Factor

    if FF_w(n) < 1
        FF_w(n) = 1.1; %Do not allow Form Factor values < 1
    end
    CDo_w(n) = (Cf_w*FF_w(n)*Design_Input.Q_w(n)*Design_Input.Swet_w(n))/Design_Input.Sref_w(n); %Contribution of Wing to CDo

    %% Horizontal Tail #1 Contribution to CDo
    if Design_Input.Swet_h1(n)~=0 % If this component exists:
        Re_h1 = V_o(n)*Design_Input.MAC_h1(n)/ATMOS.nu(n); %Horz Tail Re
        Cf_h1 = 0.074/(Re_h1^0.2); %Flat Plate Coef of Friction for Turbulent Flow
        FF_h1(n) = (1+(0.6/Airfoil.X_thick_h1(n))*Airfoil.Thick_h1(n)+100*(Airfoil.Thick_h1(n)^4))*(1.35*(V_o(n)/ATMOS.a(n))^0.18*cosd(Design_Input.Sweep_h1(n))^0.28); %Horz Tail Form Factor
        if isnan(FF_h1(n))
            error("A horizontal tail was defined, but the airfoil thickness is zero! Define the airfoil in your excel sheet.")
        end
        
        if FF_h1(n) < 1
            FF_h1(n) = 1.1; %Do not allow Form Factor values < 1
        end
        CDo_h1(n) = (Cf_h1*FF_h1(n)*Design_Input.Q_h1(n)*Design_Input.Swet_h1(n))/Design_Input.Sref_w(n); %Contribution of Horz Tail 1 to CDo
    end
    %% Horizontal Tail #2 Contribution to CDo
    if Design_Input.Swet_h2(n)~=0 % If this component exists:
        Re_h2 = V_o(n)*Design_Input.MAC_h2(n)/ATMOS.nu(n); %Horz Tail Re
        Cf_h2 = 0.074/(Re_h2^0.2); %Flat Plate Coef of Friction for Turbulent Flow
        FF_h2(n) = (1+(0.6/Airfoil.X_thick_h2(n))*Airfoil.Thick_h2(n)+100*(Airfoil.Thick_h2(n)^4))*(1.35*(V_o(n)/ATMOS.a(n))^0.18*cosd(Design_Input.Sweep_h2(n))^0.28); %Horz Tail Form Factor
        if isnan(FF_h2(n))
            error("A second horizontal tail was defined, but the airfoil thickness is zero! Define the airfoil in your excel sheet.")
        end
        if FF_h2(n) < 1
            FF_h2(n) = 1.1; %Do not allow Form Factor values < 1
        end
        CDo_h2(n) = (Cf_h2*FF_h2(n)*Design_Input.Q_h2(n)*Design_Input.Swet_h2(n))/Design_Input.Sref_w(n); %Contribution of Horz Tail 2 to CDo
    end

    %% Vertical Tail #1 Contribution to CDo
    if Design_Input.Swet_v1(n)~=0 % If this component exists:
        Re_v1 = V_o(n)*Design_Input.MAC_v1(n)/ATMOS.nu(n); %Horz Tail Re
        Cf_v1 = 0.074/(Re_v1^0.2); %Flat Plate Coef of Friction for Turbulent Flow
        FF_v1(n) = (1+(0.6/Airfoil.X_thick_v1(n))*Airfoil.Thick_v1(n)+100*(Airfoil.Thick_v1(n)^4))*(1.35*(V_o(n)/ATMOS.a(n))^0.18*cosd(Design_Input.Sweep_v1(n))^0.28); %Horz Tail Form Factor
        
        if isnan(FF_v1(n))
            error("A vertical tail was defined, but the airfoil thickness is zero! Define the airfoil in your excel sheet.")
        end
        if FF_v1(n) < 1
            FF_v1(n) = 1.1; %Do not allow Form Factor values < 1
        end        
        CDo_v1(n) = (Cf_v1*FF_v1(n)*Design_Input.Q_v1(n)*Design_Input.Swet_v1(n))/Design_Input.Sref_w(n); %Contribution of Vert Tail 1 to CDo
    end
    %% Vertical Tail #2 Contribution to CDo
    if Design_Input.Swet_v2(n)~=0 % If this component exists:
        Re_v2 = V_o(n)*Design_Input.MAC_v2(n)/ATMOS.nu(n); %Horz Tail Re
        Cf_v2 = 0.074/(Re_v2^0.2); %Flat Plate Coef of Friction for Turbulent Flow
        FF_v2(n) = (1+(0.6/Airfoil.X_thick_v2(n))*Airfoil.Thick_v2(n)+100*(Airfoil.Thick_v2(n)^4))*(1.35*(V_o(n)/ATMOS.a(n))^0.18*cosd(Design_Input.Sweep_v2(n))^0.28); %Horz Tail Form Factor
        if isnan(FF_v2(n))
            error("A second vertical tail was defined, but the airfoil thickness is zero! Define the airfoil in your excel sheet.")
        end
        if FF_v2(n) < 1
            FF_v2(n) = 1.1; %Do not allow Form Factor values < 1
        end

        CDo_v2(n) = (Cf_v2*FF_v2(n)*Design_Input.Q_v2(n)*Design_Input.Swet_v2(n))/Design_Input.Sref_w(n); %Contribution of Vert Tail 2 to CDo
    end
    %% Misc. and L&P Contributions to CDo
    if Design_Input.Abase_f(n)~=0 % If this component exists:
        D_q_base = (0.139+0.419*((V_o(n)/ATMOS.a(n))-0.161)^2)*Design_Input.Abase_f(n);
        CDo_misc(n) = D_q_base/Design_Input.Sref_w(n); %Contribution of base drag to CDo
    end

    %% Leakage and Proturbance Contribution to CDo
    CDo_lp(n) = 0.1*(CDo_f(n)+CDo_w(n)+CDo_h1(n)+CDo_h2(n)+CDo_v1(n)+CDo_v2(n)); %Increase in parasite drag due to leakage and protuberance usually 3-15% of total CDo, but here just taking fuselage contribution

    %%Total Parasite Drag and Wetted Area
    Swet_tot(n) = Design_Input.Swet_f(n)+Design_Input.Swet_w(n)+Design_Input.Swet_h1(n)+Design_Input.Swet_h2(n)+Design_Input.Swet_v1(n)+Design_Input.Swet_v2(n); %Total Wetted Area
    CDo(n) = CDo_f(n)+CDo_w(n)+CDo_h1(n)+CDo_h2(n)+CDo_v1(n)+CDo_v2(n)+CDo_misc(n)+CDo_lp(n); %Total Parasite Drag Coefficient
    % /////////////////////////////////////////////////////////////////////////
    % END OF SECTION TO MODIFY
    % /////////////////////////////////////////////////////////////////////////



end

%% Oraganize into tables for output
Parasite_Data = table(CDo, CDo_f, CDo_w, CDo_h1, CDo_h2, CDo_v1, CDo_v2, CDo_misc, CDo_lp, Swet_tot);
FF_Table = table(FF_f, FF_w, FF_h1, FF_h2, FF_v1, FF_v2);

%% Plots for this function (Fig 300 - 399)
if Plot_Parasite_Data == 1
    
    % Parasite Drag Component Breakdown Pie Charts
    for n = 1:Count
        figure(299+n)
        labels = {'CDo_f','CDo_w','CDo_{h1}','CDo_{h2}','CDo_{v1}','CDo_{v2}','CDo_{misc}','CDo_{lp}'};
        color = colororder("gem12");
        selectedColumns = Parasite_Data{:, {'CDo_f','CDo_w','CDo_h1','CDo_h2','CDo_v1','CDo_v2','CDo_misc','CDo_lp'}};
        piechart(10000*selectedColumns(n,:),labels,ColorOrder=color); %Puts values in terms of drag counts where 1 drag count = (10^4)*CDo_value
        title(sprintf('Contribution to Total Parasite Drag (In Drag Counts): Configuraton %d', n));
    end
    
    % Reset default color order
    set(0,'DefaultAxesColorOrder','default')
end

end

