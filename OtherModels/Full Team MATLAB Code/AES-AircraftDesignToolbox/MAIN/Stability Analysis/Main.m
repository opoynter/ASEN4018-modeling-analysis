%% long example (SI)
clear
clc
close all
data=readParams("Parameters_Etkins.xlsx","ParametersEtkins.xlsx");

flightCond.V0=240;
[~,~,~,flightCond.rho,~,~]=atmosisa(40000/3.281);
flightCond.theta0=deg2rad(0.0);
ImperialFlag=false;
[sys,eigvals]=calcLongitudinalDynamics(data,flightCond,ImperialFlag);
A=sys.A;
x0=[1,0,0,0];%pertub forward velocity by 1 m/s
initial(sys,x0,600)
%% long example Imperial
clear
clc
close all
data=readParams("Parameters_Etkins_Imperial.xlsx","Parameters_Etkins_Imperial.xlsx");

flightCond.V0=780;
[~,~,~,flightCond.rho,~,~]=atmosisa(40000/3.281);
flightCond.rho=flightCond.rho/515.4;%convert to slugs/ft^3 (gross)
flightCond.theta0=deg2rad(0);
ImperialFlag=true;
[sys,eigvals]=calcLongitudinalDynamics(data,flightCond,ImperialFlag);
A=sys.A;
x0=[1,0,0,0];%pertub forward velocity by 1 m/s
initial(sys,x0,600)
%% lat example SI
clear
clc
close all
data=readParams("Parameters_Etkins.xlsx","Parameters_Etkins.xlsx");
flightCond.V0=240;
[~,~,~,flightCond.rho,~,~]=atmosisa(40000/3.281);
flightCond.theta0=0;
ImperialFlag=false;

[sys,eigvals]=calcLateralDynamics(data,flightCond,ImperialFlag);
A=sys.A;
x0=[1,0,0,0];%perturb side velocity by 1 m/s
initial(sys,x0,600)

%% lat example Imperial
clear
clc
close all
data=readParams("Parameters_Etkins_Imperial.xlsx","Parameters_Etkins_Imperial.xlsx");
flightCond.V0=780;
[~,~,~,flightCond.rho,~,~]=atmosisa(40000/3.281);
flightCond.rho=flightCond.rho/515.4;%convert to slugs/ft^3 (gross)
flightCond.theta0=0;
ImperialFlag=true;

[sys,eigvals]=calcLateralDynamics(data,flightCond,ImperialFlag);
A=sys.A;
x0=[1,0,0,0];%perturb side velocity by 1 m/s
initial(sys,x0,600)


