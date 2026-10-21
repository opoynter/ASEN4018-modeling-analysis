%% OpenVSP Mass and CG Analysis
clc
clear all
close all

addpath(genpath('Mass Prop Files'))
addpath(genpath('Functions_CG_analysis'))


%% 747 Test Case
% Manual Inputs
X_np = 113.2269030; %ft %Neutral point from VSPAero .stab
c_MAC = 34.72518; %ft %wing mean aerodynamic chord
SM_min_req = 0.05; %minimum desired static margin
SM_max_req = 0.25; %maximum desired static margin

% Read mass properties from file
[totalMass, compNames, compMass, compCG] = readVSPMassProps('747200_updated_MassProps.txt');

% Build component sets
setsFile = '747sets.mat';
% load in data from previous run, load same sets if components are the same
sets = loadSets(setsFile,compNames);
% Open GUI to make component sets
[allSets,sets] = buildComponentSetGUI(compNames, compMass, compCG, sets);
% Save sets for next time
prev.sets = sets;
prev.compNames = compNames;
save(setsFile,'prev')

% Calculate CG for all cases
allSets = PlaneCGcalc(allSets);

% Plotting
plot_CGcases(allSets,X_np,c_MAC,SM_min_req,SM_max_req)

%% Cessna Test Case
% Manual Inputs
X_np = 9.5545879; %ft %Neutral point from VSPAero .stab
c_MAC = 4.49072; %ft %wing mean aerodynamic chord
SM_min_req = 0.05; %minimum desired static margin
SM_max_req = 0.25; %maximum desired static margin

% Read mass properties from file
[totalMass, compNames, compMass, compCG] = readVSPMassProps('CESSNA_172_updated_MassProps.txt');

% Build component sets
setsFile = 'CESSNAsets.mat';
% load in data from previous run, load same sets if components are the same
sets = loadSets(setsFile,compNames);
% Open GUI to make component sets
[allSets,sets] = buildComponentSetGUI(compNames, compMass, compCG, sets);
% Save sets for next time
prev.sets = sets;
prev.compNames = compNames;
save(setsFile,'prev')

% Calculate CG for all cases
allSets = PlaneCGcalc(allSets);

% Plotting
plot_CGcases(allSets,X_np,c_MAC,SM_min_req,SM_max_req)
