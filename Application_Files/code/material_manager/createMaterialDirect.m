function [] = createMaterialDirect()
%CREATEMATERIALDIRECT
%   Creates material .mat file directly (no GUI)
%
%   Reference section in Quick Fatigue Tool User Guide
%      5 Materials
%
%   Quick Fatigue Tool 6.11-13 Copyright Louis Vallance 2018
%   Last modified 07-Mar-2018 07:50:12 GMT

%%

%% Variable name look-up table
% GENERAL PROPERTIES
% Variable           | Meaning
% ___________________|_____________________________________________________
% default_algorithm* | Default analysis algorithm
% default_msc*       | Default mean stress correction
% class*             | Material classification
% behavior*          | Material behaviour
% reg_model*         | Regression model
% cael               | Constant amplitude endurance limit (2Nf)
% cael_active        | Property flag for cael
% ndCompression      | No damage for fully compressive cycles
% comment            | User comment
%                    
%    * These variables require a key to denote their meaning.
%    (See the VARIABLE KEY LOOK-UP TABLE for guidance)
% _________________________________________________________________________
% MECHANICAL PROPERTIES
% Variable           | Meaning
% ___________________|_____________________________________________________
% e                  | Young's Modulus
% e_active           | Property flag for e_active
% uts                | Ultimate tensile strength
% ucs                | Ultimate compressive strength
% uts_active         | Property flag for uts_active
% proof              | 0.2% strain proof stress
% proof_active       | Property flag for proof_active
% poisson            | Poisson's ratio
% poisson_active     | Property flag for poisson_active
% ___________________|_____________________________________________________
% FATIGUE PROPERTIES
% Variable           | Meaning
% ___________________|_____________________________________________________
% s_values           | S-N data S-values
% n_values           | S-N data N-values
% r_values           | S-N data R-values
% sf                 | Fatigue strength coefficient
% sf_active          | Property flag for sf_active
% b                  | Fatigue strength exponent
% b_active           | Property flag for b_active
% b2                 | Second fatigue strength exponent
% b2Nf               | Life above which to use b2
% ef                 | Fatigue ductility coefficient
% ef_active          | Property flag for ef_active
% c                  | Fatigue ductility exponent
% c_active           | Property flag for c_active
% kp                 | Cyclic strain-hardening coefficient
% kp_active          | Property flag for kp_active
% np                 | Cyclic strain-hardening exponent
% np_active          | Property flag for np_active
% nssc               | Normal stress sensitivity constant
% nssc_active        | Property flag for nssc_active
% ___________________|_____________________________________________________
% STRESS-BASED FAILURE CRITERIA
% Variable           | Meaning
% ___________________|_____________________________________________________
% failStress_tsfd    | Tensile stress, 11-direction
% failStress_csfd    | Compressive stress, 11-direction
% failStress_tstd    | Tensile stress, 22-direction
% failStress_cstd    | Compressive stress, 22-direction
% failStress_tsttd   | Tensile stress, 33-direction
% failStress_csttd   | Compressive stress, 33-direction
% failStress_shear   | Shear strength, 12-plane
% failStress_cross12 | Cross-product coefficient, 12-plane
% failStress_cross23 | Cross-product coefficient, 23-plane
% failStress_limit12 | Stress limit, 12-plane
% failStress_limit23 | Stress limit, 23-plane
% ___________________|_____________________________________________________
% MAXIMUM STRAIN FAILURE THEORY
% Variable           | Meaning
% ___________________|_____________________________________________________
% failStrain_tsfd    | Tensile strain, fibre direction
% failStrain_csfd    | Compressive strain, fibre direction
% failStrain_tstd    | Tensile strain, transverse direction
% failStrain_cstd    | Compressive strain, transverse direction
% failStrain_shear   | Shear strain
% failStrain_e11     | Elastic modulus, fibre direction
% failStrain_e22     | Elastic modulus, transverse direction
% failStrain_g12     | Shear modulus, 12-plane
% ___________________|_____________________________________________________
% HASHIN'S DAMAGE INITIATION CRITERIA
% Variable           | Meaning
% ___________________|_____________________________________________________
% hashin_alpha       | Shear influence parameter
% hashin_lts         | Longitudinal tensile strength
% hashin_lcs         | Longitudinal compressive strength
% hashin_tts         | Transverse tensile strength
% hashin_tcs         | Transverse compressive strength
% hashin_lss         | Longitudinal shear strength
% hashin_tss         | Transverse shear strength
% ___________________|_____________________________________________________
% LARC05 DAMAGE INITIATION CRITERIA
% Variable           | Meaning
% ___________________|_____________________________________________________
% larc05_lts         | Longitudinal tensile strength
% larc05_lcs         | Longitudinal compressive strength
% larc05_tts         | Transverse tensile strength
% larc05_tcs         | Transverse compressive strength
% larc05_lss         | Longitudinal shear strength
% larc05_tss         | Transverse shear strength
% larc05_shear       | Shear modulus
% larc05_nl          | Longitudinal slope coefficient
% larc05_nt          | Transverse slope coefficient
% larc05_alpha0      | Fracture plane angle for pure compression
% larc05_phi0        | Initial fibre misalignment angle
% larc05_iterate     | Allow iterative solution for larc05_phi0
% ___________________|_____________________________________________________
% PROPERTY FLAGS
% Variable           | Meaning
% ___________________|_____________________________________________________
% <property>_active  | 0: Derive <property> if applicable; otherwise, use
%                    |    value specified by <property>
%                    | 1: Always use value specified by <property>
%
%% Variable key look-up table
%
% Variable           | Keys                | Definition
% ___________________|_____________________|_______________________________
% default_algorithm  | {2.0 | 3.0 | 4.0 |  | {Brown-Miller | Normal Strain |
%                    | 6.0 | 7.0 | 8.0 |   | Maximum Shear Strain |
%                    | 9.0 | 10.0 | 11.0 | | Stress-based Brown-Miller |
%                    | 13.0 | 14.0}        | Normal Stress | Findley's Method |
%                    |                     | Stress Invariant Parameter |
%                    |                     | NASALIFE | MMMcK Filipini |
%                    |                     | Uniaxial Strain-Life |
%                    |                     | Uniaxial Stress-Life}
%____________________|_____________________|_______________________________
% default_msc        | {1.0 | 2.0 | 3.0 |  | {Morrow | Goodman | Soderberg |
%                    | 4.0 | 5.0 | 6.0 |   | Walker | Smith-Watson-Topper |
%                    | 7.0 | 8.0}          | Gerber | R-ratio S-N curves |
%                    |                     | None}
%____________________|_____________________|_______________________________
% class              | {1.0 | 2.0 | 3.0 |  | {Wrought steel and alloys |
%                    | 4.0 | 5.0 | 6.0 |   | Ductile iron |
%                    | 7.0}                | Malleable iron - pearlitic structure |
%                    |                     | Wrought iron | Cast iron |
%                    |                     | Aluminium/copper and alloys |
%                    |                     | Other}
%____________________|_____________________|_______________________________
% behavior           | {1.0 | 2.0 | 3.0}   | {Plain/alloy steel |
%                    |                     | Aluminium alloy | Other}
%____________________|_____________________|_______________________________
% reg_model          | {1.0| 2.0 | 3.0 |   | {Uniform La_w (Baumel & Seeger) |
%                    | 4.0 | 5.0}          | Universal Slopes (Manson) |
%                    |                     | Modified Universal Slopes (Muralidharan) |
%                    |                     | 90/50 Rule | None}
%____________________|_____________________|_______________________________

