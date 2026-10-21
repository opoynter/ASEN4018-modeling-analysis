%ASEN 4138 MAIN_DEMO.m
%Authors: John Mah, Maggie Wussow, Jonathan Morris
%12/24
%Demo script intended to serve as a baseline for comparisson for a variety
%of aircraft. Currently includes Cessna 172, F-16, Boeing 747-200 and T38. Each
%aircraft's section is meant to be ran individually (cmd/ctrl+enter or click 'run as
%section'). Also includes an OpenVSP verification case for a Cessna 172 and
%a T38 (using the same mission profile and point performance requirements
%as an F16).
%Sections for user input are denoted by %%%%%%%%%%%
%Required subfunctions:
%
%Main Model Functions:
%aero_analysis.m
%sizing.m
%sizing_VSP.m
%point_performance.m
%
%All MSN_SEG Functions
%MSN_SEG_Handler.m
%
%All Constraint_EQ Functions
%Point_Performance_handler.m
%
%Additional Helper functions found in: 
%Main Model Functions/Helper Functions for Aero and Mission Sizing

%Add folder and subfolder paths
addpath(genpath('Display Functions'));
addpath(genpath('Input Excel Sheets'));
addpath(genpath('Main Model Functions'));
addpath(genpath('Read Input Functions'));
addpath(genpath('Validation Test Files'));


%% Excel Spreadsheet Version (F16)
clear
clc
close all


%%%%%%%%%%%%%%%% USER INPUTS%%%%%%%%%%%%%%%%%%%
codeversion = "excel";
activeFile = matlab.desktop.editor.getActiveFilename;
[scriptFolder, ~, ~] = fileparts(activeFile);
outputfolder = fullfile(scriptFolder, "Output Excel Sheets");
if ~exist(outputfolder, 'dir')
    mkdir(outputfolder);
end

%aero analysis
Configuration_filename="ASEN4138_TestCases.xlsx";

%sizing analysis
W_crew = 250; %lb
W_pay_fixed = 0; %lb
W_pay_drop = 1000; %lb
W0_guess=25000;
config_row=1; %Geometric definition row number (ASEN4138_TestCases.xlsx)
MissionProfile_filename="Mission_Profile_Template.xlsx";
sheetnumber_msn=3; %Mission profile sheet number (Mission_Profile_Template.xlsx)
ProfileName="F16";
writeFlag=true;
displayFlag=true;% flag for displaying additional iteration and segment data


%Point Performance
Requirements_filename="Requirements_Input_Template.xlsx";
sheetnumber_req=2;
RequirementName="F16_req";
W_S_range = linspace(40,120,100);

%%%%%%%%%%%%%%%%%%%END INPUTS%%%%%%%%%%%%%%%%%%

msgs = []; %passthrough variable which collects warnings and other information for output
msgs.warnings = [];
%%Aero Analysis
MSN_Profile=Read_MSN_Profile(MissionProfile_filename,sheetnumber_msn,ProfileName);%reads in Mission Profile Excel sheet, saves selected sheet as a struct to be used in other functions
[Design_Input,Propulsion_Input,DragPolar_Model,WaveDrag_Data,msgs]=aero_analysis(Configuration_filename,msgs); 
disp(DragPolar_Model(config_row,:))

%%Mission Performance/Sizing Analysis
[W0,FinalWeightData,IterationData,FinalSegmentData,outputTable,msgs]=sizing(MSN_Profile,config_row,W0_guess,Design_Input,Propulsion_Input,DragPolar_Model,WaveDrag_Data,W_crew,W_pay_fixed,W_pay_drop,msgs);
[RangeFactor_Data,M_eval_range,Alt_eval_range,RF_W] = RangeFactor(config_row,FinalWeightData,Design_Input,Propulsion_Input,DragPolar_Model,WaveDrag_Data);
displaySizingData(displayFlag,W0,FinalSegmentData,FinalWeightData,IterationData,outputTable,MSN_Profile);
outputfilename = writeSizingData(writeFlag,W0,FinalSegmentData,FinalWeightData,IterationData,outputTable,DragPolar_Model,ProfileName,codeversion,outputfolder);

%%Point Performance Analysis
Req_Input=Read_Requirements_Input(Requirements_filename,sheetnumber_req,RequirementName);
msgs = point_performance(Design_Input,1,W0,Propulsion_Input,DragPolar_Model,WaveDrag_Data,outputTable,Req_Input,W_S_range,msgs);

writemsgs(msgs,outputfilename) %output warnings to output file


%% Excel Spreadsheet Version (C172)
clear
clc
close all
%%%%%%%%%%%%%%%%USER INPUTS%%%%%%%%%%%%%%%%%%%
codeversion = "excel";
activeFile = matlab.desktop.editor.getActiveFilename;
[scriptFolder, ~, ~] = fileparts(activeFile);
outputfolder = fullfile(scriptFolder, "Output Excel Sheets");
if ~exist(outputfolder, 'dir')
    mkdir(outputfolder);
