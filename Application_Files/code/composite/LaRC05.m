function [LARPFCRT, LARMFCRT, LARKFCRT, LARSFCRT, LARTFCRT] =...
    LaRC05(S11, S22, S33, S12, S13, S23, S1, S2, S3,...
                G12, Xt, Xc, Yt, Yc, Sl, St, alpha0, phi0, nl, nt,...
                LARPFCRT, LARMFCRT, LARKFCRT, LARSFCRT, LARTFCRT,...
                index, symsAvailable, step, iterate)
%LARC05    QFT function to calculate LaRC05 composite failure criteria.
%   
%   LARC05 is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%
%   See also composite, compositeFailure.
%
%   Reference section in Quick Fatigue Tool User Guide
%      12.3 Composite failure criteria
%
%   Quick Fatigue Tool 6.11-13 Copyright Louis Vallance 2018
%   Last modified 20-Nov-2017 15:52:10 GMT
    
    %%

%% Initialise St/nt/phi0 if applicable
if isempty(St) == 1.0
    St = Yc*cosd(alpha0)*(sind(alpha0) + ((cosd(alpha0)) / (tand(2.0*(alpha0)))));
end

if isempty(nt) == 1.0
    nt = -1.0 / (tand(2.0*(alpha0)));
end

if isempty(phi0) == 1.0
    %{
        If the Symbolic Math Toolbox is not installed, do not try to
        calculate the value of phi0 iteratively.
    %}
    if iterate == 1.0 && symsAvailable == 1.0
        phic = atand((1.0 - sqrt(1.0 - 4.0*((Sl/Xc) + nl)*(Sl/Xc))) / (2.0*((Sl/Xc) + nl)));
        L = length(S11);
        syms phi0sym
        phi0j = zeros(1.0, L);
    else
        phi0 = 0.0;
        phi0j = phi0;
    end
else
    phi0j = phi0;
end

%% Polymer failure
% Hydrostatic stress
Sh = (1.0/3.0).*(S11 + S22 + S33);

% k-parameter
k2 = (1.0/6.0).*((S1 - S2).^2.0 + (S2 - S3).^2.0 + (S3 - S1).^2.0);

% Failure criterion
LARPFCRT(index) = max((3.0*(k2 - (Xt - Xc)*Sh)) / (Xt*Xc));

%% Matrix failure
% Initialise critical plane search buffers
FI_mi = zeros(1.0, 181.0);
a = linspace(0.0, 180.0, 181.0);

for i = 1:step:181
    % Get the current value of alpha
    ai = a(i);
    
    % Get the tractions on the current plane
    Sn = 0.5*(S2 + S3) + 0.5*(S2 - S3)*cosd(2.0*ai) + S23*sind(2.0*ai);
    Tt = -0.5*(S2 - S3)*sind(2.0*ai) + S23*cosd(2.0*ai);
    Tl = S12*cosd(ai) + S13*sind(ai);
    
    SnPos = Sn > 0.0;
    SnNeg = Sn <= 0.0;
    
    if any(SnPos) == 0.0
        FI_mi_pos = 0.0;
    else
        % Failure criterion on the current plane (tensile)
        FI_mi_pos = max(((Tt(SnPos)) ./ (St - (nt*Sn(SnPos)))).^2.0 + ((Tl(SnPos)) ./ (Sl - (nl*Sn(SnPos)))).^2.0 + ((Sn(SnPos)) ./ (Yt)).^2.0);
    end
    
    if any(SnNeg) == 0.0
        FI_mi_neg = 0.0;
    else
        % Failure criterion on the current plane (compressive)
        FI_mi_neg = max(((Tt(SnNeg)) ./ (St - (nt*Sn(SnNeg)))).^2.0 + ((Tl(SnNeg)) ./ (Sl - (nl*Sn(SnNeg)))).^2.0);
    end
    
    % Failure criterion on current plane is maximum between compression and tension
    FI_mi(i) = max([FI_mi_pos, FI_mi_neg]);
end

% Failure criterion for the critical plane
FI_m_max = FI_mi == max(FI_mi);
LARMFCRT(index) = max(FI_mi(FI_m_max));

%% Fibre kinking/splitting failure
% Initialise critical plane search buffers
FI_si = zeros(1.0, 181.0);
FI_ki = zeros(1.0, 181.0);
psi = linspace(0.0, 180.0, 181.0);

for i = 1:step:181
    psii = psi(i);
    
    % Get the stresses on the kink band
    S2_psi = cosd(psii*S2).^2.0 + sind(psii*S3).^2.0 + 2.0*sind(psii)*cosd(psii*S23);
    Tau12_psi = S12*cosd(psii) + S13*sind(psii);
    Tau23_psi = -sind(psii)*cosd(psii*S2) + sind(psii)*cosd(psii*S3) + (cosd(psii)^2.0 - sind(psii)^2.0)*S23;
    Tau13_psi = S13*cosd(psii) - S12*sind(psii);
    
    gamma0 = (Tau12_psi/G12);
    
    % Calculate the initial fibre misalignment angle iteratively, if applicable
    if isempty(phi0) == 1.0
        for j = 1:L
            phi0j(j) = eval(solve(phi0sym == phic - gamma0(j)*sin(2.0*phi0sym*(pi/180.0))*Xc, 'phi0sym'));
        end
    end
    
    % Get the misalignment angle
    phi = phi0j.*sign(Tau12_psi) + gamma0;
    
    % Get the stresses on the fibre misalignment plane
    S2_m = sind(phi.*S1).^2.0 + cosd(phi.*S2_psi).^2.0 - 2.0.*sind(phi).*cosd(phi.*Tau12_psi);
    Tau12_m = -sind(phi).*cosd(phi.*S1) + sind(phi).*cosd(phi.*S2_psi) + (cosd(phi).^2.0 - sind(phi).^2.0).*Tau12_psi;
    Tau23_m = Tau23_psi.*cosd(phi) - Tau13_psi.*sind(phi);
    
    S2Pos = S2 > 0.0;
    S2Neg = S2 <= 0.0;
    
    if any(S2Neg) == 0.0
        FI_ki(i) = 0.0;
    else
        % Failure criterion on the current plane (tensile)
        FI_ki(i) = max(((Tau23_m(S2Neg)) / (St - (nt*S2_m(S2Neg)))).^2.0 + ((Tau12_m(S2Neg)) / (Sl - (nl*S2_m(S2Neg)))).^2.0);
    end
    
    if any(S2Pos) == 0.0
        FI_si(i) = 0.0;
    else
        % Failure criterion on the current plane (compressive)
        FI_si(i) = max(((Tau23_m(S2Pos)) / (St - (nt*S2_m(S2Pos)))).^2.0 + ((Tau12_m(S2Pos)) / (Sl - (nl*S2_m(S2Pos)))).^2.0 + ((S2_m(S2Pos)) / (Yt)).^2.0);
    end
end

% Failure crtiterion for the critical plane (kinking)
FI_k_max = FI_ki == max(FI_ki);
LARKFCRT(index) = max(FI_ki(FI_k_max));

% Failure crtiterion for the critical plane (splitting)
FI_s_max = FI_si == max(FI_si);
LARSFCRT(index) = max(FI_si(FI_s_max));

%% Fibre tensile failure
% Failure criterion
if any(S1 > 0.0) == 0.0
    LARTFCRT(index) = 0.0;
else
    LARTFCRT(index) = max(S1(S1 > 0.0)/Xt);
end