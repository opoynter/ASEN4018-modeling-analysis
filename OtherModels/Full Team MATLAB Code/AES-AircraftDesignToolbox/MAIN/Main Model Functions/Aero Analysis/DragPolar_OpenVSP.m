function [DragPolar_Model,msgs] = DragPolar_OpenVSP(Design_Input,WaveDrag_Data,parasite_file_name,aero_analysis_name,wave_peakWave_file_name,parasite_peakWave_file_name,wave_designMach_file_name,parasite_maxDesign_file_name,numConfigs,msgs)
%% Open VSP Aerodynamic Analysis
% ASEN 4138
% Author: Maggie Wussow
% last edited: 11/22/24

% Description: This function takes in all the open VSP files
% and outputs the full drag model. It will run for both supersonic and
% subsonic profiles. 

% Inputs:
%   Structs with aircraft parameters in them: Design_Input, WaveDrag_Data 
%   Cell arrays full of the file names of all the OpenVSP analysis files:
%       parasite_file_name,aero_analysis_name,wave_peakWave_file_name,
%       parasite_peakWave_file_name,wave_designMach_file_name,
%       parasite_maxDesign_file_name,
%   Number of versions run in the trade study: numConfigs

% Outputs: DragPolar_Model a table with columns of 
%   CDo_sub,k1_sub,k2_sub,CDo_peak_wave,k1_peak_wave,k2_peak_wave,CDo_max_mach,k1_max_mach,k2_max_mach
%   this is the same format as the drag polar table the matlab aero model.


%% Instructions
% Make sure the file names are correcly input into the file, the files for
% the same run should be in the same index for every single file name and
% parameter. 
% Instructions to get all these files in the correct format are in canvas
% and will be covered in lab 

%Initialization/Housekeeping
clc; close all; 

% removes warnings for table variable names for a cleaner output
warning('OFF', 'MATLAB:table:ModifiedAndSavedVarnames')

% loop through all the different configurations since it runs all the openvsp files at once 
for j = 1:numConfigs 