end


%aero analysis
Configuration_filename="ASEN4138_TestCases.xlsx";

%sizing analysis
W_crew = 600; %lb
W_pay_fixed = 0; %lb
W_pay_drop = 0; %lb
W0_guess=1500;
config_row=2; %Geometric definition row number (ASEN4138_TestCases.xlsx)
MissionProfile_filename="Mission_Profile_Template.xlsx";
sheetnumber_msn=6; %Mission profile sheet number (Mission_Profile_Template.xlsx)
ProfileName="C172";
writeFlag=true;
displayFlag=true;% flag for displaying additional iteration and segment data


%Point Performance
Requirements_filename="Requirements_Input_Template.xlsx";
sheetnumber_req=3;
RequirementName="C172_req";
W_S_range = linspace(5,20,100);
%%%%%%%%%%%%%%%%%%%END INPUTS%%%%%%%%%%%%%%%%%%

msgs = []; %passthrough variable which collects warnings and other information for output
msgs.warnings = [];
%%Aero Analysis
[Design_Input,Propulsion_Input,DragPolar_Model,WaveDrag_Data,msgs]=aero_analysis(Configuration_filename,msgs);
disp(DragPolar_Model(config_row,:))

%%Mission Performance/Sizing Analysis
MSN_Profile=Read_MSN_Profile(MissionProfile_filename,sheetnumber_msn,ProfileName);
[W0,FinalWeightData,IterationData,FinalSegmentData,outputTable,msgs]=sizing(MSN_Profile,config_row,W0_guess,Design_Input,Propulsion_Input,DragPolar_Model,WaveDrag_Data,W_crew,W_pay_fixed,W_pay_drop,msgs);
[RangeFactor_Data,M_eval_range,Alt_eval_range,RF_W] = RangeFactor(config_row,FinalWeightData,Design_Input,Propulsion_Input,DragPolar_Model,WaveDrag_Data);
displaySizingData(displayFlag,W0,FinalSegmentData,FinalWeightData,IterationData,outputTable,MSN_Profile);
outputfilename = writeSizingData(writeFlag,W0,FinalSegmentData,FinalWeightData,IterationData,outputTable,DragPolar_Model,ProfileName,codeversion,outputfolder);

%%Point Performance Analysis
Req_Input=Read_Requirements_Input(Requirements_filename,sheetnumber_req,RequirementName);
msgs = point_performance(Design_Input,config_row,W0,Propulsion_Input,DragPolar_Model,WaveDrag_Data,outputTable,Req_Input,W_S_range,msgs);

writemsgs(msgs,outputfilename) %output warnings to output file


%% Excel Spreadsheet Version (ELECTRIC C172)
clear
clc
close all
%%%%%%%%%%%%%%%%USER INPUTS%%%%%%%%%%%%%%%%%%%
codeversion = "excel";
activeFile = matlab.desktop.editor.getActiveFilename;
[scriptFolder, ~, ~] = fileparts(activeFile);
outputfolder = fullfile(scriptFolder, "Output Excel Sheets");
%aero analysis
Configuration_filename="ASEN4138_TestCases.xlsx";

%sizing analysis
W_crew = 600; %lb
W_pay_fixed = 0; %lb
W_pay_drop = 0; %lb
W0_guess=1500;
config_row=5; %Geometric definition row number (ASEN4138_TestCases.xlsx)
MissionProfile_filename="Mission_Profile_Template.xlsx";
sheetnumber_msn=7; %Mission profile sheet number (Mission_Profile_Template.xlsx)
ProfileName="C172_Electric";
writeFlag=true;
displayFlag=true;% flag for displaying additional iteration and segment data


%Point Performance
Requirements_filename="Requirements_Input_Template.xlsx";
sheetnumber_req=3;
RequirementName="C172_Electric_req";
W_S_range = linspace(5,20,100);
%%%%%%%%%%%%%%%%%%%END INPUTS%%%%%%%%%%%%%%%%%%

msgs = []; %passthrough variable which collects warnings and other information for output
msgs.warnings = [];
%%Aero Analysis
[Design_Input,Propulsion_Input,DragPolar_Model,WaveDrag_Data,msgs]=aero_analysis(Configuration_filename,msgs);
disp(DragPolar_Model(config_row,:))

%%Mission Performance/Sizing Analysis
MSN_Profile=Read_MSN_Profile(MissionProfile_filename,sheetnumber_msn,ProfileName);
[W0,FinalWeightData,IterationData,FinalSegmentData,outputTable,msgs]=sizing(MSN_Profile,config_row,W0_guess,Design_Input,Propulsion_Input,DragPolar_Model,WaveDrag_Data,W_crew,W_pay_fixed,W_pay_drop,msgs);
displaySizingData(displayFlag,W0,FinalSegmentData,FinalWeightData,IterationData,outputTable,MSN_Profile);
outputfilename = writeSizingData(writeFlag,W0,FinalSegmentData,FinalWeightData,IterationData,outputTable,DragPolar_Model,ProfileName,codeversion,outputfolder);

