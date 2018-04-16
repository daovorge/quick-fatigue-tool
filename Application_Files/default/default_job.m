function [] = default_job()
%TEMPLATE_JOB    Template job file for Quick Fatigue Tool.
%   This function contains a list of job file options to configure a
%   user-defined fatigue analysis.
%
%   Click "Run" or press F5 to start the fatigue analysis.
%   
%   Please refer to the Quick Fatigue Tool User Guide for detailed
%   instructions on creating an analysis job.
%
%   See also environment.
%
%   Reference section in Quick Fatigue Tool User Guide
%      2.4 Configuring and running an analysis
%   
%   Reference section in Quick Fatigue Tool User Settings Reference Guide
%      1 Job file options
%   
%   Quick Fatigue Tool 6.12-00 Copyright Louis Vallance 2018
%   Last modified 28-Mar-2018 09:40:26 GMT

%% 1: JOB

JOB_NAME = 'Job-1';

JOB_DESCRIPTION = 'Template job file';

CONTINUE_FROM = '';

%{
    0: Full analysis
    1: Data check analysis
    2: Use fatigue definition from job name
    'file-name.mat': Specify fatigue definition file
%}
DATA_CHECK = 0.0;

%% 2: MATERIAL

MATERIAL = '';

% STRESS-LIFE CURVE
%{
    0: Coefficients (Sf' and b)
    1: S-N data points
%}
USE_SN = 1.0;

% SCALE S-N STRESS DATAPOINTS
SN_SCALE = [];

% S-N KNOCK-DOWN FACTORS
SN_KNOCK_DOWN = {};

%% 3: LOADING

% STRESS DATASETS
DATASET = '';

% LOAD HISTORIES
%{
    HISTORY = [] if loading is dataset sequence
%}
HISTORY = [];

% DATASET UNITS
%{
    0: User-defined
    1: Pa
    2: kPa
    3: MPa
    4: psi
    5: ksi
    6: Msi
%}
UNITS = 'MPa';

%{
    [Pa] = CONV * [dataset]
%}
CONV = [];

% LOADING EQUIVALENCE
LOAD_EQ = {1.0, 'Repeats'};

% LOAD SCALE FACTORS
SCALE = [];

% LOAD OFFSET VALUES
OFFSET = [];

% LOAD REPEATS
REPEATS = 1.0;

%% 4: HIGH FREQUENCY LOADINGS

HF_DATASET = '';

HF_HISTORY = [];

%{
    HT_TIME = {[LOW_FREQUENCY_PERIOD], [HI_FREQUENCY_PERIOD]};
%}
HF_TIME = {[], []};

% SCALE FACTORS FOR HIGH FREQUENCY DATASETS
HF_SCALE = [];

%% 5: DATASET PROCESSOR

% ELEMENT STRESS ASSUMPTION
%{
    0: Do not allow plane stress elements
    1: Allow plane stress element assumption
%}
ELEMENT_TYPE = 0.0;

%% 6: ANALYSIS

% ANALYSIS GROUPS
GROUP = {'DEFAULT'};

% ANALYSIS ALGORITHM
%{
    0: Default
    3: Uniaxial Strain-Life
    4: Stress-based Brown-Miller (CP)
    5: Normal Stress (CP)
    6: Findley's Method (CP)
    7: Stress Invariant Parameter
    8: BS 7608 Fatigue of welded steel joints (CP)
    9: NASALIFE
    10: Uniaxial Stress-Life
    11: User-defined
%}
ALGORITHM = 0.0;

% MEAN STRESS CORRECTION
%{
    0: Default
    1: Morrow
    2: Goodman
    3: Soderberg
    4: Walker
    5: Smith-Watson-Topper
    6: Gerber
    7: R-ratio S-N curves
    8: None
    'file-name'.msc: User-defined
%}
MS_CORRECTION = 0.0;

% ANALYSIS REGION
%{
    'ALL': Whole model (default)
    'SURFACE': ODB element surface
    'MAXPS': Item with largest (S1-S3)
    'file-name.*': Items defined in text file
    [k1,..., kn]: 1xn item list
%}
ITEMS = 'SURFACE';

%{
    'CAEL': Endurance limit (defined in material)
    k: Nf (repeats)
%}
DESIGN_LIFE = 'CAEL';

% FACTOR OF STRENGTH ALGORITHM
FACTOR_OF_STRENGTH = 0.0;

% FATIGUE RESERVE FACTOR ENVELOPE
%{
    1: Goodman (Default)
    2: Goodman B
    3: Gerber
    'file-name'.msc: User-defined
%}
FATIGUE_RESERVE_FACTOR = 2.0;

% SAVE ITEMS BELOW DESIGN LIFE
HOTSPOT = 0.0;

%% 7: SURFACE FINISH / NOTCH EFFECTS
%{
    k: Define Kt as a value
    'file-name.kt': Select surface finish from list (DATA/KT/*.kt)
    'file-name.ktx': Define surface finish as a value (DATA/KT/*.ktx)
%}
KT_DEF = 'default.kt';

%{
    If KT_DEF is a '.kt' file, KT_CURVE is the surface finish as Ra
    See 'kt_curves.m' for a description of available Kt curves

    If KT_DEF is a '.ktx' file, KT_CURVE is the surface finish as Rz
    See 'ktx_curves.m' for a description of available Ktx curves
%}
KT_CURVE = 1.0;

% FATIGUE NOTCH FACTOR
NOTCH_CONSTANT = [];

NOTCH_RADIUS = [];

% IN-PLANE RESIDUAL STRESS
RESIDUAL = 0.0;

%% 8: VIRTUAL STRAIN GAUGES

GAUGE_LOCATION = {};

GAUGE_ORIENTATION = {};

%% 9: OUTPUT REQUESTS

OUTPUT_FIELD = 1.0;

OUTPUT_HISTORY = 1.0;

OUTPUT_FIGURE = 0.0;

%% 10: ABAQUS ODB INTERFACE

% ASSOCIATE THE JOB WITH AN ABAQUS OUTPUT DATABASE (.ODB) FILE
OUTPUT_DATABASE = '';

PART_INSTANCE = 'PART-1-1';

EXPLICIT_FEA = 0.0;

STEP_NAME = '';

RESULT_POSITION = 'ELEMENT NODAL';

%% 11: BS 7608 WELD DEFINITION

% WELD CLASSIFICATION
WELD_CLASS = 'B';

% WELD MATERIAL
YIELD_STRENGTH = [];

UTS = [];

% PROBABILITY OF FAILURE
DEVIATIONS_BELOW_MEAN = 0.0;

% FAILURE TYPE
FAILURE_MODE = 'NORMAL';

% CORRECTION FACTORS
CHARACTERISTIC_LENGTH = [];

SEA_WATER = 0.0;

%% 12: SUPPLEMENTARY ANALYSIS OPTIONS

% YIELD CRITERION
%{
    0: Do not perform yield criterion assessment
    1: Total strain energy theory
    2: Maximum shear strain energy theory
    3: Tresca yield criterion
    4: von Mises yield criterion
%}
YIELD_CRITERION = 0.0;

% COMPOSITE FAILURE/DAMAGE INITIATION CRITERIA
COMPOSITE_CRITERIA = 0.0;

%% - DO NOT EDIT
flags = {ITEMS, UNITS, SCALE, REPEATS, USE_SN, DESIGN_LIFE, ALGORITHM,...
    MS_CORRECTION, LOAD_EQ, ELEMENT_TYPE, SN_SCALE, OUTPUT_FIELD,...
    OUTPUT_HISTORY, OUTPUT_FIGURE, KT_DEF, KT_CURVE, RESIDUAL,...
    WELD_CLASS, DEVIATIONS_BELOW_MEAN, CHARACTERISTIC_LENGTH, SEA_WATER,...
    YIELD_STRENGTH, FAILURE_MODE, UTS, CONV, OUTPUT_DATABASE, PART_INSTANCE,...
    OFFSET, STEP_NAME, FACTOR_OF_STRENGTH, GROUP, HOTSPOT, SN_KNOCK_DOWN,...
    EXPLICIT_FEA, RESULT_POSITION, CONTINUE_FROM, DATA_CHECK, NOTCH_CONSTANT,...
    NOTCH_RADIUS, GAUGE_LOCATION, GAUGE_ORIENTATION, JOB_NAME,...
    JOB_DESCRIPTION, MATERIAL, DATASET, HISTORY, HF_DATASET, HF_HISTORY,...
    HF_TIME, HF_SCALE, FATIGUE_RESERVE_FACTOR, COMPOSITE_CRITERIA,...
    YIELD_CRITERION};

main(flags)