function [] = compositeFailure(N, L, mainID, fid_status)
%COMPOSITEFAILURE    QFT function to calculate composite failure criteria.
%   This function calculates composite failure criteria according to the
%   maximum stress, Tsai-Hill, Tsai-Wu, Azzi-Tsai-Hill and Hashin criteria.
%   
%   COMPOSITEFAILURE is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%
%   See also LaRC05.
%
%   Reference section in Quick Fatigue Tool User Guide
%      12.3 Composite failure criteria
%
%   Quick Fatigue Tool 6.11-13 Copyright Louis Vallance 2018
%   Last modified 12-Apr-2018 09:52:19 GMT
    
    %%

% Get the number of groups for the analysis
G = getappdata(0, 'numberOfGroups');

% Get the group ID buffer
groupIDBuffer = getappdata(0, 'groupIDBuffer');

% Initialize output variables
MSTRS = linspace(-1.0, -1.0, N);
MSTRN = linspace(-1.0, -1.0, N);
TSAIH = linspace(-1.0, -1.0, N);
TSAIW = linspace(-1.0, -1.0, N);
TSAIWTT = linspace(-1.0, -1.0, N);
k = linspace(-1.0, -1.0, N);
AZZIT = linspace(-1.0, -1.0, N);
HSNFTCRT = linspace(-1.0, -1.0, N);
HSNFCCRT = linspace(-1.0, -1.0, N);
HSNMTCRT = linspace(-1.0, -1.0, N);
HSNMCCRT = linspace(-1.0, -1.0, N);
LARPFCRT = linspace(-1.0, -1.0, N);
LARMFCRT = linspace(-1.0, -1.0, N);
LARKFCRT = linspace(-1.0, -1.0, N);
LARSFCRT = linspace(-1.0, -1.0, N);
LARTFCRT = linspace(-1.0, -1.0, N);

startID = 1.0;
totalCounter = 1.0;

% Get stress tensor
S11 = getappdata(0, 'Sxx');
S22 = getappdata(0, 'Syy');
S33 = getappdata(0, 'Szz');
S12 = getappdata(0, 'Txy');
S13 = getappdata(0, 'Txz');
S23 = getappdata(0, 'Tyz');

% Constant for quadratic formula
C = linspace(-1.0, -1.0, L);