%%Point Performance Analysis
Req_Input=Read_Requirements_Input(Requirements_filename,sheetnumber_req,RequirementName);
msgs = point_performance(Design_Input,config_row,W0,Propulsion_Input,DragPolar_Model,WaveDrag_Data,outputTable,Req_Input,W_S_range,msgs);

writemsgs(msgs,outputfilename) %output warnings to output file

%% Excel Spreadsheet Version (B747-200)
clear
clc
close all
%%%%%%%%%%%%%%%%USER INPUTS%%%%%%%%%%%%%%%%%%%
codeversion = "excel";
activeFile = matlab.desktop.editor.getActiveFilename;
[scriptFolder, ~, ~] = fileparts(activeFile);
outputfolder = fullfile(scriptFolder, "Output Excel Sheets");
if ~exist(outputfolder, 'dir')
    mkdir(outputfolder);
end

%Aero Analysis
Configuration_filename="ASEN4138_TestCases.xlsx";

%Sizing Analysis
W_crew = 2000; %lb
W_pay_fixed = 45000; %lb
W_pay_drop = 0; %lb
W0_guess=700000;

config_row=3; %Geometric definition row number (ASEN4138_TestCases.xlsx)
MissionProfile_filename="Mission_Profile_Template.xlsx";
sheetnumber=5; %Mission profile sheet number (Mission_Profile_Template.xlsx)
ProfileName="B747";
writeFlag=true;
displayFlag=true;% flag for displaying additional iteration and segment data



%Point Performance
Requirements_filename="Requirements_Input_Template.xlsx";
sheetnumber_req=4;
RequirementName="B747-200_req";
W_S_range = linspace(80,140,100);

%%%%%%%%%%%%%%%%%%%END INPUTS%%%%%%%%%%%%%%%%%%

msgs = []; %passthrough variable which collects warnings and other information for output
msgs.warnings = [];
%%Aero Analysis
[Design_Input,Propulsion_Input,DragPolar_Model,WaveDrag_Data,msgs]=aero_analysis(Configuration_filename,msgs);
disp(DragPolar_Model(config_row,:))

%%Mission Performance/Sizing Analysis
MSN_Profile=Read_MSN_Profile(MissionProfile_filename,sheetnumber,ProfileName);
[W0,FinalWeightData,IterationData,FinalSegmentData,outputTable,msgs]=sizing(MSN_Profile,config_row,W0_guess,Design_Input,Propulsion_Input,DragPolar_Model,WaveDrag_Data,W_crew,W_pay_fixed,W_pay_drop,msgs);
[RangeFactor_Data,M_eval_range,Alt_eval_range,RF_W] = RangeFactor(config_row,FinalWeightData,Design_Input,Propulsion_Input,DragPolar_Model,WaveDrag_Data);
displaySizingData(displayFlag,W0,FinalSegmentData,FinalWeightData,IterationData,outputTable,MSN_Profile);
outputfilename = writeSizingData(writeFlag,W0,FinalSegmentData,FinalWeightData,IterationData,outputTable,DragPolar_Model,ProfileName,codeversion,outputfolder);

%%Point Performance Analysis
Req_Input=Read_Requirements_Input(Requirements_filename,sheetnumber_req,RequirementName);
msgs = point_performance(Design_Input,config_row,W0,Propulsion_Input,DragPolar_Model,WaveDrag_Data,outputTable,Req_Input,W_S_range,msgs);

writemsgs(msgs,outputfilename) %output warnings to output file

%% Excel Spreadsheet Version (Tiltrotor Turboprop)
clear
clc
close all
%%%%%%%%%%%%%%%%USER INPUTS%%%%%%%%%%%%%%%%%%%
codeversion = "excel";
activeFile = matlab.desktop.editor.getActiveFilename;
[scriptFolder, ~, ~] = fileparts(activeFile);
outputfolder = fullfile(scriptFolder, "Output Excel Sheets");
if ~exist(outputfolder, 'dir')
    mkdir(outputfolder);
end
%Aero Analysis
Configuration_filename="ASEN4138_TestCases.xlsx";

%Sizing Analysis
W_crew = 1000; %lb
W_pay_fixed = 7500; %lb
W_pay_drop = 0; %lb
W0_guess=40000;
config_row=6; %Geometric definition row number (ASEN4138_TestCases.xlsx)
MissionProfile_filename="Mission_Profile_Template.xlsx";
sheetnumber=8; %Mission profile sheet number (Mission_Profile_Template.xlsx)
ProfileName="TurboTilt";
writeFlag=true;
displayFlag=true;% flag for displaying additional iteration and segment data



%Point Performance
Requirements_filename="Requirements_Input_Template.xlsx";
sheetnumber_req=5;
RequirementName="TurboTilt";
W_S_range = linspace(100,200,100);

%%%%%%%%%%%%%%%%%%%END INPUTS%%%%%%%%%%%%%%%%%%

