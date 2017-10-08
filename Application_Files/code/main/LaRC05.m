function [LARPFCRT, LARMFCRT, LARKFCRT, LARTFCRT] = LaRC05(S11, S22, S33, S12, S13, S23, S1, S2, S3,...
                G12, Xt, Xc, Yt, Sl, St, phi0, nl, nt, LARPFCRT, LARMFCRT, LARKFCRT, LARTFCRT, index)
%LARC05    QFT function to calculate LaRC05 composite failure criteria.
%   
%   LARC05 is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%
%   
%   Quick Fatigue Tool 6.11-05 Copyright Louis Vallance 2017
%   Last modified 07-Oct-2017 13:46:24 GMT
    
    %%

%% Polymer
Sh = (1.0/3.0).*(S11 + S22 + S33);
k2 = (1.0/6.0).*((S1 - S2).^2.0 + (S2 - S3).^2.0 + (S3 - S1).^2.0);
LARPFCRT(index) = max((3.0*(k2 - (Xt - Xc)*Sh)) / (Xt*Xc));

%% Matrix
FI_mi = zeros(1.0, 181.0);
a = linspace(0.0, 180.0, 181.0);
for i = 1:181
    ai = a(i);
    
    Sn = 0.5*(S2 + S3) + 0.5*(S2 - S3)*cosd(2.0*ai) + S23*sind(2.0*ai);
    Tt = -0.5*(S2 - S3)*sind(2.0*ai) + S23*cosd(2.0*ai);
    Tl = S12*cosd(ai) + S13*sind(ai);
    
    SnPos = Sn > 0.0;
    SnNeg = Sn <= 0.0;
    
    FI_mi_pos = max(((Tt(SnPos)) ./ (St - (nt*Sn(SnPos)))).^2.0 + ((Tl(SnPos)) ./ (Sl - (nl*Sn(SnPos)))).^2.0 + ((Sn(SnPos)) ./ (Yt)).^2.0);
    FI_mi_neg = max(((Tt(SnNeg)) ./ (St - (nt*Sn(SnNeg)))).^2.0 + ((Tl(SnNeg)) ./ (Sl - (nl*Sn(SnNeg)))).^2.0);
    
    FI_mi(i) = max([FI_mi_pos, FI_mi_neg]);
end

FI_m_max = FI_mi == max(FI_mi);
LARMFCRT(index) = FI_mi(FI_m_max);

%% Fiber Kink/Split
FI_ki = zeros(1.0, 181.0);
psi = linspace(0.0, 180.0, 181.0);
for i = 1:181
    psii = psi(i);
    
    S2_psi = cosd(psii*S2).^2.0 + sind(psii*S3).^2.0 + 2.0*sind(psii)*cosd(psii*S23);
    Tau12_psi = S12*cosd(psii) + S13*sind(psii);
    Tau23_psi = -sind(psii)*cosd(psii*S2) + sind(psii)*cosd(psii*S3) + (cosd(psii)^2.0 - sind(psii)^2.0)*S23;
    Tau13_psi = S13*cosd(psii) - S12*sind(psii);
    
    phi = phi0*sign(Tau12_psi) + (Tau12_psi/G12);
    
    S2_m = sind(phi.*S1).^2.0 + cosd(phi.*S2_psi).^2.0 - 2.0.*sind(phi).*cosd(phi.*Tau12_psi);
    Tau12_m = -sind(phi).*cosd(phi.*S1) + sind(phi).*cosd(phi.*S2_psi) + (cosd(phi).^2.0 - sind(phi).^2.0).*Tau12_psi;
    Tau23_m = Tau23_psi.*cosd(phi) - Tau13_psi.*sind(phi);
    
    S2Pos = S2 > 0.0;
    S2Neg = S2 <= 0.0;
    
    FI_ki_pos = max(((Tau23_m(S2Pos)) / (St - (nt*S2_m(S2Pos)))).^2.0 + ((Tau12_m(S2Pos)) / (Sl - (nl*S2_m(S2Pos)))).^2.0 + ((S2_m(S2Pos)) / (Yt)).^2.0);
    FI_ki_neg = max(((Tau23_m(S2Neg)) / (St - (nt*S2_m(S2Neg)))).^2.0 + ((Tau12_m(S2Neg)) / (Sl - (nl*S2_m(S2Neg)))).^2.0);
    
    FI_ki(i) = max([FI_ki_pos, FI_ki_neg]);
end

FI_k_max = FI_ki == max(FI_ki);
LARKFCRT(index) = FI_ki(FI_k_max);

%% Fire tensile failure
if S1 > 0.0
    LARTFCRT(index) = max(S1/Xt);
else
    LARTFCRT(index) = 0.0;
end