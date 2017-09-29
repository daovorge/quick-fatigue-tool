function [] = compositeFailure(N, L)
%COMPOSITEFAILURE    QFT function to calculate composite failure criteria.
%   This function calculates composite failure criteria according to the
%   maximum stress, Tsai-Hill, Tsai-Wu, Azzi-Tsai-Hill and Hashin criteria.
%   
%   COMPOSITEFAILURE is used internally by Quick Fatigue Tool. The user is not required
%   to run this file.
%
%   
%   Quick Fatigue Tool 6.11-04 Copyright Louis Vallance 2017
%   Last modified 29-Sep-2017 15:10:28 GMT
    
    %%


% Get the number of groups for the analysis
G = getappdata(0, 'numberOfGroups');

% Get the group ID buffer
groupIDBuffer = getappdata(0, 'groupIDBuffer');

% Initialize yield variables
MSTRS = linspace(-1.0, -1.0, N);
MSTRN = linspace(-1.0, -1.0, N);
TSAIH = linspace(-1.0, -1.0, N);
TSAIW = linspace(-1.0, -1.0, N);
AZZIT = linspace(-1.0, -1.0, N);

startID = 1.0;
totalCounter = 1.0;

for groups = 1:G
    if strcmpi(groupIDBuffer(1.0).name, 'default') == 1.0
        % There is one, default group
        
        % Store the current material
        setappdata(0, 'message_groupMaterial', getappdata(0, 'material'))
    else
        % Assign group parameters to the current set of analysis IDs
        [N, ~] = group.switchProperties(groups, groupIDBuffer(groups));
        
        % Store the current material
        setappdata(0, 'message_groupMaterial', groupIDBuffer(groups).material)
    end
    
    % Get fail stress properties
    Xt = getappdata(0, 'failStress_tsfd');
    Xc = getappdata(0, 'failStress_csfd');
    Yt = getappdata(0, 'failStress_tstd');
    Yc = getappdata(0, 'failStress_cstd');
    S = getappdata(0, 'failStress_shear');
    F = getappdata(0, 'failStress_cross');
    B = getappdata(0, 'failStress_limit');
    
    % Get fail strain properties
    Xet = getappdata(0, 'failStrain_tsfd');
    Xec = getappdata(0, 'failStrain_csfd');
    Yet = getappdata(0, 'failStrain_tstd');
    Yec = getappdata(0, 'failStrain_cstd');
    Se = getappdata(0, 'failStrain_shear');
    E = getappdata(0, 'E');
    kp = getappdata(0, 'kp');
    np = getappdata(0, 'np');
    v = getappdata(0, 'poisson');
    
    % Check if there is enough data
    if ((isempty(E) == 1.0 || isempty(kp) == 1.0 || isempty(np) == 1.0) && (isempty(v) == 1.0 || isempty(E) == 1.0)) ||...
            (isempty(Xet) == 1.0 && isempty(Xec) == 1.0 && isempty(Yet) == 1.0 && isempty(Yec) == 1.0 && isempty(Se) == 1.0)
        failStrain = -1.0;
    elseif (isempty(kp) == 1.0 || isempty(np) == 1.0) && isempty(E) == 0.0
        failStrain = 0.0;
        sectionG = E/(2.0*(1.0 + v));
    else
        failStrain = 1.0;
    end
    
    if isempty(Xt) == 1.0 && isempty(Xc) == 1.0 && isempty(Yt) == 1.0 && isempty(Yc) == 1.0 && isempty(S) == 1.0
        failStress = -1.0;
    else
        failStress = 1.0;
    end
    
    % Get stress tensor
    S11 = getappdata(0, 'Sxx');
    S22 = getappdata(0, 'Syy');
    S33 = getappdata(0, 'Szz');
    S12 = getappdata(0, 'Txy');
    S13 = getappdata(0, 'Txz');
    S23 = getappdata(0, 'Tyz');
    
    S11 = S11(startID:(startID + N) - 1.0, :);
    S22 = S22(startID:(startID + N) - 1.0, :);
    S33 = S33(startID:(startID + N) - 1.0, :);
    S12 = S12(startID:(startID + N) - 1.0, :);
    S13 = S13(startID:(startID + N) - 1.0, :);
    S23 = S23(startID:(startID + N) - 1.0, :);
    
    X = zeros(1.0, L);
    Y = zeros(1.0, L);
    
    Xe = zeros(1.0, L);
    Ye = zeros(1.0, L);
    
    % Initialize Tsai-Wu parameters
    if failStress ~= -1.0
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
    end
    
    for i = 1:N
        %% Get the stresses at the current item
        S11i = S11(i, :);
        S22i = S22(i, :);
        S33i = S33(i, :);
        S12i = S12(i, :);
        S13i = S13(i, :);
        S23i = S23(i, :);
        
        %% Check for out-of-plane stress components
        if any(S13i) == 1.0 || any(S23i) == 1.0
            messenger.writeMessage(132.0)
        end
        
        %% FAIL STRESS CALCULATION
        if failStress == 1.0
            % Tension-compression split
            X(S11i >= 0.0) = Xt;
            X(S11i < 0.0) = Xc;
            
            Y(S22i >= 0.0) = Yt;
            Y(S22i < 0.0) = Yc;
            
            % Failure calculation
            MS11 = S11i./X;
            MS22 = S22i./Y;
            MS12 = abs(S12./S);
            MSTRS(totalCounter) = max(max([MS11; MS22; MS12]));
            
            TSAIH(totalCounter) = max((S11i.^2.0./X.^2.0) - ((S11i.*S22i)./X.^2.0) + (S22i.^2.0./Y.^2.0) + (S12i.^2.0./S.^2.0));
            TSAIW(totalCounter) = max((F1.*S11i) + (F2.*S22i) + (F11.*S11i.^2.0) + (F22.*S22i.^2.0) + (F66.*S12i.^2.0) + (2.0.*F12.*S11i.*S22i));
            AZZIT(totalCounter) = max((S11i.^2.0./X.^2.0) - (abs((S11i.*S22i))/X.^2.0) + (S22i.^2.0./Y.^2.0) + (S12i.^2.0./S.^2.0));
        end
        
        %% FAIL STRAIN CALCULATION
        if failStrain == 1.0            
            [E11i, ~, ~, ~] = css2e(S11i, E, kp, np);
            [E22i, ~, ~, ~] = css2e(S22i, E, kp, np);
            [E12i, ~, ~, ~] = css2e(S12i, E, kp, np);
            
            E11i = E11i(1.0 + length(E11i) - L:end);
            E22i = E22i(1.0 + length(E22i) - L:end);
            E12i = E11i(1.0 + length(E12i) - L:end);
        elseif failStrain == 0.0
            E11i = S11i./E;
            E22i = S22i./E;
            E12i = S12i./sectionG;
        end
        
        if failStrain ~= -1.0
            % Tension-compression split
            Xe(E11i >= 0.0) = Xet;
            Xe(E11i < 0.0) = Xec;
            
            Ye(E22i >= 0.0) = Yet;
            Ye(E22i < 0.0) = Yec;
            
            ME11 = E11i./Xe;
            ME22 = E22i./Ye;
            ME12 = abs(E12i./Se);
            MSTRN(totalCounter) = max(max([ME11; ME22; ME12]));
        end
        
        totalCounter = totalCounter + 1.0;
    end
    
    % Update the start ID
    startID = startID + N;