msgs = []; %passthrough variable which collects warnings and other information for output
msgs.warnings = [];
%%Aero Analysis
[Design_Input,Propulsion_Input,DragPolar_Model,WaveDrag_Data,msgs]=aero_analysis(Configuration_filename,msgs);
disp(DragPolar_Model(config_row,:))

%%Mission Performance/Sizing Analysis
MSN_Profile=Read_MSN_Profile(MissionProfile_filename,sheetnumber,ProfileName);
[W0,FinalWeightData,IterationData,FinalSegmentData,outputTable,msgs]=sizing(MSN_Profile,config_row,W0_guess,Design_Input,Propulsion_Input,DragPolar_Model,WaveDrag_Data,W_crew,W_pay_fixed,W_pay_drop,msgs);
[RangeFactor_Data,M_eval_range,Alt_eval_range,RF_W] = RangeFactor(config_row,FinalWeightData,Design_Input,Propulsion_Input,DragPolar_Model,WaveDrag_Data);
displaySizingData(displayFlag,W0,FinalSegmentData,FinalWeightData,IterationData,outputTable,MSN_Profile);
outputfilename = writeSizingData(writeFlag,W0,FinalSegmentData,FinalWeightData,IterationData,outputTable,DragPolar_Model,ProfileName,codeversion,outputfolder);

%%Point Performance Analysis
Req_Input=Read_Requirements_Input(Requirements_filename,sheetnumber_req,RequirementName);
msgs=point_performance(Design_Input,config_row,W0,Propulsion_Input,DragPolar_Model,WaveDrag_Data,outputTable,Req_Input,W_S_range,msgs);

writemsgs(msgs,outputfilename) %output warnings to output file


%% VSP Version (C172)
clear
clc
close all

%%%%%%%%%%%%%%%%USER INPUTS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
codeversion = "VSP";
activeFile = matlab.desktop.editor.getActiveFilename;
[scriptFolder, ~, ~] = fileparts(activeFile);
outputfolder = fullfile(scriptFolder, "Output Excel Sheets");
if ~exist(outputfolder, 'dir')
    mkdir(outputfolder);
end

displayFlag=true;
writeFlag=true;
W_crew = 600; %lb
W_pay_fixed = 0; %lb
W_pay_drop = 0; %lb
W0_guess=2000;
MissionProfile_filename="Mission_Profile_Template.xlsx";
sheetnumber=6; %Mission profile sheet number (Mission_Profile_Template.xlsx)
ProfileName="C172";
% These inputs allow for varaibles to be input as matrixes which can be switched based
% on the i or iteration number. If only single values leave i as 1.
%%% From Design Input Tab or OpenVSP Geometry
% General
Config=1;
Design_Input.ACType = {'GA_Metal_Single','GA_Metal_Single'};
%The options are Jet_Fighter, Jet_Trainer, Jet_Transport, Miliarty_Cargo/Bomber, GA_Single, GA_Twin, Ag_Aircraft, Turboprop_Twin, Flying_Boat, Homebuilt_Metal/wood, Homebuilt_Composite
Design_Input.M_max = [0.3,0.3];
% Wing
Design_Input.AR_w = [7.32,8.2];
Design_Input.Sref_w = [174,225];
Design_Input.Sweep_w = [0,0];
% Airfoil
Design_Input.AirfoilThick_w = [0.12,0.12];
% Propulsion
%Type of propulsion used in design
Propulsion_Input.PropType = {'PROP_Fuel','PROP_Fuel'};
%The options are PROP_Fuel, PROP_Electric, JET_HBP_Turbofan,JET_LBP_Turbofan
Propulsion_Input.Number = [1,2]; %Number of engines
Propulsion_Input.TA_mil_sl = [0,0]; %Per engine static,uninstalled thrust @ s.l.
Propulsion_Input.TSFC_mil_sl = [0,0]; %TSFC in mil power (lb/hr/lb)
Propulsion_Input.TA_AB_sl = [0,0]; %Per engine static,uninstalled thrust, w/AB @ s.l.
Propulsion_Input.TSFC_AB_sl = [0,0]; %TSFC in AB power (lb/hr/lb)
Propulsion_Input.Install_loss = [0,0]; %Installation loss (% in decimal value)
Propulsion_Input.PA_shp_sl = [180,180]; %Shaft horsepower for prop engine, uninstalled @ s.l.
Propulsion_Input.SFC_sl = [0.39,0.39]; %SFC (lb/hr/hp)
Propulsion_Input.Prop_eff = [0.8,0.8]; %Propellor efficiency
%%% OpenVSP file names
% all the file names that need to be read in (if subsonic all but the first 2 can be left empty)
file_location = "Validation Test Files/C172 VSP Analysis Files/"; %if you have a seperate folder where you store all the output OpenVSP files please put them here. If not leave it as ""
sub_parasite_file_name = {"X_parasite_C172_M03.csv","X_parasite_C172_M03.csv"};
sub_aero_file_name = {"X_c172_M03.xlsx","X_c172_M03.xlsx"};

