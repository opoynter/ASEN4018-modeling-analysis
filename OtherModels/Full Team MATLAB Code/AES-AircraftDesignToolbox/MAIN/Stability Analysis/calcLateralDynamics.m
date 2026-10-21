function [sys_open,eigenvalues] = calcLateralDynamics(acData, flightCond,ImperialFlag)
    %assume mass in lbm for imperial
    %assumes MOI in slugs/ft^2 for imperial
    %assumes normal SI if ! ImperialFlag
    Ixx=acData.Ixx;
    Izz=acData.Izz;
    S=acData.S;
    b=acData.b;

    if isfield(acData, 'Ixz')
        Ixz=acData.Ixz;
    else
        Ixz=0;
    end

    u0=flightCond.V0;
    rho=flightCond.rho;
    theta0=flightCond.theta0;
    if ImperialFlag
        g=32.17;
        mass=acData.mass/32.17;
    else
        g=9.81;
        mass=acData.mass;


    end

    Q=0.5*rho*u0^2;


    Cy_b=acData.CFy_b;
    Cl_b=-acData.CMx_b;
    Cn_b=-acData.CMz_b;

    if isfield(acData, 'CFy_p')
        Cy_p=acData.CFy_p;
    else
        Cy_p=0;
    end
    Cl_p=-acData.CMx_p;
    Cn_p=-acData.CMz_p;

    if isfield(acData, 'CFy_r')
        Cy_r=acData.CFy_r;
    else
        Cy_r=0;
    end
    Cl_r=-acData.CMx_r;
    Cn_r=-acData.CMz_r;

    if isfield(acData, 'CFy_da')
        Cy_da=acData.CFy_da;
        Cl_da=-acData.CMx_da;
        Cn_da=-acData.CMz_da;
    else
        Cy_da=0; Cl_da=0; Cn_da=0;
    end

    if isfield(acData, 'CFy_dr')
        Cy_dr=acData.CFy_dr;
        Cl_dr=-acData.CMx_dr;
        Cn_dr=-acData.CMz_dr;
    else
        Cy_dr=0; Cl_dr=0; Cn_dr=0;
    end


    Y_v=(Q*S*Cy_b)/(mass*u0);
    Y_p=(Q*S*b*Cy_p)/(2*mass*u0);
    Y_r=(Q*S*b*Cy_r)/(2*mass*u0);

    L_v=(Q*S*b*Cl_b)/(Ixx*u0);
    L_p=(Q*S*b^2*Cl_p)/(2*Ixx*u0);
    L_r=(Q*S*b^2*Cl_r)/(2*Ixx*u0);

    N_v=(Q*S*b * Cn_b)/(Izz*u0);
    N_p=(Q*S*b^2*Cn_p)/(2*Izz*u0);
    N_r=(Q*S*b^2*Cn_r)/(2*Izz*u0);

    Y_da=(Q*S*Cy_da)/mass;
    Y_dr=(Q*S*Cy_dr)/mass;

    L_da=(Q*S*b*Cl_da)/Ixx;
    L_dr=(Q*S*b*Cl_dr)/Ixx;

    N_da = (Q*S*b*Cn_da)/Izz;
    N_dr = (Q*S*b*Cn_dr)/Izz;

    % =========================================================================
    % STEP 3: STATE SPACE CONSTRUCTION
    % State vector x = [v, p, r, phi]'
    % =========================================================================

    A_unc =[Y_v,Y_p,(Y_r-u0),g*cos(theta0);...
        L_v,L_p,L_r,0;...
        N_v,N_p,N_r,0;...
        0,1,tan(theta0),0];

    B_unc = [Y_da,Y_dr;
        L_da,L_dr;
        N_da,N_dr;
        0,0];

    E = [ 1,0,0,0;
        0,1,-Ixz/Ixx,0;
        0, -Ixz/Izz,1,0;
        0,0,0,1 ];

    A=E\A_unc;
    B=E\B_unc;

    C=eye(4);
    D=zeros(4,2);

    sys_open = ss(A, B, C, D);
    sys_open.StateName={'v', 'p', 'r', 'phi'};
    sys_open.InputName={'delta_a', 'delta_r'};

    eigenvalues = eig(A);
    disp("Lateral A Matrix")
    disp("=============================================")
    disp(A)
    disp("=============================================")
    disp("Eigenvalues")
    disp(eigenvalues)
end