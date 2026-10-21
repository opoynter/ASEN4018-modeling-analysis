function [RangeFactor_Data,M_eval_range,Alt_eval_range,RF_W] = RangeFactor(Config_Row,FinalWeightData,Design_Input,Propulsion_Input,DragPolar_Model,WaveDrag_Data)
%Evaluates best cruise mach and altitude using range factor to help
%optimize mission profile parameters for best cruise range.

%   Required Inputs

M_eval_range = linspace(0.1,WaveDrag_Data.M_cr(Config_Row),20);
Alt_eval_range = linspace(5000,50000,10);
Cruise_Seg = strcmp(FinalWeightData.("Leg Type"),'Cruise');
RF_W = FinalWeightData.("Starting Weight [lb]")(Cruise_Seg);

for k = 1:length(RF_W)
    RangeFactor = zeros(length(Alt_eval_range), length(M_eval_range));
    for i = 1:length(Alt_eval_range)
        for j = 1:length(M_eval_range)
            Altitude(i) = Alt_eval_range(i);
            [rho,a,~,~,~,~] = atmos(Altitude(i),'units','US');
            Vel_eval = M_eval_range(j)*a;
            Weight(i) = str2num(RF_W(k));
            CL_eval = Weight(i) / (0.5 * rho * Vel_eval^2*Design_Input.Sref_w(Config_Row)); % Calculate lift coefficient
            CD_eval = DragPolar_Model.CDo_sub(Config_Row)+DragPolar_Model.k1_sub(Config_Row)*CL_eval^2+DragPolar_Model.k2_sub(Config_Row)*CL_eval;
            %Find TSFC for Cruise
            [~,~,~,~,~,TSFC_mil,~,~,~,SFC] =...
                Propulsion(Alt_eval_range(i),M_eval_range(j),Config_Row,Propulsion_Input);
            if strcmp(Propulsion_Input.PropType(Config_Row),'JET_LBP_Turbofan')||strcmp(Propulsion_Input.PropType(Config_Row),'JET_HBP_Turbofan')
                C = TSFC_mil;
            else
                C = SFC;
            end
            RangeFactor(i, j) = ((Vel_eval/C)*(CL_eval/CD_eval))/6076; % Calculate range factor in nautical miles
        end
    end
    RangeFactor_Data(k).RangeFactor = RangeFactor; % Store the calculated range factor for each weight
end

colors = [
    0.0000    0.4470    0.7410   % Blue
    0.8500    0.3250    0.0980   % Orange
    0.9290    0.6940    0.1250   % Yellow
    0.4940    0.1840    0.5560   % Purple
    0.4660    0.6740    0.1880   % Green
    0.3010    0.7450    0.9330   % Cyan
    0.6350    0.0780    0.1840   % Dark Red
    0.0000    0.6000    0.5000   % Teal
    0.7500    0.7500    0.0000   % Olive
    0.4000    0.4000    0.4000   % Gray
];

figure
for n = 1:length(RF_W)
    subplot(1,length(RF_W),n)
    hold on
    for i = 1:length(Alt_eval_range)
        plot(M_eval_range, RangeFactor_Data(n).RangeFactor(i,:),'Color',colors(i,:));
    end
    xline(WaveDrag_Data.M_cr(Config_Row),'--r','Critical Mach');
    title(sprintf('Cruise Segment %d Range Factor for W = %.2f lb', n, RF_W(n)));
    xlabel('Mach Number');
    ylabel('Range Factor [nm]');
    legend([string(Alt_eval_range),"M_{cr}"],'Location','northwest');
    grid on;
    hold off;
end

  