% Check if the symbolic math toolbox is available
symsAvailable = checkToolbox('Symbolic Math Toolbox');

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
    Zt = getappdata(0, 'failStress_tsttd');
    Zc = getappdata(0, 'failStress_csttd');
    S = getappdata(0, 'failStress_shear');
    Fc12 = getappdata(0, 'failStress_cross12');
    Fc23 = getappdata(0, 'failStress_cross23');
    B12 = getappdata(0, 'failStress_limit12');
    B23 = getappdata(0, 'failStress_limit23');
    
    % Get fail strain properties
    Xet = getappdata(0, 'failStrain_tsfd');
    Xec = getappdata(0, 'failStrain_csfd');
    Yet = getappdata(0, 'failStrain_tstd');
    Yec = getappdata(0, 'failStrain_cstd');
    Se = getappdata(0, 'failStrain_shear');
    E11 = getappdata(0, 'failStrain_e11');
    E22 = getappdata(0, 'failStrain_e22');
    G12 = getappdata(0, 'failStrain_g12');
    
    % Get Hashin properties
    alpha = getappdata(0, 'hashin_alpha');
    Xht = getappdata(0, 'hashin_lts');
    Xhc = getappdata(0, 'hashin_lcs');
    Yht = getappdata(0, 'hashin_tts');
    Yhc = getappdata(0, 'hashin_tcs');
    Sl = getappdata(0, 'hashin_lss');
    St = getappdata(0, 'hashin_tss');
    
    % Get LaRC05 properties
    Xlt = getappdata(0, 'larc05_lts');
    Xlc = getappdata(0, 'larc05_lcs');
    Ylt = getappdata(0, 'larc05_tts');
    Ylc = getappdata(0, 'larc05_tcs');
    Sll = getappdata(0, 'larc05_lss');
    Slt = getappdata(0, 'larc05_tss');
    larc_G12 = getappdata(0, 'larc05_shear');
    nl = getappdata(0, 'larc05_nl');
    nt = getappdata(0, 'larc05_nt');
    alpha0 = getappdata(0, 'larc05_alpha0');
    phi0 = getappdata(0, 'larc05_phi0');
    iterate = getappdata(0, 'larc05_iterate');
    step = getappdata(0, 'stepSize');
    
    % Get the master flags for the composite criteria
    [compositeFile_stress, compositeFile_strain, compositeFile_hashin,...
        compositeFile_larc05] = staticOutput.compositeFile();
    
    % Check if there is enough data for maximum stress, Tsai-Hill, Tsai-Wu and Azzi-Tsai-Hill theory
    if (isempty(Xt) == 1.0 || isempty(Xc) == 1.0 || isempty(Yt) == 1.0 || isempty(Yc) == 1.0 || isempty(S) == 1.0) || (compositeFile_stress == 0.0)
        failStressGeneral = -1.0;
    else
        failStressGeneral = 1.0;
    end
    
    % Check if there is enough data for Tsai-Wu (through-thickness)
    if (isempty(Yt) == 1.0 || isempty(Yc) == 1.0 || isempty(Zt) == 1.0 || isempty(Zc) == 1.0) || (compositeFile_stress == 0.0)
        tsaiWuTT = -1.0;
    else
        tsaiWuTT = 1.0;
    end
    
    % Check if there is enough data for fail strain
    if (((isempty(G12) == 1.0 || isempty(E11) == 1.0 || isempty(E22) == 1.0)) ||...
            (isempty(Xet) == 1.0 || isempty(Xec) == 1.0 || isempty(Yet) == 1.0...
            || isempty(Yec) == 1.0 || isempty(Se) == 1.0)) || (compositeFile_strain == 0.0)
        failStrain = -1.0;
    else
        failStrain = 1.0;
    end
    
    % Check if there is enough data for Hashin
    if (isempty(Xht) == 1.0 || isempty(Xhc) == 1.0 || isempty(Yht) == 1.0...
            || isempty(Yhc) == 1.0 || isempty(Sl) == 1.0 || isempty(St) == 1.0) || (compositeFile_hashin == 0.0)
        hashin = -1.0;
    else
        hashin = 1.0;
    end
    
    % Check if there is enough data for LaRC05
    if ((isempty(Xlt) == 1.0 || isempty(Xlc) == 1.0 || isempty(Ylt) == 1.0...
            || isempty(Sll) == 1.0 || isempty(larc_G12) == 1.0 ||...
            isempty(nl) == 1.0) || (isempty(Ylc) == 1.0 && isempty(Slt) == 1.0)) || (compositeFile_larc05 == 0.0)
        larc05 = -1.0;
    else
        larc05 = 1.0;
    end
    
    if failStressGeneral == -1.0 && tsaiWuTT == -1.0 && failStrain == -1.0 && hashin == -1.0 && larc05 == -1.0
        totalCounter = totalCounter + N;
        continue
    end
    
    S11_group = S11(startID:(startID + N) - 1.0, :);
    S22_group = S22(startID:(startID + N) - 1.0, :);
    S33_group = S33(startID:(startID + N) - 1.0, :);
    S12_group = S12(startID:(startID + N) - 1.0, :);
    S13_group = S13(startID:(startID + N) - 1.0, :);
    S23_group = S23(startID:(startID + N) - 1.0, :);
    
    % Remove compressive stresses if ndCompression=1
    if getappdata(0, 'ndCompression') == 1.0
        setappdata(0, 'message_group', groups)
        messenger.writeMessage(131.0)
        
        S11_group(S11_group < 0.0) = 0.0;
        S22_group(S22_group < 0.0) = 0.0;
        S33_group(S33_group < 0.0) = 0.0;
    end
    
    X = zeros(1.0, L);
    Y = zeros(1.0, L);
    
    Xe = zeros(1.0, L);
    Ye = zeros(1.0, L);
    
    % Initialize Tsai-Wu parameters
    if failStressGeneral ~= -1.0
        F1 = (1.0/Xt) + (1.0/Xc);
        F2 = (1.0/Yt) + (1.0/Yc);
        F11 = -(1.0/(Xt*Xc));
        F22 = -(1.0/(Yt*Yc));
        F66 = 1.0/S^2.0;
        
        if (isempty(B12) == 0.0) && (B12 ~= 0.0)
            F12 = (1.0/(2.0*B12^2.0)) * (1.0 - ((1.0/Xt) + (1.0/Xc) + (1.0/Yt) + (1.0/Yc))*(B12) + ((1.0/(Xt*Xc)) + (1.0/(Yt*Yc)))*(B12^2.0));
        else
            F12 = Fc12*sqrt(F11*F22);
        end
    end
    
    % Initialize Tsai-Wu (through-thickness) parameters
    if tsaiWuTT ~= -1.0
        F2 = (1.0/Yt) + (1.0/Yc);
        F3 = (1.0/Zt) + (1.0/Zc);
        F22 = -(1.0/(Yt*Yc));
        F33 = 1.0/(Zt*Zc);
        
        if (isempty(B12) == 0.0) && (B12 ~= 0.0)
            F23 = (1.0/(2.0*B23^2.0)) * (1.0 - ((1.0/Yt) + (1.0/Yc) + (1.0/Zt) + (1.0/Zc))*(B23) + ((1.0/(Yt*Yc)) + (1.0/(Zt*Zc)))*(B23^2.0));
        else
            F23 = Fc23*sqrt(F22*F33);
        end
    end
    
    % Initialize LaRC05 parameters
    if larc05 == 1.0
        S1 = getappdata(0, 'S1');
        S2 = getappdata(0, 'S2');
        S3 = getappdata(0, 'S3');
        
        S1_group = S1(startID:(startID + N) - 1.0, :);
        S2_group = S2(startID:(startID + N) - 1.0, :);
        S3_group = S3(startID:(startID + N) - 1.0, :);
    end
    
    for i = 1:N
        %% Get the stresses at the current item
        S11i = S11_group(i, :);
        S22i = S22_group(i, :);
        S33i = S33_group(i, :);
        S12i = S12_group(i, :);
        S13i = S13_group(i, :);
        S23i = S23_group(i, :);

        %% Check for out-of-plane stress components
        if any(S33i) == 1.0 || any(S13i) == 1.0 || any(S23i) == 1.0
            messenger.writeMessage(132.0)
        end
        
        %% FAIL STRESS CALCULATION
        if failStressGeneral == 1.0
            % Tension-compression split
            X(S11i >= 0.0) = Xt;
            X(S11i < 0.0) = Xc;
            
            Y(S22i >= 0.0) = Yt;
            Y(S22i < 0.0) = Yc;
            
            % Failure calculation (MSTRS)
            MS11 = abs(S11i./X);
            MS22 = abs(S22i./Y);
            MS12 = abs(S12i./S);
            MSTRS(totalCounter) = max(max([MS11; MS22; MS12]));
            
            % Failure calculation (TSAIH)
            TSAIH(totalCounter) = sqrt((max((S11i.^2.0./X.^2.0) - ((S11i.*S22i)./X.^2.0) + (S22i.^2.0./Y.^2.0) + (S12i.^2.0./S.^2.0))));
            
            % Failure calculation (TSAIW)
            A = (F11.*S11i.*S11i) + (F22.*S22i.*S22i) + (F66.*S12i.*S12i) + (2.0.*F12.*S11i.*S22i);
            B = (F1.*S11i) + (F2.*S22i);
            TSAIW(totalCounter) = abs(1.0./min([(-B + sqrt(B.^2.0 - (4.0.*A.*C)))./(2.0.*A), (-B - sqrt(B.^2.0 - (4.0.*A.*C)))./(2.0.*A)]));
            
            % Failure calculation (AZZIT)
            AZZIT(totalCounter) = sqrt(max((S11i.^2.0./X.^2.0) - (abs((S11i.*S22i))/X.^2.0) + (S22i.^2.0./Y.^2.0) + (S12i.^2.0./S.^2.0)));
        end
        
        if tsaiWuTT == 1.0
            k(totalCounter) = max(S12i./S23i);
            
            A = (F22.*S22i.^2.0) + (F33*S33i.^2.0) + (2.0.*F23.*S22i.*S33i);
            B = (F2.*S22i) + (F3.*S33i);
            C2 = (S12i./S23i).^2 - 1.0;
            TSAIWTT(totalCounter) = abs(1.0./min([(-B + sqrt(B.^2.0 - (4.0.*A.*C2)))./(2.0.*A), (-B - sqrt(B.^2.0 - (4.0.*A.*C2)))./(2.0.*A)]));
        end
        
        %% FAIL STRAIN CALCULATION
        if failStrain ~= -1.0          
            E11i = S11i./E11;
            E22i = S22i./E22;
            E12i = S12i./G12;
            
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
        
        %% HASHIN CALCULATION
        if hashin == 1.0
            % Mode I/II
            S11Pos = S11i >= 0.0;
            S11Neg = S11i < 0.0;
            
            if any(S11Pos) == 0.0
                HSNFTCRT(totalCounter) = 0.0;
            else
                HSNFTCRT(totalCounter) = max((S11i(S11Pos)./ Xht).^2.0 + alpha.*(S12i(S11Pos) ./ Sl).^2.0);
            end
            if any(S11Neg) == 0.0
                HSNFCCRT(totalCounter) = 0.0;
            else
                HSNFCCRT(totalCounter) = max((S11i(S11Neg) ./ Xhc).^2.0);
            end
            
            % Mode III/IV
            S22Pos = S22i >= 0.0;
            S22Neg = S22i < 0.0;
            
            if any(S22Pos) == 0.0
                HSNMTCRT(totalCounter) = 0.0;
            else
                HSNMTCRT(totalCounter) = max((S22i(S22Pos) ./ Yht).^2.0 + (S12i(S22Pos) ./ Sl).^2.0);
            end
            if any(S22Neg) == 0.0
                HSNMCCRT(totalCounter) = 0.0;
            else
                HSNMCCRT(totalCounter) = max((S22i(S22Neg) ./ (2.0*St)).^2.0 + ((Yhc ./ (2.0.*St)).^2.0 - 1.0).*(S22i(S22Neg) ./ Yhc) + (S12i(S22Neg) ./ Sl).^2.0);
            end
        end
        
        %% LARC05 CALCULATION
        if larc05 == 1.0
            S1i = S1_group(i, :);
            S2i = S2_group(i, :);
            S3i = S3_group(i, :);
            
            [LARPFCRT, LARMFCRT, LARKFCRT, LARSFCRT, LARTFCRT] =...
                LaRC05(S11i, S22i, S33i, S12i, S13i, S23i, S1i, S2i, S3i,...
                larc_G12, Xlt, Xlc, Ylt, Ylc, Sll, Slt, alpha0, phi0, nl, nt,...
                LARPFCRT, LARMFCRT, LARKFCRT, LARSFCRT, LARTFCRT,...
                totalCounter, symsAvailable, step, iterate);
        end
        
        %% UPDATE COUNTER
        totalCounter = totalCounter + 1.0;
    end
    
    % Update the start ID
    startID = startID + N;
