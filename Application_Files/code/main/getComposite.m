function [MSTRS, MSTRN, TSAIH, TSAIW, AZZIT] = composite(S11, S22, S12)
%COMPOSITE    QFT function to calculate composite failure criteria.
%   This function calculates composite failure criteria according to the
%   maximum stress, Tsai-Hill, Tsai-Wu and Azzi-Tsai-Hill theories.
%   
%   COMPOSITE is used internally by Quick Fatigue Tool. The user is not required
%   to run this file.
%
%   
%   Quick Fatigue Tool 6.11-04 Copyright Louis Vallance 2017
%   Last modified 28-Sep-2017 16:31:00 GMT
    
    %%

%% Material
Xt = 400.0;
Xc = 600.0;
Yt = 300.0;
Yc = 250.0;
S = 120.0;
F = 0.5;
B = [];

E = 203e3;
kp = 1190.0;
np = 0.193;

Xet = 0.05;
Xec = 0.1;
Yet = 0.15;
Yec = 0.18;
Se = 0.07;

%% Misc
if S11 > 0.0
    X = Xt;
else
    X = Xc;
end

if S22 > 0.0
    Y = Yt;
else
    Y = Yc;
end

[E11, ~, ~, ~] = css2e(S11, E, kp, np);
[E22, ~, ~, ~] = css2e(S22, E, kp, np);
[E12, ~, ~, ~] = css2e(S12, E, kp, np);

if length(E11) > 1.0
    E11 = E11(2.0);
end
if length(E22) > 1.0
    E22 = E22(2.0);
end
if length(E12) > 1.0
    E12 = E12(2.0);
end

if E11 > 0.0
    Xe = Xet;
else
    Xe = Xec;
end

if E22 > 0.0
    Ye = Yet;
else
    Ye = Yec;
end

F1 = (1.0/Xt) + (1.0/Xc);
F2 = (1.0/Yt) + (1.0/Yc);
F11 = -(1.0/(Xt*Xc));
F22 = -(1.0/(Yt*Yc));
F66 = 1.0/S^2.0;

if isempty(B) == 0.0
    F12 = (1.0/(2.0*B^2.0)) * (1.0 - ((1.0/Xt) + (1.0/Xc) + (1.0/Yt) + (1.0/Yc))*(B^2.0) + ((1.0/(Xt*Xc)) + (1.0/(Yt*Yc)))*(B^2.0));
else
    F12 = F*sqrt(F11*F22);
end

%% Failure
MS11 = S11/X;
MS22 = S22/Y;
MS12 = abs(S12/S);
MSTRS = max([MS11, MS22, MS12]);

TSAIH = (S11^2.0/X^2.0) - ((S11*S22)/X^2.0) + (S22^2.0/Y^2.0) + (S12^2.0/S^2.0);
TSAIW = (F1*S11) + (F2*S22) + (F11*S11^2.0) + (F22*S22^2.0) + (F66*S12^2.0) + (2.0*F12*S11*S22);
AZZIT = (S11^2.0/X^2.0) - (abs((S11*S22))/X^2.0) + (S22^2.0/Y^2.0) + (S12^2.0/S^2.0);

ME11 = E11/Xe;
ME22 = E22/Ye;
ME12 = abs(E12/Se);
MSTRN = max([ME11, ME22, ME12]);

%% Print
clc

fprintf('MSTRS = %f\n', MSTRS);
fprintf('MSTRN = %f\n', MSTRN);
fprintf('TSAIH = %f\n', TSAIH);
fprintf('TSAIW = %f\n', TSAIW);
fprintf('AZZIT = %f\n', AZZIT);