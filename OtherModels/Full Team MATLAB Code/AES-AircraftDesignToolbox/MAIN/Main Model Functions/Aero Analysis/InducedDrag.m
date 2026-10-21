function [InducedDrag_Data,msgs] =...
    InducedDrag(Design_Input,WingLiftModel,WingLiftCurve,WingDragCurve,WingGeo_Data,Count,Plot_Induced_Data,msgs)
%% Induced Drag Model Function Summary
% This function evaluates different Oswalds Efficiency Factor models for 
% use in your drag polar model. The Oswalds Efficiencty Factor, k1, and k2 values
% are outputted in the InducedDrag_Data table.  Note that
% depending on the Oswalds models chosen to evaluate, you may or may not
% need information from teh WingGeo_Data table from the WingGeo function.
% Additionally, this code supports the calculation of the k2 values for
% evaluating non-symmetric airfoil design, but is not required.

%% Outputs:
%
% InducedDrag_Data:
%   Table containing oswalds info and calculated k1 and k2 values for three
%   different models for oswalds (denoted by suffixes _mod1, _mod2, and
%   _mod3)(columns) for each input from the design input spreadsheet (rows)


%% Preallocate variables of interest
eo = zeros(Count, 1); % Oswald
k1_sub = zeros(Count, 1); % k1
k2_sub = zeros(Count, 1); % k2
CL_minD = zeros(Count,1); % Storing CL_minD value

% NOTE: k2 values not required if only symmetric airfoils used; however,
% this version of the code includes it as an option

%% Loop through different configurations
for n = 1:Count 
% /////////////////////////////////////////////////////////////////////////
% MODIFY THIS SECTION
% /////////////////////////////////////////////////////////////////////////
    %Find CL min Drag value of wing drag polar to estimate k2
    [CD_min,CD_min_index] = min(WingDragCurve{n,:});
    CL_minD(n) = WingLiftCurve{n,CD_min_index}; %Assumes CL for min D for wing only is same for whole aircraft

    %%Cavallo Oswalds Model (swept thin wing aircraft)
    eo(n) = 4.61*(1-0.045*Design_Input.AR_w(n)^0.68)*cosd(Design_Input.Sweep_w(n))^0.15-3.1;
    k1_sub(n) =  1/(pi*eo(n)*Design_Input.AR_w(n));
    k2_sub(n) = -2*k1_sub(n)*CL_minD(n);

    %Nita-Scholz Oswalds Model (Nita-Scholz Model)
    % k_ef = 1-2*(Design_Input.Dia_f(n)/WingGeo_Data.b_w(n))^2;%fuselage impacts
    % k_eDo = 0.873; %Statistical accounting for shifts in zero lift drag.Jet = 0.873,business jet=0.864,turboprop=0.804, gen aviation=0.804
    % k_eM = 1; %compressibility correction for mach; if M<0.3,=1
    % eo(n) = WingLiftModel.e(n)*k_ef*k_eDo*k_eM; %Oswalds Estimate
    % k1_sub(n) =  1/(pi*eo(n)*Design_Input.AR_w(n));
    % k2_sub(n) = -2*k1_sub(n)*CL_minD;


% /////////////////////////////////////////////////////////////////////////
% END OF SECTION TO MODIFY
% /////////////////////////////////////////////////////////////////////////   
end

%% Oraganize into table for output
InducedDrag_Data = table(eo, k1_sub,k2_sub,CL_minD);

 %Isolated Induced Drag Coefficients
    CDi_w = (WingLiftCurve{1,:}').^2/...
        (pi*WingLiftModel.e(1)*Design_Input.AR_w(1));
    CDi_sub = (WingLiftCurve{1,:}').^2.*InducedDrag_Data.k1_sub(n)...
        +InducedDrag_Data.k2_sub(1).*((WingLiftCurve{1,:}'));


%% Plots for this function (Fig 400 - 499)
if Plot_Induced_Data == 1
    
    % Subsonic CDi Plot
    for n=1:Count
        figure(399+n)
        hold on
        plot(WingLiftCurve{n,:},CDi_w,'--');
        plot(WingLiftCurve{n,:},CDi_sub);
        xlabel('Coefficient of Lift (CL) [ ]');
        ylabel('Induced Drag (CDi) [ ]');
        title(sprintf('Subsonic Induced Drag (CDi) Modeling Config: %d', n));
        legend('3D Wing','Aircraft CDi','Location','southeast');
        grid on
        hold off
    end
    
    % Reset default color order
    set(0,'DefaultAxesColorOrder','default')
end

if Plot_Induced_Data == 1

        figure
        hold on
        plot(WingLiftCurve{n,:},CDi_w,'--');
        plot(WingLiftCurve{n,:},CDi_sub);
        xlabel('Coefficient of Lift (CL) [ ]');
        ylabel('Induced Drag (CDi) [ ]');
        title('CDi Curves');
        legend('3D Wing','Aircraft (Nita-Scholz Model)','Location','southeast');
        grid on
        hold off


end

end