end

%% Remove INF values of K
k(isinf(k)) = 0.0;

%% Remove negative HSNMCCRT values
if hashin == 1.0
    HSNMCCRT(HSNMCCRT < 0.0) = 0.0;
end

%% Round failure measures to 1 if within tolerance
MSTRS(abs(MSTRS - 1.0) < 1e-6) = 1.0;
MSTRN(abs(MSTRN - 1.0) < 1e-6) = 1.0;
TSAIH(abs(TSAIH - 1.0) < 1e-6) = 1.0;
TSAIW(abs(TSAIW - 1.0) < 1e-6) = 1.0;
TSAIWTT(abs(TSAIWTT - 1.0) < 1e-6) = 1.0;
AZZIT(abs(AZZIT - 1.0) < 1e-6) = 1.0;
HSNFTCRT(abs(HSNFTCRT - 1.0) < 1e-6) = 1.0;
HSNFCCRT(abs(HSNFCCRT - 1.0) < 1e-6) = 1.0;
HSNMTCRT(abs(HSNMTCRT - 1.0) < 1e-6) = 1.0;
HSNMCCRT(abs(HSNMCCRT - 1.0) < 1e-6) = 1.0;
LARPFCRT(abs(LARPFCRT - 1.0) < 1e-6) = 1.0;
LARMFCRT(abs(LARMFCRT - 1.0) < 1e-6) = 1.0;
LARKFCRT(abs(LARKFCRT - 1.0) < 1e-6) = 1.0;
LARSFCRT(abs(LARSFCRT - 1.0) < 1e-6) = 1.0;
LARTFCRT(abs(LARTFCRT - 1.0) < 1e-6) = 1.0;

