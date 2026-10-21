function weights = componentWeightModel(excelFileName, category)
    %Jonathan Morris 3/19/2026
    %Import Data from Excel "Designer Inputs"

    rawData = readcell(excelFileName, 'Sheet', 'Designer Inputs');
    inputs = struct();
    for i = 1:size(rawData, 1)
        varName = rawData{i, 2};
        rowName= rawData{i,1};
        val = rawData{i, 3};
        if ischar(varName) && ~isempty(varName) && isnumeric(val) && ~isnan(val) && ~ismissing(val)
            cleanName = matlab.lang.makeValidName(varName);
            inputs.(cleanName) = val;
        end
        if ischar(rowName) && strcmp(rowName, 'Fixed or Retractable?')
            inputs.LG_Type = rawData{i, 3};
        end
        if strcmp(varName,'Category') && ischar(val)
            inputs.Category=val;
        end

    end

    W_dg = inputs.W_dg;
    weights = struct();
    weights.Crew=inputs.W_crew;
    weights.Passenger=inputs.W_passenger;
    weights.Payload=inputs.W_payload;
    if inputs.N_en_jet ~=0
        weights.Engine=inputs.N_en_jet*inputs.W_en_jet;
    end

    %weight model from spreadsheet
    if strcmp(inputs.Category, 'Fighter')
        weights.Wing = 0.0103 * inputs.K_dw * inputs.K_vs * (inputs.W_dg * inputs.Nz)^0.5 * inputs.S_w^0.622 * inputs.AR_w^0.785 * inputs.t_c_root^-0.4 * (1 + inputs.Taper_w)^0.05 * (cosd(inputs.Sweep_w))^-1 * inputs.S_csw^0.04;
        weights.HorzTail = 3.316 * (1 + inputs.Fw / inputs.Bh)^-2 * (inputs.W_dg * inputs.Nz / 1000)^0.26 * inputs.S_ht^0.806;
        weights.VertTail = 0.452 * inputs.K_rht * (1 + inputs.Ht_Hv)^0.5 * (inputs.W_dg * inputs.Nz)^0.488 * inputs.S_vt^0.718 * inputs.M^0.341 * inputs.L_vt^-1 * (1 + inputs.Sr / inputs.S_vt)^0.348 * inputs.AR_vt^0.223 * (1 + inputs.Taper_vt)^0.25 * (cosd(inputs.Sweep_vt))^-0.323;
        weights.Fuselage = 0.499 * inputs.K_dwf * inputs.W_dg^0.35 * inputs.Nz^0.25 * inputs.L^0.5 * inputs.Diameter^0.849 * inputs.Width^0.685;
        weights.EngineMounts = 0.013 * inputs.N_en_jet^0.795 * inputs.Tmax_jet^0.579 * inputs.Nz;
        weights.AirInlet = 13.29 * inputs.K_vg * inputs.L_d^0.643 * inputs.K_d^0.182 * inputs.N_en_jet^1.498 * (inputs.L_s / inputs.L_d)^-0.373 * inputs.De;
        weights.Nacelles=0;
        weights.Fuel=inputs.Wf;
    elseif strcmp(inputs.Category, 'Bomber/Large Jet Transport')
        weights.Wing = 0.0051 * (inputs.W_dg * inputs.Nz)^0.557 * inputs.S_w^0.649 * inputs.AR_w^0.5 * inputs.t_c_root^-0.4 * (1 + inputs.Taper_w)^0.1 * (cosd(inputs.Sweep_w))^-1 * inputs.S_csw^0.1;
        weights.HorzTail = 0.0379 * inputs.K_uht * (1 + inputs.Fw / inputs.Bh)^-0.25 * inputs.W_dg^0.639 * inputs.Nz^0.1 * inputs.S_ht^0.75 * inputs.L_ht^-1 * inputs.Ky^0.704 * (cosd(inputs.Sweep_ht))^-1 * inputs.AR_ht^0.166 * (1 + inputs.Se / inputs.S_ht)^0.1;
        weights.VertTail = 0.0026 * (1 + inputs.Ht_Hv)^0.225 * inputs.W_dg^0.556 * inputs.Nz^0.536 * inputs.L_vt^-0.5 * inputs.S_vt^0.5 * inputs.Kz^0.875 * (cosd(inputs.Sweep_vt))^-1 * inputs.AR_vt^0.35 * inputs.t_c_root_vt^-0.5;
        weights.Fuselage = 0.328 * inputs.K_door * inputs.K_Lg * (inputs.W_dg * inputs.Nz)^0.5 * inputs.L^0.25 * inputs.Sf^0.302 * (1 + inputs.K_ws)^0.04 * inputs.L_D_fineness^0.1;
        weights.EngineMounts = 0;
        weights.AirInlet = 0;
        weights.Nacelles = 0.6724 * inputs.K_ng * inputs.N_Lt^0.1 * inputs.Nw^0.294 * ...
            inputs.Nz^0.119 * inputs.Wec^0.611 * inputs.Sn^0.224*inputs.N_en_jet;
        weights.Fuel=inputs.Wf;

    elseif strcmp(inputs.Category, 'General Aviation/Prop Transport')
        weights.Wing = 0.036 * inputs.S_w^0.758 * inputs.W_fw^0.0035 * (inputs.AR_w / (cosd(inputs.Sweep_w))^2)^0.6 * inputs.q^0.006 * inputs.t_c_root^0.04 * ((100 * inputs.t_c_root) / cosd(inputs.Sweep_w))^-0.3 * (inputs.Nz * inputs.W_dg)^0.49;
        weights.HorzTail = 0.016 * (inputs.Nz * inputs.W_dg)^0.414 * inputs.q^0.168 * inputs.S_ht^0.896 * (100 * inputs.t_c_root_ht / cosd(inputs.Sweep_ht))^-0.12 * (inputs.AR_ht / (cosd(inputs.Sweep_ht))^2)^0.043 * inputs.Taper_ht^-0.02;
        weights.VertTail = 0.073 * (1 + 0.2 * inputs.Ht_Hv) * (inputs.Nz * inputs.W_dg)^0.376 * inputs.q^0.122 * inputs.S_vt^0.873 * (100 * inputs.t_c_root_vt / cosd(inputs.Sweep_vt))^-0.49 * (inputs.AR_vt / (cosd(inputs.Sweep_vt))^2)^0.357 * inputs.Taper_vt^0.039;
        weights.Fuselage = 0.052 * inputs.Sf^1.086 * (inputs.Nz * inputs.W_dg)^0.177 * inputs.L_ht^-0.051 * inputs.L_D_fineness^-0.072 * inputs.q^0.241 + inputs.W_pressurize;
        weights.EngineMounts = 0;
        weights.AirInlet = 0;
        weights.Nacelles = 0;
        weights.Fuel=inputs.Wf;
        weights.EnginePropMount=inputs.N_en_prop*(2.575*inputs.W_en_prop^.922);

    else
        error("Invalid Aircraft Category Selection")
    end

    % Determine landing gear eqn factor based on category
    if strcmp(inputs.Category, 'Fighter')
        lg_factor = 0.033;
    elseif strcmp(inputs.Category, 'Bomber/Large Jet Transport')
        lg_factor = 0.043;
    elseif strcmp(inputs.Category, 'General Aviation/Prop Transport')
        lg_factor = 0.057;
    else
        lg_factor = 0; % Fallback
    end

    %  retractable vs fixed gear
    if strcmp(inputs.LG_Type, 'Retractable')
        weights.LandingGear = lg_factor * inputs.Wo;
    else
        weights.LandingGear = 0.86 * lg_factor * inputs.Wo;
    end

    if strcmp(inputs.Category, 'Fighter') || strcmp(inputs.Category, 'Bomber/Large Jet Transport')
        weights.OtherSubsystems = 0.17 * inputs.Wo;
    elseif strcmp(inputs.Category, 'General Aviation/Prop Transport')
        weights.OtherSubsystems = 0.1 * inputs.Wo;
    end

    disp(['--- Calculated Weights (lbs) for [', inputs.Category, '] ---']);
    compNames = fieldnames(weights);
    We = 0;%isnt really We since we have fuel weight now but whatever.
    for i = 1:length(compNames)
        comp = compNames{i};
        fprintf('%s: %g [lbs]\n', comp, weights.(comp));
        We = We + weights.(comp);
    end

    disp(['Refined Empty Weight Estimate:   ', num2str(We-weights.Fuel-weights.Crew-weights.Payload-weights.Passenger)])
    disp(['Refined W0 Estimate:   ', num2str(We)])

end