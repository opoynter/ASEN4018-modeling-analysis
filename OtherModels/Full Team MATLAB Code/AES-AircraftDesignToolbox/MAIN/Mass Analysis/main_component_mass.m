%%this script calls necessary functions in ComponentWeightModel/ to
%%calculate component weights of the aircraft, and then with user input
%%will modify a .vsp3 to input the densities to enable cg and MOI
%%calculation.

%%instructions
%1. CREATE A COPY OF YOUR VSP FILE! We write to a new one, but make a copy
%incase somehow reading corrupts it.
%
%2.(IN VSP)Set interior components priority above the volume that incloses them.
%
%3.(IN VSP)Run Mass Prop Tool w/ sufficient number of slices. Densities
%don't matter, as these will be updated.
%
%4. Fill out the first page of weightSheet.xlsx, examples for 747 and C172
%are provided. The second page is a remnant before this was ported to
%MATLAB, but I left it for debugging purposes. It has no bearing on this
%code, and should only be used as a means of comparison.
%
%5. Call componentWeightModel with your xlsx sheet. Save the output weight
%struct.
%
%6.ENSURE YOU HAVE COPIED YOUR VSP3 FILE!
%
%7. Call updateVSPWeights.
%
%8. Fill out weight matrix. The columns are the categories from the
%component weight buildup code. The rows are your VSP parts.
%
%9. Open VSP. Ensure the mass properties outputs in VSP match the command
%line outputs.
%

clear
clc
addpath(genpath('component_mass'))
%% 747 test case
component_weight_filename="weightSheet_747.xlsx";
mass_props_filename="747200_MassProps.txt";
vsp3_filename="747200.vsp3";
myWeights = componentWeightModel(component_weight_filename);
updateVSPWeights(mass_props_filename, vsp3_filename, myWeights);


%% C172 test case
component_weight_filename="weightSheet_C172.xlsx";
mass_props_filename="CESSNA_172_MassProps.txt";
vsp3_filename="CESSNA_172.vsp3";
myWeights = componentWeightModel(component_weight_filename);
updateVSPWeights(mass_props_filename, vsp3_filename, myWeights);

%% T38 test case
component_weight_filename="weightSheet_T38.xlsx";
mass_props_filename="T38_base_MassProps.txt";
myWeights = componentWeightModel(component_weight_filename);
%Haven't created a detailed enough model to update the T38 densities