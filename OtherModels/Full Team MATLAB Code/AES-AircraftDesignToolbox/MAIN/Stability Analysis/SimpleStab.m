classdef SimpleStab < matlab.apps.AppBase
    
    % 1. DATA STORAGE
    properties (Access = public)
        UIFigure
        GridLayout
        
        % Left Panel Controls
        UnitDrop      
        ModeDrop
        LoadButton
        CalcButton
        
        VelLabel      
        VelInput
        AltLabel      
        AltInput
        ThetaInput
        
        PerturbDrop
        MagLabel      
        MagInput
        TimeInput
        StatsLabel
        
        % Right Panel Visualization
        PlotLayout
        Ax_1
        Ax_2
        Ax_3
        Ax_4
        
        % Data
        AcData        
        FullSys      
    end
    
    % 2. APP LOGIC
    methods (Access = private)
        
        % --- Helper: Update Labels based on Mode and Units ---
        function UpdateLabels(app)
            mode = app.ModeDrop.Value;
            unitSys = app.UnitDrop.Value;
            
            % Set unit strings based on selection
            if strcmp(unitSys, 'SI (m, kg, s)')
                velStr = 'm/s';
                altStr = 'm';
            else
                velStr = 'ft/s';
                altStr = 'ft';
            end
            
            % Update Input Labels 
            app.VelLabel.Text = sprintf('Velocity (%s):', velStr); 
            app.AltLabel.Text = sprintf('Altitude (%s):', altStr);  
            app.MagLabel.Text = sprintf('Mag (%s, deg):', velStr);  
            
            if strcmp(mode, 'Longitudinal Dynamics')
                % Update Perturb Dropdown
                app.PerturbDrop.Items = {
                    'Perturb Forward Velocity (u)', ...
                    'Perturb Vertical Velocity (w)', ...
                    'Perturb Pitch Rate (q)', ...
                    'Perturb Pitch Angle (theta)'};
                
                % Update Plot Titles & Labels
                title(app.Ax_1, 'Velocity u'); ylabel(app.Ax_1, velStr);
                title(app.Ax_2, 'Vertical Vel w'); ylabel(app.Ax_2, velStr);
                title(app.Ax_3, 'Pitch Rate q'); ylabel(app.Ax_3, 'deg/s');
                title(app.Ax_4, 'Pitch Angle \theta'); ylabel(app.Ax_4, 'deg');
            else % Lateral Dynamics
                % Update Perturb Dropdown
                app.PerturbDrop.Items = {
                    'Perturb Y Velocity (v)', ...
                    'Perturb Roll Rate (p)', ...
                    'Perturb Yaw Rate (r)', ...
                    'Perturb Bank Angle (phi)'};
                
                % Update Plot Titles & Labels
                title(app.Ax_1, 'Sideslip Velocity v'); ylabel(app.Ax_1, velStr);
                title(app.Ax_2, 'Roll Rate p'); ylabel(app.Ax_2, 'deg/s');
                title(app.Ax_3, 'Yaw Rate r'); ylabel(app.Ax_3, 'deg/s');
                title(app.Ax_4, 'Bank Angle \phi'); ylabel(app.Ax_4, 'deg');
            end
            
            % Clear existing plots when layout changes
            cla(app.Ax_1); cla(app.Ax_2); cla(app.Ax_3); cla(app.Ax_4);
            app.StatsLabel.Value = {'Run Calculate to update.'};
        end
        
        % --- Mode or Unit Dropdown Changed ---
        function UIChanged(app, ~)
            app.UpdateLabels();
        end
        
        % --- Button 1: Load Data ---
        function LoadButtonPushed(app, ~)
            try
                [file, path] = uigetfile({'*.xlsx';'*.mat';'*.csv'}, 'Select Data File');
                if isequal(file, 0); return; end
                fullPath = fullfile(path, file);
                app.AcData=readParams(fullPath,file);
                app.LoadButton.Text = 'Data Loaded! (Success)';
                app.LoadButton.BackgroundColor = [0.6 1 0.6];
            catch ME
                uialert(app.UIFigure, ME.message, 'Loading Error');
            end
        end
        
        % --- Button 2: Calculate & Plot ---
        function CalcButtonPushed(app, ~)
            try
                if isempty(app.AcData)
                    error('Please load aircraft data first.');
                end
                
                % 1. Determine Unit System Flag
                isImperial = strcmp(app.UnitDrop.Value, 'Imperial (ft, lbm, s)');
                
                % 2. Get Inputs
                fc.V0 = app.VelInput.Value;
                fc.theta0 = deg2rad(app.ThetaInput.Value);
                h = app.AltInput.Value;
                
                if isImperial
                    h_m = h * 0.3048; % atmosisa strictly requires meters
                    [~, ~, ~, rho_kgm3] = atmosisa(h_m);
                    fc.rho = rho_kgm3 / 515.3788; % Convert kg/m^3 to slugs/ft^3
                else
                    [~, ~, ~, fc.rho] = atmosisa(h);
                end
                
                mode = app.ModeDrop.Value;
                
                if strcmp(mode, 'Longitudinal Dynamics')
                    [sys,eigenvals] = calcLongitudinalDynamics(app.AcData, fc, isImperial);
                    app.FullSys = sys;
                    
                    complex_eigs = eigenvals(imag(eigenvals) ~= 0);
                    if ~isempty(complex_eigs)
                        [wn, zeta, p] = damp(sys);
                        [wn_sorted, idx] = sort(wn, 'descend');
                        zeta_sorted = zeta(idx);
                        p_sorted = p(idx);
                        
                        sp_wn = wn_sorted(1);   sp_z  = zeta_sorted(1);   sp_eig = p_sorted(1);
                        ph_wn = wn_sorted(end); ph_z  = zeta_sorted(end); ph_eig = p_sorted(end);
                        
                        statsText = sprintf([...
                            'SHORT PERIOD:\n Root: %.4f +/- %.4fi\n w_n: %.3f rad/s\n zeta: %.3f\n\n' ...
                            'PHUGOID:\n Root: %.4f +/- %.4fi\n w_n: %.3f rad/s\n zeta: %.3f'], ...
                            real(sp_eig), abs(imag(sp_eig)), sp_wn, sp_z, ...
                            real(ph_eig), abs(imag(ph_eig)), ph_wn, ph_z);
                        app.StatsLabel.Value = statsText;
                    else
                        app.StatsLabel.Value = 'System is Overdamped.';
                    end
                    
                else % Lateral Dynamics
                    [sys,~] = calcLateralDynamics(app.AcData, fc, isImperial);
                    app.FullSys = sys;
                    
                    [wn, zeta, p] = damp(sys);
                    
                    % Find Dutch Roll (Complex pair)
                    complex_idx = find(imag(p) ~= 0);
                    if ~isempty(complex_idx)
                        dr_eig = p(complex_idx(1));
                        dr_wn = wn(complex_idx(1));
                        dr_z = zeta(complex_idx(1));
                        dr_str = sprintf('DUTCH ROLL:\n Root: %.4f +/- %.4fi\n w_n: %.3f rad/s, z: %.3f\n', ...
                            real(dr_eig), abs(imag(dr_eig)), dr_wn, dr_z);
                    else
                        dr_str = sprintf('DUTCH ROLL:\n Overdamped\n');
                    end
                    
                    % Find Roll and Spiral (Real roots)
                    real_idx = find(imag(p) == 0);
                    if length(real_idx) >= 2
                        real_roots = p(real_idx);
                        [~, sort_idx] = sort(real_roots, 'ascend'); 
                        roll_eig = real_roots(sort_idx(1)); 
                        spiral_eig = real_roots(sort_idx(end)); 
                        
                        t_roll = -1/roll_eig;
                        t_spiral = -1/spiral_eig;
                        rs_str = sprintf('\nROLL MODE:\n Root: %.4f\n Tau: %.2f sec\n', roll_eig, t_roll);
                        sp_str = sprintf('\nSPIRAL MODE:\n Root: %.4f\n Tau: %.2f sec', spiral_eig, t_spiral);
                    else
                        rs_str = sprintf('\nROLL/SPIRAL: Combined\n');
                        sp_str = '';
                    end
                    app.StatsLabel.Value = [dr_str, rs_str, sp_str];
                end
                
                % 5. Run Perturbation Simulation
                app.RunSimulation();
                
            catch ME
                uialert(app.UIFigure, ME.message, 'Calculation Error');
            end
        end
        
        % --- Simulation Helper ---
        function RunSimulation(app, varargin) 
            if isempty(app.FullSys); return; end
            
            tMax = app.TimeInput.Value;
            if tMax <= 0, tMax = 10; end
            t = 0:0.1:tMax;
            mag = app.MagInput.Value;
            perturbType = app.PerturbDrop.Value;
            
            % Get correct unit string for titles
            if strcmp(app.UnitDrop.Value, 'SI (m, kg, s)')
                velStr = 'm/s';
            else
                velStr = 'ft/s';
            end
            
            isLong = contains(perturbType, {'(u)', '(w)', '(q)', '(theta)'});
            
            if isLong
                % Longitudinal: [u, w, q, theta]
                switch perturbType
                    case 'Perturb Forward Velocity (u)'
                        x0 = [mag; 0; 0; 0];
                        titleSuffix = sprintf(' (u0 = %.1f %s)', mag, velStr);
                    case 'Perturb Vertical Velocity (w)'
                        x0 = [0; mag; 0; 0];
                        titleSuffix = sprintf(' (w0 = %.1f %s)', mag, velStr);
                    case 'Perturb Pitch Rate (q)'
                        x0 = [0; 0; deg2rad(mag); 0];
                        titleSuffix = sprintf(' (q0 = %.1f deg/s)', mag);
                    case 'Perturb Pitch Angle (theta)'
                        x0 = [0; 0; 0; deg2rad(mag)];
                        titleSuffix = sprintf(' (theta0 = %.1f deg)', mag);
                end
                y = initial(app.FullSys, x0, t);
                
                plot(app.Ax_1, t, y(:,1), 'LineWidth', 2, 'Color', '#0072BD'); title(app.Ax_1, ['Foward Velocity u' titleSuffix]); grid(app.Ax_1, 'on');
                plot(app.Ax_2, t, y(:,2), 'LineWidth', 2, 'Color', '#D95319'); title(app.Ax_2, 'Vertical Velocity w'); grid(app.Ax_2, 'on');
                plot(app.Ax_3, t, y(:,3)*180/pi, 'LineWidth', 2, 'Color', '#EDB120'); title(app.Ax_3, 'Pitch Rate q'); grid(app.Ax_3, 'on');
                plot(app.Ax_4, t, y(:,4)*180/pi, 'LineWidth', 2, 'Color', '#7E2F8E'); title(app.Ax_4, 'Pitch Angle \theta'); grid(app.Ax_4, 'on');
            else
                % Lateral: [v, p, r, phi]
                switch perturbType
                    case 'Perturb Y Velocity (v)'
                        x0 = [mag; 0; 0; 0];
                        titleSuffix = sprintf(' (v0 = %.1f %s)', mag, velStr);
                    case 'Perturb Roll Rate (p)'
                        x0 = [0; deg2rad(mag); 0; 0];
                        titleSuffix = sprintf(' (p0 = %.1f deg/s)', mag);
                    case 'Perturb Yaw Rate (r)'
                        x0 = [0; 0; deg2rad(mag); 0];
                        titleSuffix = sprintf(' (r0 = %.1f deg/s)', mag);
                    case 'Perturb Bank Angle (phi)'
                        x0 = [0; 0; 0; deg2rad(mag)];
                        titleSuffix = sprintf(' (phi0 = %.1f deg)', mag);
                end
                y = initial(app.FullSys, x0, t);
                
                plot(app.Ax_1, t, y(:,1), 'LineWidth', 2, 'Color', '#0072BD'); title(app.Ax_1, ['Y Velocity v' titleSuffix]); grid(app.Ax_1, 'on');
                plot(app.Ax_2, t, y(:,2)*180/pi, 'LineWidth', 2, 'Color', '#D95319'); title(app.Ax_2, 'Roll Rate p'); grid(app.Ax_2, 'on');
                plot(app.Ax_3, t, y(:,3)*180/pi, 'LineWidth', 2, 'Color', '#EDB120'); title(app.Ax_3, 'Yaw Rate r'); grid(app.Ax_3, 'on');
                plot(app.Ax_4, t, y(:,4)*180/pi, 'LineWidth', 2, 'Color', '#7E2F8E'); title(app.Ax_4, 'Bank Angle \phi'); grid(app.Ax_4, 'on');
            end
        end
    end
    
    %UI layout
    methods (Access = public)
        function createComponents(app)
            % Main Window
            app.UIFigure = uifigure('Position', [100 100 1000 700]);
            app.UIFigure.Name = 'Flight Dynamics Analyzer';
            g = uigridlayout(app.UIFigure, [1, 2]);
            g.ColumnWidth = {250, '1x'};
            
            % --- LEFT PANEL ---
            leftPanel = uipanel(g);
            leftPanel.Title = 'Configuration';
            leftPanel.BackgroundColor = [0.95 0.95 0.95];
            
            % Units Selector
            uilabel(leftPanel, 'Position', [20 635 150 20], 'Text', 'Unit System:', 'FontWeight', 'bold');
            app.UnitDrop = uidropdown(leftPanel, 'Position', [20 615 210 22]);
            app.UnitDrop.Items = {'SI (m, kg, s)', 'Imperial (ft, lbm, s)'};
            app.UnitDrop.ValueChangedFcn = @(s,e) app.UIChanged(e);
            
            % Mode Selector
            uilabel(leftPanel, 'Position', [20 585 150 20], 'Text', 'Dynamics Mode:', 'FontWeight', 'bold');
            app.ModeDrop = uidropdown(leftPanel, 'Position', [20 565 210 22]);
            app.ModeDrop.Items = {'Longitudinal Dynamics', 'Lateral Dynamics'};
            app.ModeDrop.ValueChangedFcn = @(s,e) app.UIChanged(e);
            
            % Load Button
            app.LoadButton = uibutton(leftPanel, 'Position', [20 515 210 30], 'Text', '1. Load Excel Data');
            app.LoadButton.ButtonPushedFcn = @(s,e) app.LoadButtonPushed(e);
            
            app.VelLabel = uilabel(leftPanel, 'Position', [20 480 150 20], 'Text', 'Velocity (m/s):');
            app.VelInput = uieditfield(leftPanel, 'numeric', 'Position', [20 460 210 20], 'Value', 0);
            
            app.AltLabel = uilabel(leftPanel, 'Position', [20 430 150 20], 'Text', 'Altitude (m):');
            app.AltInput = uieditfield(leftPanel, 'numeric', 'Position', [20 410 210 20], 'Value', 0);
            
            uilabel(leftPanel, 'Position', [20 380 150 20], 'Text', 'Trim Theta (deg):');
            app.ThetaInput = uieditfield(leftPanel, 'numeric', 'Position', [20 360 210 20], 'Value', 0.0);
            
            % --- PERTURBATION SECTION ---
            uilabel(leftPanel, 'Position', [20 320 150 20], 'Text', 'Perturb Variable:', 'FontWeight', 'bold');
            app.PerturbDrop = uidropdown(leftPanel, 'Position', [20 300 210 22]);
            app.PerturbDrop.Items = {
                'Perturb Forward Velocity (u)', ...
                'Perturb Vertical Velocity (w)', ...
                'Perturb Pitch Rate (q)', ...
                'Perturb Pitch Angle (theta)'};
            app.PerturbDrop.ValueChangedFcn = @(s,e) app.RunSimulation(e);
            
            % Magnitude & Time
            app.MagLabel = uilabel(leftPanel, 'Position', [20 270 110 20], 'Text', 'Mag (m/s, deg):');
            app.MagInput = uieditfield(leftPanel, 'numeric', 'Position', [20 250 100 20], 'Value', 10);
            app.MagInput.ValueChangedFcn = @(s,e) app.RunSimulation(e);
            
            uilabel(leftPanel, 'Position', [140 270 90 20], 'Text', 'Sim Time (s):');
            app.TimeInput = uieditfield(leftPanel, 'numeric', 'Position', [140 250 90 20], 'Value', 120);
            app.TimeInput.ValueChangedFcn = @(s,e) app.RunSimulation(e);
            
            % Calc Button
            app.CalcButton = uibutton(leftPanel, 'Position', [20 190 210 40], 'Text', '2. CALCULATE', ...
                'BackgroundColor', [0 0.45 0.74], 'FontColor', 'white', 'FontWeight', 'bold');
            app.CalcButton.ButtonPushedFcn = @(s,e) app.CalcButtonPushed(e);
            
            % --- Stats Label ---
            app.StatsLabel = uitextarea(leftPanel);
            app.StatsLabel.Position = [20 20 210 150];
            app.StatsLabel.Editable = 'off';
            app.StatsLabel.FontSize = 11;
            app.StatsLabel.FontName = 'Monospaced';
            app.StatsLabel.Value = {'Load data...'; ''; 'Results will appear here.'};
            
            % --- RIGHT PANEL ---
            rightPanel = uipanel(g);
            rightPanel.Title = 'Dynamics Analysis';
            app.PlotLayout = tiledlayout(rightPanel, 2, 2);
            app.PlotLayout.Padding = 'compact';
            
            % Create generic Axes 
            app.Ax_1 = nexttile(app.PlotLayout);
            app.Ax_2 = nexttile(app.PlotLayout);
            app.Ax_3 = nexttile(app.PlotLayout);
            app.Ax_4 = nexttile(app.PlotLayout);
            
            % Force an initial label update
            app.UpdateLabels();
        end
        
        % CONSTRUCTOR
        function app = SimpleStab
            createComponents(app);
        end
        function delete(app)
            delete(app.UIFigure);
        end
    end
end