%% subsonic (both sub and super sonic) 
    %%% SUBSOINC PARASITE DRAG
    % take the parasite files from the .csv file into a cell array (allows
    % for numbers and characeters
    X = readcell(parasite_file_name{j}, 'Delimiter' , ',');
    
    %%% Determine the correct index 
    % set the row indexes we will want to pull 
    ind_pull = [1:7 9:length(X(:,12))];
    % in column 12 (cd column) find which of those rows are "missing"
    missing = cell2mat(cellfun(@ismissing,X(ind_pull,12),'UniformOutput',false));
    % find the last index which is "missing" 
    missing_last_index = find(missing == 1, 1, 'last');
    
    % convert the cell 4 below that last "missing" row in column 12 to
    % a matrix: this is cd_parasite_total 
    Cd0_parasite = cell2mat(X(missing_last_index+4,12));
    % save this variable into a matrix 
    CDo_Sub(j,1) = Cd0_parasite;

    %%% AERO ANALYSIS: K1 AND K2 
    % read the aero analysis .xslx file into a table 
    aero_analysis = readtable(aero_analysis_name{j});
    
    % pull out all the Cl and Cdi columns
    Cdi = aero_analysis.CDi;
    % different versions of OpenVSP have different CL column names, if
    % CLtot exists, use that, otherwise use CL
    if ismember('CLtot',aero_analysis.Properties.VariableNames)
        CL = aero_analysis.CLtot;
    elseif ismember('CL',aero_analysis.Properties.VariableNames)
        CL = aero_analysis.CL;
    else
        error('CL .polar data not found')
    end
    
    % poly fit a first order fit to get k1 and k2
    p = polyfit(CL,Cdi,2);
    % save both k1 and k2 into arrays
    k1_sub(j,1) = p(1);
    k2_sub(j,1) = p(2);

%% Supersonic -- need both analysis from M_peak_wave_drag (1.2) and Design_Input.M_max
if Design_Input.M_max(j) > WaveDrag_Data.M_DD(j) && Design_Input.M_max(j) < 1
    msgs.warnings{end+1} = 'Maximum mach is in the transonic region (M_DD<M_max<1), expect higher drag values. Using Raymer model for transonic drag penalty.';
    warning(msgs.warnings{end,:})
end

if Design_Input.M_max(j)<1 % if subsonic
    CDo_Super_Wave_Peak(j,1) = 4*CDo_Sub(j,1); %set these to estimated value, important for transonic aircraft
    CDo_Super_M_max(j,1) = 0;
    k1_super_M_max(j,1) = 0;
    k1_super_w_max(j,1) = k1_sub(j,1);
   
else % if supersonic
   %%% MAX DESIGN MACH (M_MAX) 
        %%% Parasite Drag same process as subsonic 
        X = readcell(parasite_maxDesign_file_name{j}, 'Delimiter' , ',');
        
        % determine the correct index 
        ind_pull = [1:7 9:length(X(:,12))];
        missing = cell2mat(cellfun(@ismissing,X(ind_pull,12),'UniformOutput',false));
        missing_last_index = find(missing == 1, 1, 'last');
        
        Cd0_maxDesign_parasite = cell2mat(X(missing_last_index+4,12));
    
        %%% Wave Drag 
        %read the .txt wave drag file 
        wave_designMach = readlines(wave_designMach_file_name{j});
        % check which lines have the characters "CDWave" and pull out the
        % numbers following -- should only be one per file 
        for di =1:numel(wave_designMach)
            line_str =  extractAfter(wave_designMach(di),'CDWave:');  
            % if it finds that string then pull out the characters after
            % and convert them to numbers 
            if ~ismissing(line_str) 
                Cd0_maxDesign_wave =  str2num(strtrim(line_str)); 
            end
        end
        % calculate the max design CD0 by adding wave and parasite cd0
        CDo_Super_M_max(j,1) = Cd0_maxDesign_wave + Cd0_maxDesign_parasite;
    
        %Calculate induced drag k1 value for max design max mach 
        k1_super_M_max(j,1) = (Design_Input.AR_w(j)*(Design_Input.M_max(j)^2-1))/(4*Design_Input.AR_w(j)*sqrt(Design_Input.M_max(j)^2-1)-2)*cosd(Design_Input.Sweep_w(j));

   %%% PEAK WAVE DRAG MACH (based on aircraft geometry) 
        M_wave_max = 1/(cosd(Design_Input.Sweep_w(j))^0.2); %Estimation of mach for max wave drag rise (Brandt). Value ~1.05 typically.

        %%% Parasite Drag for Peak Wave Drag Mach -- same process as subsonic
        X = readcell(parasite_peakWave_file_name{j}, 'Delimiter' , ',');
        
        % determine the correct index 
        ind_pull = [1:7 9:length(X(:,12))];
        missing = cell2mat(cellfun(@ismissing,X(ind_pull,12),'UniformOutput',false));
        missing_last_index = find(missing == 1, 1, 'last');
        
        % pull out the cd0 parasite value
        Cd0_peakWave_parasite = cell2mat(X(missing_last_index+4,12));

        %%% Wave Drag for Peak Wave Drag Mach -- same as with Max Design Mach
        wave_peakWave = readlines(wave_peakWave_file_name{j});
        
        for ci =1:numel(wave_peakWave)
        line_str =  extractAfter(wave_peakWave(ci),'CDWave:');  
            if ~ismissing(line_str)
                Cd0_peakWave_wave =  str2num(strtrim(line_str)); 
            end
        end

        CDo_Super_Wave_Peak(j,1) = Cd0_peakWave_wave + Cd0_peakWave_parasite;

        % Calculate induced drag k1 value for mach at peak wave drag (M_wave_max)
        k1_super_model = (Design_Input.AR_w(j)*(M_wave_max^2-1))/(4*Design_Input.AR_w(j)*sqrt(M_wave_max^2-1)-2)*cosd(Design_Input.Sweep_w(j));
        % Average between max mach k1 and subsonic k1 values 
        k1_super_avg = (k1_super_M_max(j,1)+k1_sub(j,1))/2; 
        % Takes whichever k1 is larger, k1 from the Max wave mach or from
        % the average between supersonic and subsonic 
        k1_super_w_max(j,1) = max(k1_super_model,k1_super_avg);
    end
end
% Put all the drag polar components into the table -- this is what will be
% output into the command line 
DragPolar_Model = table(CDo_Sub,k1_sub,k2_sub,CDo_Super_Wave_Peak,k1_super_w_max,zeros(numConfigs,1),CDo_Super_M_max,k1_super_M_max,zeros(numConfigs,1));
DragPolar_Model.Properties.VariableNames = {'CDo_sub','k1_sub','k2_sub','CDo_peak_wave','k1_peak_wave','k2_peak_wave','CDo_max_mach','k1_max_mach','k2_max_mach'};

% Added in tables for easy display purposes 
fprintf("Table with Drag Model\n\n")
disp(DragPolar_Model)
end


