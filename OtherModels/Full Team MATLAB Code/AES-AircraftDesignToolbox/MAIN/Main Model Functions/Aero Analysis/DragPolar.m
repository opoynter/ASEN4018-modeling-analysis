function [DragPolar_Subsonic,DragPolar_Supersonic_Max,DragPolar_Supersonic_Wave_Peak,DragPolar_Model,msgs] =...
    DragPolar(Parasite_Drag_Data,InducedDrag_Data,WaveDrag_Data,Design_Input,AoA_Count,WingLiftCurve,WingDragCurve,AirfoilLiftCurve,Airfoil,Count,Plot_DragPolar_Data,msgs)
%% Drag Polar Summary
% Creates an array for each drag polar model with total CD value.
% Columns are each configuration tested, rows are variation with angle of
% attack (-5 to 12 deg).
%
% Allows comparison of different configuration's drag polars (per model).
% Once a drag polar model is chosen, other models can be commented out if
% desired.

%% Outputs:
%
% DragPolar_mod1:
%   Table containing total drag data (parasite and induced) for
%   induced drag model , each table has columns of AoA and rows of
%   case inputs


%% Preallocate variables of interest
% NOTE: These are being stored in a structure where the second level
% variables are the different models. The arrays within this second level
% are the arrays discussed above


CDo_Sub = zeros(Count,1);
CDo_Super_Wave_Peak = zeros(Count,1);
CDo_Super_M_max = zeros(Count,1);
DragPolar_Subsonic = zeros(Count,AoA_Count); %Used for all Mach < M_cr
DragPolar_Supersonic_Max = zeros(Count,AoA_Count); %Evaluated at Max Mach value from Design Input File
DragPolar_Supersonic_Wave_Peak=zeros(Count,AoA_Count);



%% Loop through different configurations
for n = 1:Count
    CDo_Sub(n) = Parasite_Drag_Data.CDo(n);
    DragPolar_Subsonic(n,:)= CDo_Sub(n)+((WingLiftCurve{n,:}').^2).*InducedDrag_Data.k1_sub(n)+InducedDrag_Data.k2_sub(n).*((WingLiftCurve{n,:}'));
    CDo_Super_Wave_Peak(n) = (Parasite_Drag_Data.CDo(n)+WaveDrag_Data.CDw_max(n));
    CDo_Super_M_max(n) = (Parasite_Drag_Data.CDo(n)+WaveDrag_Data.CDw_M_max(n));
    DragPolar_Supersonic_Wave_Peak(n,:)= CDo_Super_Wave_Peak(n)+((WingLiftCurve{n,:}').^2).*WaveDrag_Data.k1_super_w_max(n)+WaveDrag_Data.k2_super_w_max(n).*((WingLiftCurve{n,:}'));
    DragPolar_Supersonic_Max(n,:)= CDo_Super_M_max(n)+((WingLiftCurve{n,:}').^2).*WaveDrag_Data.k1_super_M_max(n)+WaveDrag_Data.k2_super_M_max(n).*((WingLiftCurve{n,:}'));
end
%% Convert to tables for output
AoA_Names = {'-5', '-4', '-3', '-2', '-1', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'};
DragPolar_Subsonic = array2table(DragPolar_Subsonic); % Convert to table
DragPolar_Subsonic.Properties.VariableNames = AoA_Names; % Name column headers for clarity using vector defined above
DragPolar_Supersonic_Wave_Peak = array2table(DragPolar_Supersonic_Wave_Peak);
DragPolar_Supersonic_Wave_Peak.Properties.VariableNames = AoA_Names;
DragPolar_Supersonic_Max = array2table(DragPolar_Supersonic_Max);
DragPolar_Supersonic_Max.Properties.VariableNames = AoA_Names;

%Output Consolidated Drag Polar Model Table

DragPolar_Model = table(CDo_Sub,InducedDrag_Data.k1_sub,InducedDrag_Data.k2_sub,CDo_Super_Wave_Peak,WaveDrag_Data.k1_super_w_max,WaveDrag_Data.k2_super_w_max,CDo_Super_M_max,WaveDrag_Data.k1_super_M_max,WaveDrag_Data.k2_super_M_max);
DragPolar_Model.Properties.VariableNames = {'CDo_sub','k1_sub','k2_sub','CDo_peak_wave','k1_peak_wave','k2_peak_wave','CDo_max_mach','k1_max_mach','k2_max_mach'};
%% Plots for this function (Fig 500 - 599)
if Plot_DragPolar_Data == 1

    % Drag Polar Curves
    for n=1:Count
        figure(499+n)
        hold on
        plot(AirfoilLiftCurve{n,:},Airfoil{n,(24:41)}); %2D Airfoil Drag Polar
        plot(WingLiftCurve{n,:},WingDragCurve{n,:},'--'); %3D Wing Drag Polar
        plot(WingLiftCurve{n,:},DragPolar_Subsonic{n,:}); %Aircraft Subsonic Drag Polar
        if Design_Input.M_max(n)>0.8 %This conditional turns off wave drag plotting for M_design<0.8
            plot(WingLiftCurve{n,:},DragPolar_Supersonic_Wave_Peak{n,:}); %Transonic Drag Polar
            plot(WingLiftCurve{n,:},DragPolar_Supersonic_Max{n,:}); %Supersonic Drag Polar
            legend('Airfoil Drag Polar','Wing Drag Polar','Drag Polar Subsonic','Drag Polar Supersonic Wave Peak','Drag Polar Supersonic Max Mach','Location','northwest');
        else
            legend('Airfoil Drag Polar','Wing Drag Polar','Drag Polar Subsonic','Location','northwest');
        end
        xlabel('Coefficient of Lift (CL) [ ]');
        ylabel('Coefficient of Drag (CD) [ ]');
        title('Drag Polar vs Mach Comparison - Config: ', Design_Input.Config(n));
        grid on
        hold off
    end

    %Drag Polar comparisons for multiple configuration changes
    figure(520)
    hold on
    for n = 1:Count
        plot(WingLiftCurve{1,:},DragPolar_Subsonic{n,:}); % brace indexing for plotting tables
    end
    xlabel('Coefficient of Lift (CL)');
    ylabel('Coefficient of Drag (CD)');
    title('Subsonic Drag Polar Configuration Comparison');
    legend(Design_Input.Config(:),'Location','northwest');
    grid on
    hold off
end

end
