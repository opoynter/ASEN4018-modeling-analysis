function [Design_Input,Propulsion_Input,DragPolar_Model,WaveDrag_Data,msgs]=aero_analysis(filename,msgs)
%%Aircraft Design Aerodynamic Modeling Function
% ASEN 4138
% Author: John Mah, Jonathan Morris

% Description:  This function allows for the rapid aerodynamic analysis of
% multiple conceptual aircraft configurations to enable the brainstorming
% phase of an aircraft conceptual design using very basic geometry inputs
% from the 4138_Design Input File_V24-00.xlsx spreadsheet.  The first order
% models used in this script are meant for initial review of feasibility
% and to evaluate initial concept configurations prior to moving to higher
% order design analysis.  Primary source material for these models were John
% Anderson's Introduction to Flight, 9th ed, Daniel Raymer's Aircraft Design:
% A Conceptual Approach 6th Ed and Steve Brandt's Introduction to Aeronautics:
% A Design Perspective. Additional models used outside of these sources will
% be referenced in the code comments where applicable.

% Current Version:  AY24.00

% Date Last Change: 24 Nov 2024
% Changes in Current Version: Refactored from initial version main script into a function.
% This model is a branched version of the ASEN 2804 vehicle design model AY25.00
% created by John Mah & Preston Tee.  Code history and changes for baseline
% ASEN 2804 code can be referenced in the AY25.00 version of that code.

% Functions & files required to execute this script
%atmos.m
%DragPolar.m
%DragPolar_Function.m
%InducedDrag.m
%LD.m
%ParasiteDrag.m
%Propulsion.m
%WaveDrag.m
%WingGeo.m
%WingLiftDrag.m
%Excel aircraft definition sheet (e.g. ASEN4138_TestCases.xlsx)

%% Clean Workspace and Housekeeping

% clearvars
close all
% removes warnings for table variable names for a cleaner output
warning('OFF', 'MATLAB:table:ModifiedAndSavedVarnames')


%% Import and Read Aircraft Design File

Design_Input = readtable(filename,'Sheet','Main_Input','ReadRowNames',true); %Read in Aircraft Geometry File
Count = height(Design_Input); %Number of different aircraft configurations in design input file

% Import Airfoil Data File
Airfoil = readtable(filename,'Sheet','Airfoil_Data'); %Read in Airfoil Data

% Import Propulsion Design Data
Propulsion_Input = readtable(filename,'Sheet','Propulsion'); %Read in Propulsion Design Input Data for model

%% Quick Explainer - Tables
% This code heavily utilizes tables for data organization. You should think
% of a table as a spreadsheet. Tables are also very similar to a 2D array
% of data exept that the columns can be named so that it is clear what data
% is in those columns. There are multiple ways to get the data out of
% columns, through standard indexing, and through dot indexing.
%
% Standard indexing:
%
% Like when indexing into an array you can get data out of a table by using
% parenthasis, (), which will return another table, which is often a
% problem for calulations and plotting
%   Example:
%       NewTable = OriginalTable(:,:)
%
% Alternativly, if you index in the same way but with curly braces, {}, a
% standard array will be returned
%   Example:
%       NewArray = OriginalTable{:,:}
%
% Finally, if you would like to access just one column, tables support dot
% indexing using the name of the column header. This takes the form of the
% name of the variable, then a dot, then the name of the column, This will
% return a standard 1D array of data
%   Example:
%       NewArray = OriginalTable.ColumnName_1
%
% The tables in this code have been purposly organized such that the rows
% will ALWAYS correspond to the different configuration inputs in the input
% file. In other words, the first input row of the input file (1st row not
% including the header row) will match up with row 1 of the tables in this
% code, the second input will be the 2nd row of tables here, etc. Columns
% will always be variables of interest and will be named appropriately.
%
% More MATLAB documentation on getting data out of tables:
% https://www.mathworks.com/help/matlab/matlab_prog/access-data-in-a-table.html
%
% We have provided the necessary code for packaging the data into tables to
% output from and input to functions in order to keep the size of the
% function headers reasonable. It will be your responsibility to unpack and
% use data passed into functions in tables correctly. Please ensure you
% are using the preallocated varaible names and do not modify the code that
% creates the tables. We want to help you with the math, not with general
% coding