peakWave_wave_file_name = {"",""};
peakWave_parasite_file_name = {"",""};
maxDesign_wave_file_name = {"",""};
maxDesign_parasite_file_name = {"",""};

%Point Performance
Requirements_filename="Requirements_Input_Template.xlsx";
sheetnumber_req=3;
RequirementName="C172_req";
W_S_range = linspace(5,20,100);
%%%%%%%%%%%%%%%%%%%END INPUTS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

msgs = []; %passthrough variable which collects warnings and other information for output
msgs.warnings = [];
%%Mission Performance/Sizing Analysis
MSN_Profile=Read_MSN_Profile(MissionProfile_filename,sheetnumber,ProfileName);
[W0,FinalWeightData,IterationData,FinalSegmentData,outputTable,DragPolar_Model,WaveDrag_Data,msgs]=sizing_VSP(MSN_Profile,Config,W0_guess,Design_Input,Propulsion_Input,W_crew,W_pay_fixed,W_pay_drop,file_location,sub_parasite_file_name,sub_aero_file_name,peakWave_wave_file_name,peakWave_parasite_file_name,maxDesign_wave_file_name,maxDesign_parasite_file_name,msgs);
[RangeFactor_Data,M_eval_range,Alt_eval_range,RF_W] = RangeFactor(Config,FinalWeightData,Design_Input,Propulsion_Input,DragPolar_Model,WaveDrag_Data);
displaySizingData(displayFlag,W0,FinalSegmentData,FinalWeightData,IterationData,outputTable,MSN_Profile);
outputfilename = writeSizingData(writeFlag,W0,FinalSegmentData,FinalWeightData,IterationData,outputTable,DragPolar_Model,ProfileName,codeversion,outputfolder);

%%Point Performance Analysis
Req_Input=Read_Requirements_Input(Requirements_filename,sheetnumber_req,RequirementName);
msgs=point_performance(Design_Input,Config,W0,Propulsion_Input,DragPolar_Model,WaveDrag_Data,outputTable,Req_Input,W_S_range,msgs);

writemsgs(msgs,outputfilename) %output warnings to output file







%% VSP Version (C172-Electric)
clear
clc
close all
%%%%%%%%%%%%%%%%USER INPUTS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
codeversion = "VSP";
activeFile = matlab.desktop.editor.getActiveFilename;
[scriptFolder, ~, ~] = fileparts(activeFile);
outputfolder = fullfile(scriptFolder, "Output Excel Sheets");
if ~exist(outputfolder, 'dir')
    mkdir(outputfolder);
end
displayFlag=true;
writeFlag=true;
W_crew = 600; %lb
W_pay_fixed = 0; %lb
W_pay_drop = 0; %lb
W0_guess=2000;
MissionProfile_filename="Mission_Profile_Template.xlsx";
sheetnumber=7; %Mission profile sheet number (Mission_Profile_Template.xlsx)
ProfileName="C172 Electric";
% These inputs allow for varaibles to be input as matrixes which can be switched based
% on the i or iteration number. If only single values leave i as 1.
%%% From Design Input Tab or OpenVSP Geometry
% General
Config=1;
Design_Input.ACType = {'GA_Metal_Single','GA_Metal_Single'};
%The options are Jet_Fighter, Jet_Trainer, Jet_Transport, Miliarty_Cargo/Bomber, GA_Single, GA_Twin, Ag_Aircraft, Turboprop_Twin, Flying_Boat, Homebuilt_Metal/wood, Homebuilt_Composite
Design_Input.M_max = [0.3,0.3];
% Wing
Design_Input.AR_w = [7.32,8.2];
Design_Input.Sref_w = [174,225];
Design_Input.Sweep_w = [0,0];
% Airfoil
Design_Input.AirfoilThick_w = [0.12,0.12];
% Propulsion
%Type of propulsion used in design
Propulsion_Input.PropType = {'PROP_Electric','PROP_Electric'};
%The options are PROP_Fuel, PROP_Electric, JET_HBP_Turbofan,JET_LBP_Turbofan
Propulsion_Input.Number = [1,2]; %Number of engines
Propulsion_Input.TA_mil_sl = [0,0]; %Per engine static,uninstalled thrust @ s.l.
Propulsion_Input.TSFC_mil_sl = [0,0]; %TSFC in mil power (lb/hr/lb)
Propulsion_Input.TA_AB_sl = [0,0]; %Per engine static,uninstalled thrust, w/AB @ s.l.
Propulsion_Input.TSFC_AB_sl = [0,0]; %TSFC in AB power (lb/hr/lb)
Propulsion_Input.Install_loss = [0,0]; %Installation loss (% in decimal value)
Propulsion_Input.PA_shp_sl = [180,180]; %Shaft horsepower for prop engine, uninstalled @ s.l.
Propulsion_Input.SFC_sl = [0.39,0.39]; %SFC (lb/hr/hp)
Propulsion_Input.Prop_eff = [0.8,0.8]; %Propellor efficiency
Propulsion_Input.Esb_Real=300;
Propulsion_Input.eta_b2s=.99;
%%% OpenVSP file names
% all the file names that need to be read in (if subsonic all but the first 2 can be left empty)
file_location = "Validation Test Files/C172 VSP Analysis Files/"; %if you have a seperate folder where you store all the output OpenVSP files please put them here. If not leave it as ""
sub_parasite_file_name = {"X_parasite_C172_M03.csv","X_parasite_C172_M03.csv"};
sub_aero_file_name = {"X_c172_M03.xlsx","X_c172_M03.xlsx"};