%% Round failure measures to 0 if within tolerance
MSTRS(abs(MSTRS) < 1e-6) = 0.0;
MSTRN(abs(MSTRN) < 1e-6) = 0.0;
TSAIH(abs(TSAIH) < 1e-6) = 0.0;
TSAIW(abs(TSAIW) < 1e-6) = 0.0;
TSAIWTT(abs(TSAIWTT) < 1e-6) = 0.0;
AZZIT(abs(AZZIT) < 1e-6) = 0.0;
HSNFTCRT(abs(HSNFTCRT) < 1e-6) = 0.0;
HSNFCCRT(abs(HSNFCCRT) < 1e-6) = 0.0;
HSNMTCRT(abs(HSNMTCRT) < 1e-6) = 0.0;
HSNMCCRT(abs(HSNMCCRT) < 1e-6) = 0.0;
LARPFCRT(abs(LARPFCRT) < 1e-6) = 0.0;
LARMFCRT(abs(LARMFCRT) < 1e-6) = 0.0;
LARKFCRT(abs(LARKFCRT) < 1e-6) = 0.0;
LARSFCRT(abs(LARSFCRT) < 1e-6) = 0.0;
LARTFCRT(abs(LARTFCRT) < 1e-6) = 0.0;

%% Get whole model model summary for message file
mainIDs = getappdata(0, 'mainID');
subIDs = getappdata(0, 'subID');

