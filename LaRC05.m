% Material
E11 = 200e3;
E22 = 200e3;
v12 = 0.3;
v23 = 0.3;
G12 = 120e3;
Xt = 400.0;
Xc = 200.0;
Yt = 300.0;
Yc = 150.0;
Sl = 120.0;
St = 120.0;
a0 = 53.0;
phi0 = 0.0;
nl = 0.1;
nt = 0.2867;

% Load
S11 = 200.0;
S22 = 100.0;
S33 = -100.0;
S12 = 50.0;
S13 = -50.0;
S23 = 100.0;

% Principals
S = [S11, S12, S13; S12, S22, S23; S13, S23, S33];
eigenvalues = eig(S);
S1 = max(eigenvalues);
S2 = median(eigenvalues);
S3 = min(eigenvalues);

% Additional material parameters
phi_c = atand((1.0 - sqrt(1.0 - 4.0*((Sl/Xc) + nl)*(Sl/Xc))) / (2.0*((Sl/Xc) + nl)));
gamma_m0 = 0.0;
E33 = E22;
v13 = v12;
G23 = E22/(2.0*(1.0 + v23));
G13 = G12;

%% Polymer
Sh = (1.0/3.0)*(S11 + S22 + S33);
k = (1.0/6.0)*((S1 - S2)^2.0 + (S2 - S3)^2.0 + (S3 - S1)^2.0);
FI_p = (3.0*(k - (Xt - Xc)*Sh)) / (Xt*Xc);

%% Matrix
FI_mi = zeros(1.0, 181.0);
a = linspace(0.0, 180.0, 181.0);
for i = 1:181
    ai = a(i);
    
    Sn = 0.5*(S2 + S3) + 0.5*(S2 - S3)*cosd(2.0*ai) + S23*sind(2.0*ai);
    Tt = -0.5*(S2 - S3)*sind(2.0*ai) + S23*cosd(2.0*ai);
    Tl = S12*cosd(ai) + S13*sind(ai);
    
    if Sn > 0.0
        FI_mi(i) = ((Tt) / (St - (nt*Sn)))^2.0 + ((Tl) / (Sl - (nl*Sn)))^2.0 + ((Sn) / (Yt))^2.0;
    else
        FI_mi(i) = ((Tt) / (St - (nt*Sn)))^2.0 + ((Tl) / (Sl - (nl*Sn)))^2.0;
    end
end

FI_m_max = find(FI_mi == max(FI_mi));
a_max = a(FI_m_max);
FI_m = FI_mi(FI_m_max);

%% Fiber Kink/Split
FI_ki = zeros(1.0, 181.0);
psi = linspace(0.0, 180.0, 181.0);
for i = 1:181
    psii = psi(i);
    
    S2_psi = cosd(psii*S2)^2.0 + sind(psii*S3)^2.0 + 2.0*sind(psii)*cosd(psii*S23);
    Tau12_psi = S12*cosd(psii) + S13*sind(psii);
    Tau23_psi = -sind(psii)*cosd(psii*S2) + sind(psi)*cosd(psii*S3) + (cosd(psii)^2.0 - sind(psii)^2.0)*S23;
    Tau13_psi = S13*cosd(psii) - S12*sind(psii);
    
    gamma_m0 = Tau13_psi/G13;
    phi = phi0*sign(Tau12_psi) + gamma_m0;
    
    S2_m = sind(phi+S1)^2.0 + cosd(phi*S2_psi)^2.0 - 2.0*sind(phi)*cosd(phi*Tau12_psi);
    Tau12_m = -sind(phi)*cosd(phi*S1) + sind(phi)*cosd(phi*S2_psi) + (cosd(phi)^2.0 - sind(phi)^2.0)*Tau12_psi;
    Tau23_m = Tau23_psi*cosd(phi) - Tau13_psi*sind(phi);
    
    if S2 > 0.0
        FI_ki(i) = ((Tau23_m) / (St - (nt*S2_m)))^2.0 + ((Tau12_m) / (Sl - (nl*S2_m)))^2.0 + ((S2_m) / (Yt))^2.0;
    else
        FI_ki(i) = ((Tau23_m) / (St - (nt*S2_m)))^2.0 + ((Tau12_m) / (Sl - (nl*S2_m)))^2.0;
    end
end

FI_k_max = find(FI_ki == max(FI_ki));
psi_max = psi(FI_m_max);
FI_k = FI_ki(FI_k_max);