peakWave_wave_file_name = {"",""};
peakWave_parasite_file_name = {"",""};
maxDesign_wave_file_name = {"",""};
maxDesign_parasite_file_name = {"",""};

%Point Performance
Requirements_filename="Requirements_Input_Template.xlsx";
sheetnumber_req=3;
RequirementName="C172_req";
W_S_range = linspace(5,20,100);
%%%%%%%%%%%%%%%%%%%END INPUTS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

msgs = []; %passthrough variable which collects warnings and other information for output
msgs.warnings = [];
%%Mission Performance/Sizing Analysis
MSN_Profile=Read_MSN_Profile(MissionProfile_filename,sheetnumber,ProfileName);
[W0,FinalWeightData,IterationData,FinalSegmentData,outputTable,DragPolar_Model,WaveDrag_Data,msgs]=sizing_VSP(MSN_Profile,Config,W0_guess,Design_Input,Propulsion_Input,W_crew,W_pay_fixed,W_pay_drop,file_location,sub_parasite_file_name,sub_aero_file_name,peakWave_wave_file_name,peakWave_parasite_file_name,maxDesign_wave_file_name,maxDesign_parasite_file_name,msgs);
displaySizingData(displayFlag,W0,FinalSegmentData,FinalWeightData,IterationData,outputTable,MSN_Profile);
outputfilename = writeSizingData(writeFlag,W0,FinalSegmentData,FinalWeightData,IterationData,outputTable,DragPolar_Model,ProfileName,codeversion,outputfolder);

%%Point Performance Analysis
Req_Input=Read_Requirements_Input(Requirements_filename,sheetnumber_req,RequirementName);
msgs=point_performance(Design_Input,Config,W0,Propulsion_Input,DragPolar_Model,WaveDrag_Data,outputTable,Req_Input,W_S_range,msgs);

writemsgs(msgs,outputfilename) %output warnings to output file


%% VSP Version (T38) - analysis using F16 Mission profile and point performance
clear
clc
close all
%%%%%%%%%%%%%%%%USER INPUTS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
codeversion = "VSP";
activeFile = matlab.desktop.editor.getActiveFilename;
[scriptFolder, ~, ~] = fileparts(activeFile);
outputfolder = fullfile(scriptFolder, "Output Excel Sheets");
if ~exist(outputfolder, 'dir')
    mkdir(outputfolder);
end
displayFlag=true;
writeFlag=true;
W_crew = 400; %lb
W_pay_fixed = 0; %lb
W_pay_drop = 1000; %lb
W0_guess=15000;
MissionProfile_filename="Mission_Profile_Template.xlsx";
sheetnumber=2; %Mission profile sheet number (Mission_Profile_Template.xlsx)
ProfileName="T38";
% These inputs allow for varaibles to be input as matrixes which can be switched based
% on the i or iteration number. If only single values leave i as 1.
%%% From Design Input Tab or OpenVSP Geometry

% General
Config=1;
Design_Input.ACType = {'Jet_Fighter','Jet_Fighter'};
%The options are Jet_Fighter, Jet_Trainer, Jet_Transport, Miliarty_Cargo/Bomber, GA_Single, GA_Twin, Ag_Aircraft, Turboprop_Twin, Flying_Boat, Homebuilt_Metal/wood, Homebuilt_Composite
Design_Input.M_max = [1.3,1.3];
% Wing
Design_Input.AR_w = [3.75,3.75];
Design_Input.Sref_w = [170,170];
Design_Input.Sweep_w = [0,0];
% Airfoil
Design_Input.AirfoilThick_w = [0.06,0.06];
% Propulsion
%Type of propulsion used in design
Propulsion_Input.PropType = {'JET_LBP_Turbofan','JET_LBP_Turbofan'};
%The options are PROP_Fuel, PROP_Electric, JET_HBP_Turbofan,JET_LBP_Turbofan
Propulsion_Input.Number = [2,2]; %Number of engines
Propulsion_Input.TA_mil_sl = [2700,2700]; %Per engine static,uninstalled thrust @ s.l.
Propulsion_Input.TSFC_mil_sl = [0.65,0.65]; %TSFC in mil power (lb/hr/lb)
Propulsion_Input.TA_AB_sl = [3800,3800]; %Per engine static,uninstalled thrust, w/AB @ s.l.
Propulsion_Input.TSFC_AB_sl = [1.7,1.7]; %TSFC in AB power (lb/hr/lb)
Propulsion_Input.Install_loss = [.1,.1]; %Installation loss (% in decimal value)
Propulsion_Input.PA_shp_sl = [0,0]; %Shaft horsepower for prop engine, uninstalled @ s.l.
Propulsion_Input.SFC_sl = [0,0]; %SFC (lb/hr/hp)
Propulsion_Input.Prop_eff = [0,0]; %Propellor efficiency
%%% OpenVSP file names
% all the file names that need to be read in (if subsonic all but the first
% 2 can be left empty)
file_location = "Validation Test Files/T38 VSP Analysis Files/"; %if you have a seperate folder where you store all the output OpenVSP files please put them here. If not leave it as ""
sub_parasite_file_name = {"T38_CDo_M03.csv","T38_CDo_M03.csv"};
sub_aero_file_name = {"Northrup_T38_M03_VSPAERO.xlsm","Northrup_T38_M03_VSPAERO.xlsm"};