%% Calcuations - Conditions and Wing Geometry
% US Standard Atmophere - uses provided MATLAB File Exchange function in
% English units
[rho,a,T,P,nu,z]= atmos(Design_Input.altitude_o(:,:),'units','US');
ATMOS = table(rho,a,T,P,nu,z); % Reorganize atmopheric conditions into a table for ease of passing into functions
clearvars rho a T P nu z % Clear original variables now that they are in a table
g = 32.2; %Sets constant acceleration of gravity [ft/s^2]

%% Call Wing Geometry Calcuation Function
Plot_WingGeo_Data = 0; %Set to 0 to suppress plots for this function or 1 to output plots (Fig 100 - 199)
[WingGeo_Data,msgs] = WingGeo(Design_Input,Count,Plot_WingGeo_Data,msgs); %Calculate specific wing geometry from wing configuration parameters

%% Calculations - Lift and Drag
% Call Wing Lift & Drag Model Function
Plot_Wing_Data = 1; %Set to 0 to suppress plots for this function or 1 to output plots (Fig 200 - 299)
[WingLiftModel,AoA,AoA_Count,AirfoilLiftCurve,WingLiftCurve,WingDragCurve,msgs] =...
    WingLiftDrag(Design_Input,Airfoil,Count,Plot_Wing_Data,msgs);

%% Call Parasite Drag Buildup Model Function
Plot_Parasite_Data = 0; %Set to 0 to suppress plots for this function or 1 to output plots (Fig 300 - 399)
[Parasite_Drag_Data,FF_Table,msgs] = ...
    ParasiteDrag(Design_Input,Airfoil,WingGeo_Data,ATMOS,Count,Plot_Parasite_Data,msgs);

%% Call Induced Drag Model Function
Plot_Induced_Data = 0; %Set to 0 to suppress plots for this function or 1 to output plots (Fig 400 - 499)
[InducedDrag_Data,msgs] = ...
    InducedDrag(Design_Input,WingLiftModel,WingLiftCurve,WingDragCurve,WingGeo_Data,Count,Plot_Induced_Data,msgs);

%% Call Wave Drag Model Function
Plot_WaveDrag_Data = 0; %Set to 0 to suppress plots for this function or 1 to output plots (Fig 500 - 599)
[WaveDrag_Data,msgs] = WaveDrag(Design_Input,Airfoil,InducedDrag_Data,Count,Plot_WaveDrag_Data,Parasite_Drag_Data,msgs);

%% Call Complete Drag Polar Function
Plot_DragPolar_Data = 1; %Set to 0 to suppress plots for this function or 1 to output plots (Fig 600 - 699)
[DragPolar_Subsonic,DragPolar_Supersonic_Max,DragPolar_Supersonic_Wave_Peak,DragPolar_Model,msgs] = ...
    DragPolar(Parasite_Drag_Data,InducedDrag_Data,WaveDrag_Data,Design_Input,AoA_Count,WingLiftCurve,WingDragCurve,AirfoilLiftCurve,Airfoil,Count,Plot_DragPolar_Data,msgs);

%% Call L/D Analysis Function
Plot_LD_Data = 1; %Set to 0 to suppress plots for this function or 1 to output plots (Fig 700 - 799)
[LD_sub, LD_super, msgs] = ...
    LD(Design_Input,DragPolar_Subsonic,DragPolar_Supersonic_Max,WingLiftCurve,WingDragCurve,AoA_Count,Count,Plot_LD_Data,msgs);

%%Integrated Aero Trade Study Plots

%% Reset default color order
set(0,'DefaultAxesColorOrder','default')
end