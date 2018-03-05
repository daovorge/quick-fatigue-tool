function [] = flushData()
%CLEANUP    QFT function to clear material data.
%   This function removes analysis data.
%   
%   FLUSHDATA is used internally by Quick Fatigue Tool. The user
%   is not required to run this file.
%   
%   Quick Fatigue Tool 6.11-13 Copyright Louis Vallance 2018
%   Last modified 02-Feb-2018 09:50:06 GMT
    
    %%
    
%% Remove material data

% Fatigue
if isappdata(0, 'defaultAlgorithm') == 1.0
    rmappdata(0, 'defaultAlgorithm')
end
if isappdata(0, 'defaultMSC') == 1.0
    rmappdata(0, 'defaultMSC')
end
if isappdata(0, 'cael') == 1.0
    rmappdata(0, 'cael')
end
if isappdata(0, 'ndCompression') == 1.0
    rmappdata(0, 'ndCompression')
end
if isappdata(0, 'E') == 1.0
    rmappdata(0, 'E')
end
if isappdata(0, 'poisson') == 1.0
    rmappdata(0, 'poisson')
end
if isappdata(0, 'uts') == 1.0
    rmappdata(0, 'uts')
end
if isappdata(0, 'ucs') == 1.0
    rmappdata(0, 'ucs')
end
if isappdata(0, 'twops') == 1.0
    rmappdata(0, 'twops')
end
if isappdata(0, 'twops') == 1.0
    rmappdata(0, 'twops')
end
if isappdata(0, 's_values') == 1.0
    rmappdata(0, 's_values')
end
if isappdata(0, 'n_values') == 1.0
    rmappdata(0, 'n_values')
end
if isappdata(0, 'r_values') == 1.0
    rmappdata(0, 'r_values')
end
if isappdata(0, 'residualStress') == 1.0
    rmappdata(0, 'residualStress')
end
if isappdata(0, 'ndEndurance') == 1.0
    rmappdata(0, 'ndEndurance')
end
if isappdata(0, 'Sf') == 1.0
    rmappdata(0, 'Sf')
end
if isappdata(0, 'b') == 1.0
    rmappdata(0, 'b')
end
if isappdata(0, 'b2') == 1.0
    rmappdata(0, 'b2')
end
if isappdata(0, 'b2Nf') == 1.0
    rmappdata(0, 'b2Nf')
end
if isappdata(0, 'Ef') == 1.0
    rmappdata(0, 'Ef')
end
if isappdata(0, 'c') == 1.0
    rmappdata(0, 'c')
end
if isappdata(0, 'kp') == 1.0
    rmappdata(0, 'kp')
end
if isappdata(0, 'np') == 1.0
    rmappdata(0, 'np')
end
if isappdata(0, 'fsc') == 1.0
    rmappdata(0, 'fsc')
end
if isappdata(0, 'TfPrime') == 1.0
    rmappdata(0, 'TfPrime')
end
if isappdata(0, 'Tfs') == 1.0
    rmappdata(0, 'Tfs')
end
if isappdata(0, 'k') == 1.0
    rmappdata(0, 'k')
end

% Composote: Fail stress
if isappdata(0, 'failStress_tsfd') == 1.0
    rmappdata(0, 'failStress_tsfd')
end
if isappdata(0, 'failStress_csfd') == 1.0
    rmappdata(0, 'failStress_csfd')
end
if isappdata(0, 'failStress_tstd') == 1.0
    rmappdata(0, 'failStress_tstd')
end
if isappdata(0, 'failStress_cstd') == 1.0
    rmappdata(0, 'failStress_cstd')
end
if isappdata(0, 'failStress_tsttd') == 1.0
    rmappdata(0, 'failStress_tsttd')
end
if isappdata(0, 'failStress_csttd') == 1.0
    rmappdata(0, 'failStress_csttd')
end
if isappdata(0, 'failStress_shear') == 1.0
    rmappdata(0, 'failStress_shear')
end
if isappdata(0, 'failStress_cross12') == 1.0
    rmappdata(0, 'failStress_cross12')
end
if isappdata(0, 'failStress_cross23') == 1.0
    rmappdata(0, 'failStress_cross23')
end
if isappdata(0, 'failStress_limit12') == 1.0
    rmappdata(0, 'failStress_limit12')
