function [CD,CDo_msn,k1_msn,k2_msn,msgs] = DragPolar_Function(Mach_Input,CL_Input,Config_Row,DragPolar_Model,WaveDrag_Data,msgs)
    %DRAG COEFFICIENT CALCULATOR
    %   Based on the subsonic and supersonic modeling of an aircraft's drag
    %   polor, this function allows the calculation of an aircraft's drag
    %   coefficient for an inputted mach, coefficient of lift, and designating
    %   the specific aircraft configuration row in the design input file.Can
    %   only be used with one configuration at a time through mission analysis
    %   (so you must designate which row you are assessing in "Config_Row"
    %   input).

    %Establish vectors to enable linear interpolation of drag polar changes
    %with mach from subsonic to supersonic flight.  Script automatically pulls
    %these values from the outputs of the
    %ASEN4138_Aircaft_Design_Aero_Model_Main.m code; howver, once you progress
    %to more detailed design in OPEN VSP, you should manually input the drag
    %polar values required for the "D" and "K" matrices below from OPEN VSP.
    %Mach values in the "M" matrix can remain the same; however, ensure your
    %use these same Mach values for your OPEN VSP analysis to ensure they
    %correlate correctly.
    %KEY FOR MATRIX INPUTS IF MANUALLY INPUTTING VALUES FROM OPEN VSP
    % M = [0 M_DD M_peak_wave_drag M_max]
    % CDo = [CDo_subsoinic CDo_Subsonic CDo_peak_wave_drag CDo_max_mach]
    % K1 = [k1_subsonic k1_subsonic k1_peak_wave_drag k1_max_mach]
    % K2 = [k2_subsonic k2_subsonic 0 0]

    %Fixes a common error where this function outputs CD=NaN and causes less traceable problems elsewhere.
    if Mach_Input>WaveDrag_Data.M_max_design(Config_Row)%catches invalid Mach_Inputs. 
        error("Input Mach > maximum design Mach. Input Mach values to MSN_SEG functions cannot be greater than the user-specified maximum design Mach values.");
    end

    DragPolar_Model.Cdo_DD(Config_Row) = DragPolar_Model.CDo_sub(Config_Row)+0.008; %Raymer estimate of drag rise from M crit to M DD
    M =    [0                                   WaveDrag_Data.M_cr(Config_Row)      WaveDrag_Data.M_DD(Config_Row)];
    CDo =  [DragPolar_Model.CDo_sub(Config_Row) DragPolar_Model.CDo_sub(Config_Row) DragPolar_Model.Cdo_DD(Config_Row)];
    K1 =   [DragPolar_Model.k1_sub(Config_Row)  DragPolar_Model.k1_sub(Config_Row)  DragPolar_Model.k1_sub(Config_Row)];
    K2 =   [DragPolar_Model.k2_sub(Config_Row)  DragPolar_Model.k2_sub(Config_Row)  DragPolar_Model.k2_sub(Config_Row)];


    if WaveDrag_Data.M_wave_max(Config_Row) ~= 0 %if the max wave drag point is defined, add this data
        M =   [M   WaveDrag_Data.M_wave_max(Config_Row)];
        CDo = [CDo DragPolar_Model.CDo_peak_wave(Config_Row)];
        K1 =  [K1  DragPolar_Model.k1_peak_wave(Config_Row)];
        K2 =  [K2  0]; %No k2 value during supersonic flight
    end

    %only use max mach data if greater than peak wave drag mach and CDo max mach is
    %defined
    if WaveDrag_Data.M_max_design(Config_Row) > WaveDrag_Data.M_wave_max(Config_Row) && DragPolar_Model.CDo_max_mach(Config_Row) ~= 0 
        M =   [M   WaveDrag_Data.M_max_design(Config_Row)];
        CDo = [CDo DragPolar_Model.CDo_max_mach(Config_Row)];
        K1 =  [K1  DragPolar_Model.k1_max_mach(Config_Row)];
        K2 =  [K2  0]; %No k2 value during supersonic flight
    end
    CDo_msn = interp1(M,CDo,Mach_Input); %CDo interpolation based on mach for msn segment
    k1_msn = interp1(M,K1,Mach_Input); %k1 interpolation based on mach for msn segment
    k2_msn = interp1(M,K2,Mach_Input); %k2 interpolation based on mach for msn segment

    CD = CDo_msn+k1_msn*CL_Input^2+k2_msn*CL_Input; %CD interpolation based on mach for msn segment

    %Test Plot of CDo variaion with mach to confirm interpolation is correct.
    %Comment out this portion when not validating.
    % A = linspace(0.1,M(1,4));
    % ParasiteDragProfile = interp1(M,CDo,A);
    %
    % figure
    % plot(A,ParasiteDragProfile)
    % xlabel('Mach');
    % ylabel('CDo');
    % title('Parasite Drag Coefficient Variation with Mach');

end