[N_MSTRS, N_MSTRN, N_TSAIH, N_TSAIW, N_TSAIWTT, N_AZZIT, N_HSNFTCRT,...
    N_HSNFCCRT, N_HSNMTCRT, N_HSNMCCRT, N_LARPFCRT, N_LARMFCRT,...
    N_LARKFCRT, N_LARSFCRT, N_LARTFCRT] =...
    staticOutput.getCompositeSummary(MSTRS, MSTRN, TSAIH, TSAIW,...
    TSAIWTT, AZZIT, HSNFTCRT, HSNFCCRT, HSNMTCRT, HSNMCCRT, LARPFCRT,...
    LARMFCRT, LARKFCRT, LARSFCRT, LARTFCRT, k, failStressGeneral,...
    tsaiWuTT, failStrain, hashin, larc05, mainIDs, subIDs);

%% Report results summary to the message file
messenger.writeMessage(315.0)

%% Write output to file
if (failStressGeneral ~= -1.0) || (tsaiWuTT ~= -1.0) || (failStrain ~= -1.0) || (hashin ~= -1.0) || (larc05 ~= -1.0)
    % Check if there is failure 
    FAIL_ALL = [N_MSTRS, N_TSAIH, N_TSAIW, N_TSAIWTT, N_AZZIT, N_MSTRN, N_HSNFTCRT, N_HSNFCCRT, N_HSNMTCRT, N_HSNMCCRT, N_LARPFCRT, N_LARMFCRT, N_LARKFCRT, N_LARSFCRT, N_LARTFCRT];
    if any(FAIL_ALL) == 0.0
        messenger.writeMessage(301.0)
    end
    
    data = [mainIDs'; subIDs'; MSTRS; MSTRN; TSAIH; TSAIW; TSAIWTT; AZZIT; HSNFTCRT; HSNFCCRT; HSNMTCRT; HSNMCCRT; LARPFCRT; LARMFCRT; LARKFCRT; LARSFCRT; LARTFCRT]';
    
    % Print information to file
    root = getappdata(0, 'outputDirectory');
    
    if exist(sprintf('%s/Data Files', root), 'dir') == 0.0
        mkdir(sprintf('%s/Data Files', root))
    end
    
    dir = [root, 'Data Files/composite_criteria.dat'];
    
    fid = fopen(dir, 'w+');
    
    fprintf(fid, 'COMPOSITE ASSESSMENT RESULTS\r\n');
    fprintf(fid, 'Job:\t%s\r\nLoading:\t%.3g\t%s\r\n', getappdata(0, 'jobName'), getappdata(0, 'loadEqVal'), getappdata(0, 'loadEqUnits'));
    
    fprintf(fid, 'Main ID\tSub ID\tMSTRS\tMSTRN\tTSAIH\tTSAIW\tTSAIWTT\tAZZIT\tHSNFTCRT\tHSNFCCRT\tHSNMTCRT\tHSNMCCRT\tLARPFCRT\tLARMFCRT\tLARKFCRT\tLARSFCRT\tLARTFCRT\r\n');
    fprintf(fid, '%.0f\t%.0f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\t%f\r\n', data');
    
    fclose(fid);
    
    messenger.writeMessage(129.0)
    
    %% Write results to ODB if applicable
    if getappdata(0, 'autoExport_ODB') == 1.0
        if getappdata(0, 'autoExport_uniaxial') == 1.0
            messenger.writeMessage(203.0)
        else
            staticOutput.exportODB(fid_status, mainID, 2.0)
        end
    end
else
    messenger.writeMessage(300.0)
end

%% Update .msg file
messenger.writeMessage(127.0)