end
if isappdata(0, 'failStress_limit23') == 1.0
    rmappdata(0, 'failStress_limit23')
end

% Composote: Fail strain
if isappdata(0, 'failStrain_tsfd') == 1.0
    rmappdata(0, 'failStrain_tsfd')
end
if isappdata(0, 'failStrain_csfd') == 1.0
    rmappdata(0, 'failStrain_csfd')
end
if isappdata(0, 'failStrain_tstd') == 1.0
    rmappdata(0, 'failStrain_tstd')
end
if isappdata(0, 'failStrain_cstd') == 1.0
    rmappdata(0, 'failStrain_cstd')
end
if isappdata(0, 'failStrain_shear') == 1.0
    rmappdata(0, 'failStrain_shear')
end
if isappdata(0, 'failStrain_e11') == 1.0
    rmappdata(0, 'failStrain_e11')
end
if isappdata(0, 'failStrain_e22') == 1.0
    rmappdata(0, 'failStrain_e22')
end
if isappdata(0, 'failStrain_g12') == 1.0
    rmappdata(0, 'failStrain_g12')
end

% Composote: Hashin
if isappdata(0, 'hashin_alpha') == 1.0
    rmappdata(0, 'hashin_alpha')
end
if isappdata(0, 'hashin_lts') == 1.0
    rmappdata(0, 'hashin_lts')
end
if isappdata(0, 'hashin_lcs') == 1.0
    rmappdata(0, 'hashin_lcs')
end
if isappdata(0, 'hashin_tts') == 1.0
    rmappdata(0, 'hashin_tts')
end
if isappdata(0, 'hashin_tcs') == 1.0
    rmappdata(0, 'hashin_tcs')
end
if isappdata(0, 'hashin_lss') == 1.0
    rmappdata(0, 'hashin_lss')
end
if isappdata(0, 'hashin_tss') == 1.0
    rmappdata(0, 'hashin_tss')
end

% Composote: LaRC05
if isappdata(0, 'larc05_lts') == 1.0
    rmappdata(0, 'larc05_lts')
end
if isappdata(0, 'larc05_lcs') == 1.0
    rmappdata(0, 'larc05_lcs')
end
if isappdata(0, 'larc05_tts') == 1.0
    rmappdata(0, 'larc05_tts')
end
if isappdata(0, 'larc05_tcs') == 1.0
    rmappdata(0, 'larc05_tcs')
end
if isappdata(0, 'larc05_lss') == 1.0
    rmappdata(0, 'larc05_lss')
end
if isappdata(0, 'larc05_tss') == 1.0
    rmappdata(0, 'larc05_tss')
end
if isappdata(0, 'larc05_shear') == 1.0
    rmappdata(0, 'larc05_shear')
end
if isappdata(0, 'larc05_nl') == 1.0
    rmappdata(0, 'larc05_nl')
end
if isappdata(0, 'larc05_nt') == 1.0
    rmappdata(0, 'larc05_nt')
end
if isappdata(0, 'larc05_alpha0') == 1.0
    rmappdata(0, 'larc05_alpha0')
end
if isappdata(0, 'larc05_phi0') == 1.0
    rmappdata(0, 'larc05_phi0')
end
if isappdata(0, 'larc05_iterate') == 1.0
    rmappdata(0, 'larc05_iterate')
end

%% Remove loading data
if isappdata(0, 'Sxx') == 1.0
    rmappdata(0, 'Sxx')
end
if isappdata(0, 'Syy') == 1.0
    rmappdata(0, 'Syy')
end
if isappdata(0, 'Szz') == 1.0
    rmappdata(0, 'Szz')
end
if isappdata(0, 'Txy') == 1.0
    rmappdata(0, 'Txy')
end
if isappdata(0, 'Txz') == 1.0
    rmappdata(0, 'Txz')
end
if isappdata(0, 'Tyz') == 1.0
    rmappdata(0, 'Tyz')
end
if isappdata(0, 'SIGOriginalSignal') == 1.0
    rmappdata(0, 'SIGOriginalSignal')
end
if isappdata(0, 'fatigueDefinitionFile') == 1.0
    rmappdata(0, 'fatigueDefinitionFile')
end