peakWave_wave_file_name = {"Northrup_T38_WaveDrag_M1.010000_Modified_Model_Inlet_flow.txt","Northrup_T38_WaveDrag_M1.010000_Modified_Model_Inlet_flow.txt"};
peakWave_parasite_file_name = {"T38_CDo_M105.csv","T38_CDo_M105.csv"};
maxDesign_wave_file_name = {"Northrup_T38_WaveDrag_M1.500000_Modified_Model_Inlet_flow.txt","Northrup_T38_WaveDrag_M1.500000_Modified_Model_Inlet_flow.txt"};
maxDesign_parasite_file_name = {"T38_CDo_M15.csv","T38_CDo_M15.csv"};

%Point Performance
Requirements_filename="Requirements_Input_Template.xlsx";
sheetnumber_req=2;
RequirementName="T38_req";
W_S_range = linspace(40,120,100);
%%%%%%%%%%%%%%%%%%%END INPUTS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

msgs = []; %passthrough variable which collects warnings and other information for output
msgs.warnings = [];
%%Mission Performance/Sizing Analysis
MSN_Profile=Read_MSN_Profile(MissionProfile_filename,sheetnumber,ProfileName);
[W0,FinalWeightData,IterationData,FinalSegmentData,outputTable,DragPolar_Model,WaveDrag_Data,msgs]=sizing_VSP(MSN_Profile,Config,W0_guess,Design_Input,Propulsion_Input,W_crew,W_pay_fixed,W_pay_drop,file_location,sub_parasite_file_name,sub_aero_file_name,peakWave_wave_file_name,peakWave_parasite_file_name,maxDesign_wave_file_name,maxDesign_parasite_file_name,msgs);
[RangeFactor_Data,M_eval_range,Alt_eval_range,RF_W] = RangeFactor(Config,FinalWeightData,Design_Input,Propulsion_Input,DragPolar_Model,WaveDrag_Data);
displaySizingData(displayFlag,W0,FinalSegmentData,FinalWeightData,IterationData,outputTable,MSN_Profile);
outputfilename = writeSizingData(writeFlag,W0,FinalSegmentData,FinalWeightData,IterationData,outputTable,DragPolar_Model,ProfileName,codeversion,outputfolder);

%%Point Performance Analysis
Req_Input=Read_Requirements_Input(Requirements_filename,sheetnumber_req,RequirementName);
msgs=point_performance(Design_Input,Config,W0,Propulsion_Input,DragPolar_Model,WaveDrag_Data,outputTable,Req_Input,W_S_range,msgs);

writemsgs(msgs,outputfilename) %output warnings to output file

%% VSP Version (747) 
%Initialize Workspace
clear
clc
close all

%Add folder and subfolder paths
addpath(genpath('Display Functions'));
addpath(genpath('Input Excel Sheets'));
addpath(genpath('Main Model Functions'));
addpath(genpath('Read Input Functions'));
addpath(genpath('Validation Test Files'));
%%%%%%%%%%%%%%%%USER INPUTS%%%%%%%%%%%%%%%%%%%
codeversion = "VSP";
activeFile = matlab.desktop.editor.getActiveFilename;
[scriptFolder, ~, ~] = fileparts(activeFile);
outputfolder = fullfile(scriptFolder, "Output Excel Sheets");
if ~exist(outputfolder, 'dir')
    mkdir(outputfolder);
end
%Sizing Analysis
W_crew = 2000; %lb
W_pay_fixed =96000; %lb
W_pay_drop = 0; %lb
W0_guess=700000;
MissionProfile_filename="Mission_Profile_Template.xlsx";
sheetnumber=5; %Mission profile sheet number (Mission_Profile_Template.xlsx)
ProfileName="B747";
displayFlag=true;% flag for displaying additional iteration and segment data
writeFlag=true;

