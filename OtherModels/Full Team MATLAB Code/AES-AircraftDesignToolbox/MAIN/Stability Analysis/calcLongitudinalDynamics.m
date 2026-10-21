function [sys_open,eigenvalues] = calcLongitudinalDynamics(acData, flightCond,ImperialFlag)
    % CALCLONGITUDINALDYNAMICS
    %assume mass in lbm for imperial
    %assumes MOI in slugs/ft^2 for imperial
    %assumes normal SI if ! ImperialFlag
    if ImperialFlag
        g=32.2;
        mass=acData.mass/32.17;

    else
        g=9.81;
        mass=acData.mass;

    end
    Iyy=acData.Iyy;
    S=acData.S;
    c_bar= acData.c_bar;
    u0=flightCond.V0;
    rho=flightCond.rho;
    theta0=flightCond.theta0;
    Q=0.5*rho*u0^2;




    %converitng from ARU (VSP) to FRD (normal,etkin)
    CX0=-acData.CFx0;
    CZ0=-acData.CFz0;

    CX_a=-acData.CFx_a;
    CZ_a=-acData.CFz_a;
    Cm_a=acData.CMy_a;

    CX_q=-acData.CFx_q;
    CZ_q=-acData.CFz_q;
    Cm_q=acData.CMy_q;

    CX_u=-acData.CFx_u;
    CZ_u=-acData.CFz_u;
    Cm_u=acData.CMy_u;


    % Alpha-dot Derivatives is ignored in steady mode in VSP
    if isfield(acData, 'CMy_adot')
        Cm_adot = acData.CMy_adot;
    else
        Cm_adot = 0;
    end

    CX_de=-acData.CFx_de;
    CZ_de=-acData.CFz_de;
    Cm_de=acData.CMy_de;


    %Dimensional derivs (ETKINS CH 4)
    CX_u+2*CX0
    Xu=(CX_u+2*CX0)*Q*S/(mass*u0)
    Xw=(CX_a)*Q*S/(mass*u0);
    Xq=(CX_q)*(c_bar/(2*u0))*(Q*S/mass);

    Zu=(CZ_u+2*CZ0)*Q*S/(mass*u0);
    Zw=(CZ_a)*Q*S/(mass*u0);
    Zq=(CZ_q)*(c_bar/(2*u0))*(Q*S/mass);

    Mu=Cm_u*(Q*S*c_bar)/(u0*Iyy);
    Mw=Cm_a*(Q*S*c_bar)/(u0*Iyy);
    Mq=Cm_q*(c_bar/(2*u0))*(Q*S*c_bar/Iyy);

    Mw_dot=Cm_adot*(c_bar/(2*u0))*(Q*S*c_bar/(u0 * Iyy));

    X_de=CX_de*Q*S/mass;
    Z_de=CZ_de*Q*S/mass;
    M_de=Cm_de*Q*S*c_bar/Iyy;


    M_row_u=Mu+Mw_dot*Zu;
    M_row_w=Mw+Mw_dot*Zw;
    M_row_q=Mq+Mw_dot*(u0+Zq);
    M_row_th=Mw_dot*(-g*sin(theta0));

    % State Matrix A
    A = [Xu,Xw,Xq,-g*cos(theta0);...
        Zu,Zw,u0+Zq,-g*sin(theta0);...
        M_row_u, M_row_w, M_row_q,M_row_th;...
        0,0,1,0];

    % Control Matrix B
    M_de_eff = M_de + Mw_dot * Z_de;
    B = [ X_de;
        Z_de;
        M_de_eff;
        0 ];

    C=eye(4);% ouput
    D=zeros(4,1); %ctrl feedthru

    sys_open = ss(A, B, C, D);
    eigenvalues = eig(A);
    disp("Longitudinal A Matrix")
    disp("=============================================")
    disp(A)
    disp("=============================================")
    disp("Eigenvalues")
    disp(eigenvalues)

end