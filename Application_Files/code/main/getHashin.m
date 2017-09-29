function [HSNFCCRT, HSNFTCRT, HSNMCCRT, HSNMTCRT] = hashin(S11, S22, S33, S12)
%HASHIN    QFT function to calculate Hashin criterion.
%   
%   HASHIN is used internally by Quick Fatigue Tool. The user is not required
%   to run this file.
%
%   
%   Quick Fatigue Tool 6.11-04 Copyright Louis Vallance 2017
%   Last modified 28-Sep-2017 16:31:00 GMT
    
    %%

%% Material
Xt = 400.0;
Xc = 400.0;
Yt = 400.0;
Yc = 400.0;
Sl = 120.0;
St = 120.0;
a = 0.0;

%% Effective stress
df = 0.0;
dm = 0.0;
dc = 0.0;

S = [S11, S12, 0.0; S12, S22, 0.0; 0.0, 0.0, S33];
D = [1.0/(1.0 - df), 0.0, 0.0; 0.0, 1.0/(1.0 - dm), 0.0; 0.0, 0.0, 1.0/(1.0 - dc)];
Sh = S*D;

S11h = Sh(1.0, 1.0);
S22h = Sh(2.0, 2.0);
S12h = Sh(1.0, 2.0);

%% Criteria
HSNFTCRT = 0.0;
HSNFCCRT = 0.0;

HSNMTCRT = 0.0;
HSNMCCRT = 0.0;

%% Mode I/II
if S11 >= 0.0
    HSNFTCRT = (S11h/Xt)^2.0 + a*(S12h/Sl)^2.0;
else
    HSNFCCRT = (S11h/Xc)^2.0;
end

%% Mode III/IV
if S22 >= 0.0
    HSNMTCRT = (S22h/Yt)^2.0 + (S12h/Sl)^2.0;
else
    HSNMCCRT = (S22h/(2.0*St))^2.0 + ((Yc/(2.0*St))^2.0 - 1.0)*(S22h/Yc) + (S12h/Sl)^2.0;
end

%% Print
clc

fprintf('HSNFCCRT = %f\n', HSNFCCRT);
fprintf('HSNFTCRT = %f\n', HSNFTCRT);
fprintf('HSNMCCRT = %f\n', HSNMCCRT);
fprintf('HSNMTCRT = %f\n', HSNMTCRT);