end

%% Inform the user if composite has failed
N_MSTRS = length(MSTRS(MSTRS >= 1.0));
N_MSTRN = length(MSTRN(MSTRN >= 1.0));
N_TSAIH = length(TSAIH(TSAIH >= 1.0));
N_TSAIW = length(TSAIW(TSAIW >= 1.0));
N_AZZIT = length(AZZIT(AZZIT >= 1.0));

setappdata(0, 'MSTRS', N_MSTRS)
setappdata(0, 'MSTRN', N_MSTRN)
setappdata(0, 'TSAIH', N_TSAIH)
setappdata(0, 'TSAIW', N_TSAIW)
setappdata(0, 'AZZIT', N_AZZIT)

if N_MSTRS > 0.0
    messenger.writeMessage(290.0)
end
if N_TSAIH > 0.0
    messenger.writeMessage(291.0)
end
if N_TSAIW > 0.0
    messenger.writeMessage(292.0)
end
if N_AZZIT > 0.0
    messenger.writeMessage(293.0)
end
if N_MSTRN > 0.0
    messenger.writeMessage(294.0)
end

%% Write output to file
if (failStress ~= -1.0) || (failStrain ~= -1.0)
    mainIDs = getappdata(0, 'mainID');
    subIDs = getappdata(0, 'subID');
    
    data = [mainIDs'; subIDs'; MSTRS; MSTRN; TSAIW; TSAIW; AZZIT]';
    
    % Print information to file
    root = getappdata(0, 'outputDirectory');
    
    if exist(sprintf('%s/Data Files', root), 'dir') == 0.0
        mkdir(sprintf('%s/Data Files', root))
    end
    
    dir = [root, 'Data Files/composite_criteria.dat'];
    
    fid = fopen(dir, 'w+');
    
    fprintf(fid, 'COMPOSITE FAILURE\r\n');
    fprintf(fid, 'Job:\t%s\r\nLoading:\t%.3g\t%s\r\n', getappdata(0, 'jobName'), getappdata(0, 'loadEqVal'), getappdata(0, 'loadEqUnits'));
    
    fprintf(fid, 'Main ID\tSub ID\tMSTRS\tMSTRN\tTSAIH\tTSAIW\tAZZIT\r\n');
    fprintf(fid, '%.0f\t%.0f\t%f\t%f\t%f\t%f\t%f\r\n', data');
    
    fclose(fid);
    
    messenger.writeMessage(129.0)
end