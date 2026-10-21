function [LD_sub,LD_super,msgs] =...
    LD(Design_Input,DragPolar_Subsonic,DragPolar_Supersonic_Max,WingLiftCurve,WingDragCurve,AoA_Count,Count,Plot_LD_Data,msgs)
%% Lift over Drag Analysis function Summary
% This function creates four arrays to compare the lift over drag (LD)
% estimations. Each row in the output tables represents a differnt configuration from the Design Input
% spreadsheet. Each column of the tables is for the discrete
% angles of attack evaluated (from the WingLiftDrag function).

%% Outputs:
%
% LD_sub:
%   Table containing L/D values for subsonic drag polar
%
% LD_super:
%   Table containing L/D values for supersonic drag polar

%% Preallocate variables of interest
% NOTE: These are being stored in a structure where the second level 
% variables are the different models. The arrays within this second level
% are the arrays discussed above
LD_sub = zeros(Count,AoA_Count);
LD_super = zeros(Count,AoA_Count);


%% Loop through different configurations
for n = 1:Count 
% /////////////////////////////////////////////////////////////////////////
% MODIFY THIS SECTION
% /////////////////////////////////////////////////////////////////////////
    LD_sub(n,:)=(WingLiftCurve{n,:})./DragPolar_Subsonic{n,:}; % brace indexing to make sure our values are in array form and not still a table as this will cause an error
    LD_super(n,:)=(WingLiftCurve{n,:})./DragPolar_Supersonic_Max{n,:};

% /////////////////////////////////////////////////////////////////////////
% END OF SECTION TO MODIFY
% /////////////////////////////////////////////////////////////////////////
end

%% Convert to tables for output
AoA_Names = {'-5', '-4', '-3', '-2', '-1', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12'};
LD_sub = array2table(LD_sub); % Convert to table
LD_sub.Properties.VariableNames = AoA_Names; % Name column headers for clarity using vector defined above
LD_super = array2table(LD_super); 
LD_super.Properties.VariableNames = AoA_Names;

%% Plots for this function (Fig 700 - 799)

if Plot_LD_Data == 1

    %Lift over Drag Analysis Plots
    for n=1:Count
        figure(699+n)
        hold on
        plot(WingLiftCurve{n,:},WingLiftCurve{n,:}./WingDragCurve{n,:},'--');
        plot(WingLiftCurve{n,:},LD_sub{n,:});
        plot(WingLiftCurve{n,:},LD_super{n,:});
        xlabel('Coefficient of Lift (CL) [ ]');
        ylabel('L/D Ratio [ ]');
        title('Lift over Drag Model Comparisons Config: ', Design_Input.Config(n));
        legend('3D Wing','L/D Subsonic','L/D Supersonic','Location','southeast');
        grid on
        hold off
    end
    
% Reset default color order
set(0,'DefaultAxesColorOrder','default')
end

end