% General
Config=1; %Column in arrays listed below align with different configurations being analyzed (must sequence manually)
Design_Input.ACType = {'Jet_Transport','Jet_Transport'}; %Sets empty weight model used
%The options are Jet_Fighter, Jet_Trainer, Jet_Transport, Miliarty_Cargo/Bomber, GA_Single, GA_Twin, Ag_Aircraft, Turboprop_Twin, Flying_Boat, Homebuilt_Metal/wood, Homebuilt_Composite
Design_Input.M_max = [.85,.85];

% Wing
Design_Input.AR_w = [6.7,6.7];
Design_Input.Sref_w = [5693,5693];
Design_Input.Sweep_w = [37.5,37.5];
% Airfoil
Design_Input.AirfoilThick_w = [0.101,0.101];

% Propulsion
%Type of propulsion used in design
Propulsion_Input.PropType = {'JET_HBP_Turbofan','JET_HBP_Turbofan'};
%The options are PROP_Fuel, PROP_Electric, JET_HBP_Turbofan,JET_LBP_Turbofan, Turboprop
Propulsion_Input.Number = [4,4]; %Number of engines
Propulsion_Input.TA_mil_sl = [57000,57000]; %Per engine static,uninstalled thrust @ s.l. (req for JET_HBP_Turbofan, JET_LBP_Turbofan, and Turboprop)
Propulsion_Input.TSFC_mil_sl = [0.368,0.368]; %TSFC in mil power (lb/hr/lb) (req for JET_HBP_Turbofan, JET_LBP_Turbofan, and Turboprop)
Propulsion_Input.TA_AB_sl = [0,0]; %Per engine static,uninstalled thrust, w/AB @ s.l. (req for any JET_LBP_Turbofan w/ afterburnner, all others put "0" in array)
Propulsion_Input.TSFC_AB_sl = [0,0]; %TSFC in AB power (lb/hr/lb) (req for any JET_LBP_Turbofan w/ afterburnner, all others put "0" in array)
Propulsion_Input.Install_loss = [0.1,0.1]; %Installation loss (% in decimal value) (req for all JET engines, others put "0" in array)
Propulsion_Input.PA_shp_sl = [0,0]; %Shaft horsepower for prop engine, uninstalled @ s.l. (Only for PROP_fuel, and PROP_electric, all others put "0" in array)
Propulsion_Input.SFC_sl = [0,0]; %SFC (lb/hr/hp) (Only for PROP_fuel, and PROP_electric, all others put "0" in array)
Propulsion_Input.Prop_eff = [0,0]; %Propellor efficiency (Only for PROP_fuel, and PROP_electric, all others put "0" in array)

%%% OpenVSP file names
% all the file names that need to be read in (if subsonic all but the first 2 can be left empty)
file_location = "Validation Test Files/B747 VSP Analysis Files/"; %if you have a seperate folder where you store all the output OpenVSP files please put them here. If not leave it as ""
sub_parasite_file_name = {"B747parasite.csv","B747parasite.csv"};
sub_aero_file_name = {"747200.polar.xlsx","747200.polar.xlsx"};

peakWave_wave_file_name = {"",""};
peakWave_parasite_file_name = {"",""};
maxDesign_wave_file_name = {"",""};
maxDesign_parasite_file_name = {"",""};

%Point Performance
Requirements_filename="Requirements_Input_Template.xlsx";
sheetnumber_req=4;
RequirementName="B747-200_req";
W_S_range = linspace(80,200,100);
%%%%%%%%%%%%%%%%%%%END INPUTS%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

msgs = []; %passthrough variable which collects warnings and other information for output
msgs.warnings = [];
%%Mission Performance/Sizing Analysis
MSN_Profile=Read_MSN_Profile(MissionProfile_filename,sheetnumber,ProfileName);
[W0,FinalWeightData,IterationData,FinalSegmentData,outputTable,DragPolar_Model,WaveDrag_Data,msgs]=sizing_VSP(MSN_Profile,Config,W0_guess,Design_Input,Propulsion_Input,W_crew,W_pay_fixed,W_pay_drop,file_location,sub_parasite_file_name,sub_aero_file_name,peakWave_wave_file_name,peakWave_parasite_file_name,maxDesign_wave_file_name,maxDesign_parasite_file_name,msgs);
[RangeFactor_Data,M_eval_range,Alt_eval_range,RF_W] = RangeFactor(Config,FinalWeightData,Design_Input,Propulsion_Input,DragPolar_Model,WaveDrag_Data);
displaySizingData(displayFlag,W0,FinalSegmentData,FinalWeightData,IterationData,outputTable,MSN_Profile);
outputfilename = writeSizingData(writeFlag,W0,FinalSegmentData,FinalWeightData,IterationData,outputTable,DragPolar_Model,ProfileName,codeversion,outputfolder);

%%Point Performance Analysis
Req_Input=Read_Requirements_Input(Requirements_filename,sheetnumber_req,RequirementName);
msgs = point_performance(Design_Input,Config,W0,Propulsion_Input,DragPolar_Model,WaveDrag_Data,outputTable,Req_Input,W_S_range,msgs);

writemsgs(msgs,outputfilename) %output warnings to output file