%% User material data
materialName = 'Material-1';

material_properties = struct(...
'default_algorithm', 6.0,...
'default_msc', 1.0,...
'class', 1.0,...
'behavior', 1.0,...
'reg_model', 1.0,...
'cael', 2e7,...
'cael_active', 0.0,...
'ndCompression', 0.0,...
'e', [],...
'e_active', 0.0,...
'uts', [],...
'ucs', [],...
'uts_active', 0.0,...
'proof', [],...
'proof_active', 0.0,...
'poisson', 0.33,...
'poisson_active', 0.0,...
's_values', [],...
'n_values', [],...
'r_values', [],...
'sf', [],...
'sf_active', 0.0,...
'b', [],...
'b_active', 0.0,...
'b2', [],...
'b2Nf', [],...
'ef', [],...
'ef_active', 0.0,...
'c', [],...
'c_active', 0.0,...
'kp', [],...
'kp_active', 0.0,...
'np', [],...
'np_active', 0.0,...
'nssc', 0.2857,...
'nssc_active', 0.0,...
'comment', [],...
'failStress_tsfd', [],...
'failStress_csfd', [],...
'failStress_tstd', [],...
'failStress_cstd', [],...
'failStress_tsttd', [],...
'failStress_csttd', [],...
'failStress_shear', [],...
'failStress_cross12', 0.0,...
'failStress_cross23', 0.0,...
'failStress_limit12', [],...
'failStress_limit23', [],...
'failStrain_tsfd', [],...
'failStrain_csfd', [],...
'failStrain_tstd', [],...
'failStrain_cstd', [],...
'failStrain_shear', [],...
'failStrain_e11', [],...
'failStrain_e22', [],...
'failStrain_g12', [],...
'hashin_alpha', 0.0,...
'hashin_lts', [],...
'hashin_lcs', [],...
'hashin_tts', [],...
'hashin_tcs', [],...
'hashin_lss', [],...
'hashin_tss', [],...
'larc05_lts', [],...
'larc05_lcs', [],...
'larc05_tts', [],...
'larc05_tcs', [],...
'larc05_lss', [],...
'larc05_tss', [],...
'larc05_shear', [],...
'larc05_nl', [],...
'larc05_nt', [],...
'larc05_alpha0', 53.0,...
'larc05_phi0', 0.0,...
'larc05_iterate', 0.0); %#ok<NASGU>

%% Save the material - DO NOT EDIT

% Check for illegal characters in the material name
if isempty(regexp(materialName, '[/\\*:?"<>|]', 'once')) == 0.0
    message1 = sprintf('The material name cannot contain any of the following characters:\n\n');
    message2 = sprintf('/ \\ * : ? " < > | ');
    waitfor(errordlg([message1, message2], 'Quick Fatigue Tool'))
    return
end

% Check if the material already exists in the local database
if exist([pwd, '\data\material\local\', materialName, '.mat'], 'file') == 2.0
    msg = sprintf('''%s'' already exists in the local database. Do you wish to overwrite the material?', materialName);
    response = questdlg(msg, 'Quick Fatigue Tool');
    
    if (strcmpi(response, 'no') == 1.0) || (strcmpi(response, 'cancel') == 1.0) || (isempty(response) == 1.0)
        return
    end
end

% Save the material to a .mat file in the local material database
try
    save([pwd, '\Data\material\local\', materialName, '.mat'], 'material_properties')
catch exception
    errordlg(sprintf('The material could not be saved.\n\n%s', exception.message))
end