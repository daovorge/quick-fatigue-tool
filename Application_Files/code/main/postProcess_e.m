classdef postProcess_e < handle
%POSTPROCESS_E    QFT class for post-analysis processing (strain-based).
%   
%   POSTPROCESS_E is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%
%   See also postProcess.
%
%   Reference section in Quick Fatigue Tool User Guide
%      10 Output
%   
%   Quick Fatigue Tool 6.11-12 Copyright Louis Vallance 2018
%   Last modified 04-Mar-2018 19:58:22 GMT
    
    %%
    
    methods(Static = true)
        %% Get the worst cycle amplitude and mean
        function [] = getWorstCycleMeanAmp()
            N = getappdata(0, 'numberOfNodes');
            
            nodalCycles_stress = getappdata(0, 'nodalPairs');
            nodalCycles_strain = getappdata(0, 'nodalPairs_strain');
            
            nodalAmps_stress = getappdata(0, 'nodalAmplitudes');
            nodalAmps_strain = getappdata(0, 'nodalAmplitudes_strain');
            
            WCM = zeros(1.0, N);
            WCA = zeros(1.0, N);
            
            for i = 1:N
                % Get cycles and amplitudes for current item
                cycles = nodalCycles_stress{i};
                amps = nodalAmps_stress{i};
                
                if length(amps) == 1.0
                    % There is only one cycle
                    WCA(i) = amps;
                    WCM(i) = 0.5*(cycles(1.0) + cycles(2.0));
                else
                    % Search for the maximum cycle
                    WCA(i) = max(amps);
                    
                    indexOfSa = find(amps == max(amps));
                    indexOfSaL = length(indexOfSa);
                    
                    %{
                        If there is more than one amplitude then find the cycle
                        with the largest mean stress
                    %}
                    
                    if indexOfSaL > 1.0
                        % The maximum amplitude belongs to more than one cycle
                        means = 0.5*(cycles(indexOfSa(:), 1.0) + cycles(indexOfSa(:), 2.0));
                        WCM(i) = max(means);
                    else
                        WCM(i) = 0.5*(cycles(indexOfSa, 1.0) + cycles(indexOfSa, 2.0));
                    end
                end
            end
            setappdata(0, 'WCA', WCA)
            setappdata(0, 'WCM', WCM)
            
            WCM_strain = zeros(1.0, N);
            WCA_strain = zeros(1.0, N);
            
            for i = 1:N
                % Get cycles and amplitudes for current item
                cycles = nodalCycles_strain{i};
                amps = nodalAmps_strain{i};
                
                if length(amps) == 1.0
                    % There is only one cycle
                    WCA_strain(i) = amps;
                    WCM_strain(i) = 0.5*(cycles(1.0) + cycles(2.0));
                else
                    % Search for the maximum cycle
                    WCA_strain(i) = max(amps);
                    
                    indexOfSa = find(amps == max(amps));
                    indexOfSaL = length(indexOfSa);
                    
                    %{
                        If there is more than one amplitude then find the cycle
                        with the largest mean stress
                    %}
                    
                    if indexOfSaL > 1.0
                        % The maximum amplitude belongs to more than one cycle
                        means = 0.5*(cycles(indexOfSa(:), 1.0) + cycles(indexOfSa(:), 2.0));
                        WCM_strain(i) = max(means);
                    else
                        WCM_strain(i) = 0.5*(cycles(indexOfSa, 1.0) + cycles(indexOfSa, 2.0));
                    end
                end
            end
            setappdata(0, 'WCA_strain', WCA_strain)
            setappdata(0, 'WCM_strain', WCM_strain)
            
            % Get mean stress for each cycle
            cycles = getappdata(0, 'cyclesOnCP');
            Sm = 0.5*(cycles(:, 1.0) + cycles(:, 2.0));
            setappdata(0, 'meansOnCP', Sm)
            setappdata(0, 'numberOfCycles', length(Sm))
            
            % Get mean strain for each cycle
            cycles = getappdata(0, 'cyclesOnCP_strain');
            Em = 0.5*(cycles(:, 1.0) + cycles(:, 2.0));
            setappdata(0, 'meansOnCP_strain', Em)
        end
        
        %% Get field output from analysis:
        function [] = getFields(algorithm, msCorrection, gateTensors, tensorGate, coldItems, fid_status)
            %% Get commonly used variables
            % Basic fatigue
            use_sn = getappdata(0, 'useSN');
            
            % Worst analysis item
            worstItem = getappdata(0, 'worstItem');
            
            % Signal length
            L = getappdata(0, 'signalLength');
            
            N = getappdata(0, 'numberOfNodes');
            mainID = getappdata(0, 'mainID_master');
            subID = getappdata(0, 'subID_master');
            
            mainID_original = getappdata(0, 'mainID_original');
            subID_original = getappdata(0, 'subID_original');
            
            mainID_field = getappdata(0, 'mainID_groupAll');
            subID_field = getappdata(0, 'subID_groupAll');
            
            if (getappdata(0, 'numberOfGroups') == 1.0) || (isempty(mainID_field) == 1.0) || (isempty(subID_field) == 1.0)
                mainID_field = mainID;
                subID_field = subID;
            else
                mainID_field = getappdata(0, 'mainID_groupAll');
                subID_field = getappdata(0, 'subID_groupAll');
            end
            
            %% FOS (Factor of Strength)
            %{
                The FOS calculation can be time consuming. Only perform FOS
                iterations if requested by the uesr
            %}
            
            if getappdata(0, 'enableFOS') == 1.0
                fos(gateTensors, tensorGate, coldItems, algorithm, msCorrection, N, L, mainID, subID, fid_status)
            end
            
            %% FRF (Fatigue Reserve Factor)
            %{
                Obtain the largest cycle from the critical plane
                
                -> If the history is only 2 points, then there is one cycle
                -> If the history is greater than 2 points, search for the
                   largest cycle
            %}
            frf(algorithm, msCorrection, N, mainID, subID, use_sn)
            
            %% SMAX (Largest stress in loading)
            
            if getappdata(0, 'skipMaximumStressCalculation') == 0.0
                postProcess.getMaximumStress();

                SMAX_ABS = getappdata(0, 'SMAX');
                hydroStress = getappdata(0, 'hydrostaticStress');
                
                %% GET THE NORMALIZED STRESS COMPONENTS
                normStress(SMAX_ABS, mainID_original, subID_original)
            else
                hydroStress = getappdata(0, 'hydrostaticStress');
            end
            
            %% WCA (Worst cycle amplitude)
            
            % Get the worst mean strain for each item in the model
            WCA = getappdata(0, 'WCA_strain');
            
            % Find the maximum value of the worst mean strain in the model
            WCA_ABS = max(WCA);
            
            % If there is more than one value, take the first value
            WCA_ABS = WCA_ABS(1.0);
            
            % Get the item ID for this value of mean stress
            WCA_item = find(WCA == WCA_ABS);
            
            % If there is more than one value
            if any(WCA_item == worstItem) == 1.0
                WCA_item = worstItem;
            else
                WCA_item = WCA_item(1.0);
            end
            
            % Save the variables to the APPDATA
            setappdata(0, 'WCA_ABS', WCA_ABS)
            
            setappdata(0, 'WCA_mainID', mainID_field(WCA_item))
            setappdata(0, 'WCA_subID', subID_field(WCA_item))
            
            %% WCM (Worst cycle mean strain)
            
            % Get the worst mean stress for each item in the model
            WCM = getappdata(0, 'WCM_strain');
            
            % Find the maximum value of the worst mean strain in the model
            WCM_ABS = max(WCM);
            
            % If there is more than one value, take the first value
            WCM_ABS = WCM_ABS(1.0);
            
            % Get the item ID for this value of mean stress
            WCM_item = find(WCM == WCM_ABS);
            
            % If there is more than one value
            if any(WCM_item == worstItem) == 1.0
                WCM_item = worstItem;
            else
                WCM_item = WCM_item(1.0);
            end
            
            % Save the variables to the APPDATA
            setappdata(0, 'WCM_ABS', WCM_ABS)
            setappdata(0, 'WCM_mainID', mainID_field(WCM_item))
            setappdata(0, 'WCM_subID', subID_field(WCM_item))
            
            %% WCDP (Damage parameter)
            
            %{
                This variable was already saved to the appdata immediately
                after the critical plane search
            %}
            
            % Get the worst damage parameter for each item in the model
            WCDP = getappdata(0, 'WCDP');
            
            % Find the maximum value of the worst parameter in the model
            WCDP_ABS = max(WCDP);
            
            % If there is more than one value, take the first value
            WCDP_ABS = WCDP_ABS(1.0);
            
            % Get the item ID for this value of the damage parameter
            WCDP_item = find(WCDP == WCDP_ABS);
            
            % If there is more than one value
            if any(WCDP_item == worstItem) == 1.0
                WCDP_item = worstItem;
            else
                WCDP_item = WCDP_item(1.0);
            end
            
            % Save the variables to the APPDATA
            setappdata(0, 'WCDP_ABS', WCDP_ABS)
            setappdata(0, 'WCDP_mainID', mainID_field(WCDP_item))
            setappdata(0, 'WCDP_subID', subID_field(WCDP_item))
            
            %% TRF (Triaxiality Factor)
            
            % Get von Mises stress
            vonMises = getappdata(0, 'VM');
            
            % Total counter
            totalCounter = 0.0;
            
            % Initialize variable
            triaxialityFactor = zeros(1.0, N);
            
            % Get the von Mises stress history for each analysis item
            for i = 1.0:N
                totalCounter = totalCounter + 1.0;
                
                % Get the triaxiality factors at the current analysis item
                triaxialityFactors = hydroStress(totalCounter, :)./vonMises(totalCounter, :);
                
                % Get the maximum triaxiality factor in the loading at the current analysis item
                triaxialityFactor(totalCounter) = max(triaxialityFactors);
            end
            
            setappdata(0, 'TRF', triaxialityFactor)
            
            % Warn the user if any parts of the model are in a state of pure triaxial tension/compression
            if any(triaxialityFactor > 2.0) == 1.0
                messenger.writeMessage(307.0)
            end
        end
        
        %% Write field output to file:
        function [] = exportFields(loadEqUnits, coldItems)
            % Field output format string
            f = getappdata(0, 'fieldFormatString');
            
            %{
                FIELDS -> Single value per item
            %}
            
            if (getappdata(0, 'numberOfNodes') ~= length(getappdata(0, 'mainID_groupAll'))) || (getappdata(0, 'numberOfGroups') == 1.0)
                mainID = getappdata(0, 'mainID');
                subID = getappdata(0, 'subID');
            else
                mainID = getappdata(0, 'mainID_groupAll');
                subID = getappdata(0, 'subID_groupAll');
            end
            
            [r, ~] = size(mainID);
            if r == 1.0
                mainID = mainID';
            end
            [r, ~] = size(subID);
            if r == 1.0
                subID = subID';
            end
            
            LL = getappdata(0, 'LL');
            [~, N] = size(LL);
            D = getappdata(0, 'D');
            DDL = D*getappdata(0, 'dLife');
            L = D.^-1.0;
            if getappdata(0, 'enableFOS') == 1.0
                FOS = getappdata(0, 'FOS');
            else
                FOS = linspace(-1.0, -1.0, N);
            end
            FRFR = getappdata(0, 'FRFR');
            FRFH = getappdata(0, 'FRFH');
            FRFV = getappdata(0, 'FRFV');
            FRFW = getappdata(0, 'FRFW');
            SMAX = getappdata(0, 'SMAX');
            SMXP = getappdata(0, 'SMXP');
            SMXU = getappdata(0, 'SMXU');
            TRF = getappdata(0, 'TRF');
            WCM = getappdata(0, 'WCM_strain');
            WCA = getappdata(0, 'WCA_strain');
            WCDP = getappdata(0, 'WCDP');
            SFA = getSFA(WCA, WCDP, N);
            WCATAN = atand(WCM./WCA);
            WCATAN(isnan(WCATAN) == 1.0) = 90.0;
            YIELD = getappdata(0, 'YIELD');
            
            data = [mainID'; subID'; L; LL; D; DDL; FOS; SFA; FRFR; FRFH; FRFV; FRFW; SMAX; SMXP; SMXU; TRF; WCM; WCA; WCATAN; WCDP; YIELD]';
            
            %% Open file for writing:
            
            if getappdata(0, 'file_F_OUTPUT_ALL') == 1.0
                dir = [getappdata(0, 'outputDirectory'), 'Data Files/f-output-all.dat'];
                
                fid = fopen(dir, 'w+');
                
                fprintf(fid, 'FIELDS [WHOLE MODEL]\r\nJob:\t%s\r\nLoading:\t%.3g\t%s\r\n', getappdata(0, 'jobName'), getappdata(0, 'loadEqVal'), getappdata(0, 'loadEqUnits'));
                
                fprintf(fid, 'Main ID\tSub ID\tL (%s)\tLL (%s)\tD\tDDL\tFOS\tSFA\tFRFR\tFRFH\tFRFV\tFRFW\tSMAX (MPa)\tSMXP\tSMXU\tTRF\tWCM (Strain)\tWCA (Strain)\tWCATAN (Deg)\tWCDP (Strain)\tYIELD\r\n', loadEqUnits, loadEqUnits);
                fprintf(fid, sprintf('%%.0f\t%%.0f\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%.0f\r\n',...
                    f, f, f, f, f, f, f, f, f, f, f, f, f, f, f, f, f, f), data');
                
                fclose(fid);
            end
            
            %% Additional field output if nodal elimination removed more than 50% of the items
            
            if getappdata(0, 'file_F_OUTPUT_ANALYSED') == 1.0
                if getappdata(0, 'separateFieldOutput') == 1.0
                    dir = [getappdata(0, 'outputDirectory'), 'Data Files/f-output-analysed.dat'];
                    
                    fid = fopen(dir, 'w+');
                    
                    fprintf(fid, 'FIELDS [ANALYSED ITEMS ONLY]\r\nJob:\t%s\r\nLoading:\t%.3g\t%s\r\n', getappdata(0, 'jobName'), getappdata(0, 'loadEqVal'), getappdata(0, 'loadEqUnits'));
                    
                    mainID_i = zeros(1, length(mainID) - length(coldItems));
                    subID_i = mainID_i;
                    L_i = mainID_i;
                    LL_i = mainID_i;
                    D_i = mainID_i;
                    DDL_i = mainID_i;
                    FOS_i = mainID_i;
                    SFA_i = mainID_i;
                    FRFR_i = mainID_i;
                    FRFH_i = mainID_i;
                    FRFV_i = mainID_i;
                    FRFW_i = mainID_i;
                    SMAX_i = mainID_i;
                    SMXP_i = mainID_i;
                    SMXU_i = mainID_i;
                    TRF_i = mainID_i;
                    WCM_i = mainID_i;
                    WCA_i = mainID_i;
                    WCATAN_i = mainID_i;
                    WCDP_i = mainID_i;
                    YIELD_i = mainID_i;
                    j = 1.0;
                    for i = 1:length(mainID)
                        if j > length(mainID_i)
                            break
                        end
                        
                        if any(i == coldItems) == 0.0
                            mainID_i(j) = mainID(i);
                            subID_i(j) = subID(i);
                            L_i(j) = L(i);
                            LL_i(j) = LL(i);
                            D_i(j) = D(i);
                            DDL_i(j) = DDL(i);
                            FOS_i(j) = FOS(i);
                            SFA_i(j) = SFA(i);
                            FRFR_i(j) = FRFR(i);
                            FRFH_i(j) = FRFH(i);
                            FRFV_i(j) = FRFV(i);
                            FRFW_i(j) = FRFW(i);
                            SMAX_i(j) = SMAX(i);
                            SMXP_i(j) = SMXP(i);
                            SMXU_i(j) = SMXU(i);
                            TRF_i(j) = TRF(i);
                            WCM_i(j) = WCM(i);
                            WCA_i(j) = WCA(i);
                            WCATAN_i(j) = WCATAN(i);
                            WCDP_i(j) = WCDP(i);
                            YIELD_i(j) = YIELD(i);
                            
                            j = j + 1.0;
                        end
                    end
                    
                    data_i = [mainID_i; subID_i; L_i; LL_i; D_i; DDL_i; FOS_i; SFA_i; FRFR_i; FRFH_i; FRFV_i; FRFW_i; SMAX_i; SMXP_i; SMXU_i; TRF_i; WCM_i; WCA_i; WCATAN_i; WCDP_i; YIELD_i]';
                    
                    fprintf(fid, 'Main ID\tSub ID\tL (%s)\tLL (%s)\tD\tDDL\tFOS\tSFA\tFRFR\tFRFH\tFRFV\tFRFW\tSMAX (MPa)\tSMXP\tSMXU\tTRF\tWCM (Strain)\tWCA (Strain)\tWCATAN (Deg)\tWCDP (Strain)\tYIELD\r\n', loadEqUnits, loadEqUnits);
                    fprintf(fid, sprintf('%%.0f\t%%.0f\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%.0f\r\n',...
                    f, f, f, f, f, f, f, f, f, f, f, f, f, f, f, f, f, f), data_i');
                    
                    fclose(fid);
                end
            end
        end
        
        %% Get history output from analysis:
        function [] = getHistories(algorithm, loadEqUnits, outputField, outputFigure, damageParameter, damageParameter_strain)
            figureFormat = getappdata(0, 'figureFormat');
            
            root = getappdata(0, 'outputDirectory');
            
            midnightBlue = [25/255, 25/255, 112/255];
            fireBrick =  [178/255, 34/255, 34/255];
            forestGreen = [34/255, 139/255, 34/255];
            lineWidth = getappdata(0, 'defaultLineWidth');
            fontX = getappdata(0, 'defaultFontSize_XAxis');
            fontY = getappdata(0, 'defaultFontSize_YAxis');
            fontTitle = getappdata(0, 'defaultFontSize_Title');
            fontTicks = getappdata(0, 'defaultFontSize_Ticks');
            XTickPartition = getappdata(0, 'XTickPartition');
            gridLines = getappdata(0, 'gridLines');

            mainID = getappdata(0, 'worstMainID');
            subID = getappdata(0, 'worstSubID');
            
            % Get the worst analysis item
            worstItem = getappdata(0, 'worstItem');
            
            % Get amplitudes
            amplitudes = getappdata(0, 'amplitudesOnCP');
            
            L = getappdata(0, 'signalLength');
            
            % Figure visibility
            figureVisibility = getappdata(0, 'figureVisibility');
            
            %% Get the worst cycle mean stress and stress amplitude (WCM and WCA)

            %% ANHD (Worst cycle Haigh diagram)
            
            if outputField == 1.0 && outputFigure == 1.0
                if getappdata(0, 'figure_ANHD') == 1.0
                    WCA = getappdata(0, 'WCA');
                    WCM = getappdata(0, 'WCM');
                    
                    f1 = figure('visible', figureVisibility);
                    subplot(1.0, 2.0, 1.0)
                    scatter(WCM, WCA, 40, 'MarkerEdgeColor', [0 0.5 0.5],...
                        'MarkerFaceColor', [0 0.7 0.7], 'LineWidth', 1.5)
                    
                    hold on
                    if min(WCM) == max(WCM)
                        if max(WCA) == 0.0
                            plot(linspace(-max(WCM), 0.0, 2.0), linspace(max(WCM), 0.0, 2.0), '-.k', 'lineWidth', 1.0);
                            plot(linspace(0.0, max(WCM), 2.0), linspace(0.0, max(WCM), 2.0), '-.k', 'lineWidth', 1.0);
                        else
                            plot(linspace(-max(WCA), 0.0, 2.0), linspace(max(WCA), 0.0, 2.0), '-.k', 'lineWidth', 1.0);
                            plot(linspace(0.0, max(WCA), 2.0), linspace(0.0, max(WCA), 2.0), '-.k', 'lineWidth', 1.0);
                        end
                    else
                        if max(WCM) < 0.0
                            plot(linspace(min(WCM), 0.0, 2.0), linspace(-min(WCM), 0.0, 2.0), '-.k', 'lineWidth', 1.0);
                            plot(linspace(0.0, -min(WCM), 2.0), linspace(0.0, -min(WCM), 2.0), '-.k', 'lineWidth', 1.0);
                        elseif max(WCM) == 0.0
                            plot(linspace(min(WCM), 0.0, 2.0), linspace(-min(WCM), 0.0, 2.0), '-.k', 'lineWidth', 1.0);
                            plot(linspace(0.0, -min(WCM), 2.0), linspace(0.0, -min(WCM), 2.0), '-.k', 'lineWidth', 1.0);
                        else
                            plot(linspace(-max(WCM), 0.0, 2.0), linspace(max(WCM), 0.0, 2.0), '-.k', 'lineWidth', 1.0);
                            plot(linspace(0.0, max(WCM), 2.0), linspace(0.0, max(WCM), 2.0), '-.k', 'lineWidth', 1.0);
                        end
                    end
                    
                    if max(WCA) == 0.0
                        p2 = line([0.0, 0.0], [0.0, abs(max(WCM))], 'lineWidth', 1.0);
                    else
                        p2 = line([0.0, 0.0], [0.0, max(WCA)], 'lineWidth', 1.0);
                    end
                    
                    set(p2, 'Color', 'k', 'lineStyle', '-.')
                    
                    try
                        axis tight
                    catch
                        % Don't tighten the axis
                    end
                    
                    xlabel('Mean stress [MPa]', 'FontSize', fontX)
                    ylabel('Stress amplitude [MPa]', 'FontSize', fontY)
                    title('ANHD, Haigh diagram for all items', 'FontSize', fontTitle)
                    set(gca, 'FontSize', fontTicks)
                    if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
                        grid on
                    end
                end
                
                %% HD (Haigh diagram for critical plane)
                
                % Get mean stress for each cycle
                cycles = getappdata(0, 'cyclesOnCP');
                Sm = 0.5*(cycles(:, 1.0) + cycles(:, 2.0));
                setappdata(0, 'numberOfCycles', length(Sm))
                setappdata(0, 'meansOnCP', Sm)
                
                if getappdata(0, 'figure_HD') == 1.0
                    if outputFigure == 1.0
                        if algorithm == 10.0
                            msg = sprintf('HD, Haigh diagram for item %.0f.%.0f', mainID, subID);
                            figureTitle = 'MATLAB Figures/ANHD + HD, Haigh diagram for all items';
                        else
                            msg = sprintf('HD, Haigh diagram on critical plane for item %.0f.%.0f', mainID, subID);
                            figureTitle = 'MATLAB Figures/ANHD + HD, Haigh diagram for all items and critical plane';
                        end
                        
                        subplot(1.0, 2.0, 2.0)
                        scatter(Sm, amplitudes, 40, 'MarkerEdgeColor', [0.5 0 0.5],...
                            'MarkerFaceColor', [0.7 0 0.7], 'LineWidth', 1.5)
                        
                        xlabel('Mean stress [MPa]', 'FontSize', fontX)
                        title(msg, 'FontSize', fontTitle)
                        set(gca, 'FontSize', fontTicks)
                        
                        try
                            axis tight
                        catch
                            % Don't tighten the axis
                        end
                        
                        if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
                            grid on
                        end
                        
                        dir = [root, figureTitle];
                        saveas(f1, dir, figureFormat)
                        if strcmpi(figureFormat, 'fig') == true
                            postProcess.makeVisible([dir, '.fig'])
                        end
                    end
                end
            end
            
            %% VM (von Mises elastic stress at worst item)
            
            vonMises = getappdata(0, 'VM');
            vonMises = vonMises(worstItem, :);
            
            setappdata(0, 'WNVM', vonMises)
                
            if  getappdata(0, 'figure_VM') == 1.0 && outputFigure == 1.0
                f3 = figure('visible', figureVisibility);
                
                plot(vonMises, '-', 'LineWidth', lineWidth, 'Color', midnightBlue)
                
                msg = sprintf('VM, von Mises elastic stress for item %.0f.%.0f', mainID, subID);
                xlabel('Sample', 'FontSize', fontX)
                ylabel('von Mises Stress [MPa]', 'FontSize', fontY)
                title(msg, 'FontSize', fontTitle)
                set(gca, 'FontSize', fontTicks)
                set(gca, 'XTick', linspace(1.0, L, XTickPartition + 1.0))
                set(gca, 'XTickLabel', round(linspace(1.0, L, XTickPartition + 1.0))); 
                
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                
                if strcmpi(gridLines, 'on') == 1.0 || gridLines == 1.0
                    grid on
                end
                
                dir = [root, 'MATLAB Figures/VM, von Mises elastic stress at worst item'];
                saveas(f3, dir, figureFormat)
                if strcmpi(figureFormat, 'fig') == true
                    postProcess.makeVisible([dir, '.fig'])
                end
            end
            
            %% PS1 (Maximum elastic principal stress at worst item)
            worstItem = getappdata(0, 'worstItem');
            s1 = getappdata(0, 'S1');
            s1 = s1(worstItem, :);
            s2 = getappdata(0, 'S2');
            s2 = s2(worstItem, :);
            s3 = getappdata(0, 'S3');
            s3 = s3(worstItem, :);
            
            setappdata(0, 'WNPS1', s1)
            setappdata(0, 'WNPS2', s2)
            setappdata(0, 'WNPS3', s3)
            
            if getappdata(0, 'figure_PS') == 1.0 && outputFigure == 1.0
                f4 = figure('visible', figureVisibility);
                subplot(3.0, 1.0, 1.0)
                plot(s1, '-', 'LineWidth', lineWidth, 'Color', midnightBlue)

                msg = sprintf('PS1, Maximum elastic principal stress for item %.0f.%.0f', mainID, subID);
                ylabel('Stress [MPa]', 'FontSize', fontY)
                title(msg, 'FontSize', fontTitle)
                set(gca, 'FontSize', fontTicks)
                set(gca, 'XTick', linspace(1.0, L, XTickPartition + 1.0))
                set(gca, 'XTickLabel', round(linspace(1.0, L, XTickPartition + 1.0))); 
                
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                
                if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
                    grid on
                end

                %% PS2 (Middle elastic principal stress at worst item)
                
                subplot(3, 1, 2)
                plot(s2, '-', 'LineWidth', lineWidth, 'Color', midnightBlue)
                
                msg = sprintf('PS2, Middle elastic principal stress for item %.0f.%.0f', mainID, subID);
                ylabel('Stress [MPa]', 'FontSize', fontY)
                title(msg, 'FontSize', fontTitle)
                set(gca, 'FontSize', fontTicks)
                set(gca, 'XTick', linspace(1.0, L, XTickPartition + 1.0))
                set(gca, 'XTickLabel', round(linspace(1.0, L, XTickPartition + 1.0))); 
                
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                
                if strcmpi(gridLines, 'on') == 1.0 || gridLines == 1.0
                    grid on
                end
                
                %% PS3 (Minimum elastic principal stress at worst item)
                
                subplot(3.0, 1.0, 3.0)
                plot(s3, '-', 'LineWidth', lineWidth, 'Color', midnightBlue)
                
                msg = sprintf('PS3, Minimum elastic principal stress for item %.0f.%.0f', mainID, subID);
                xlabel('Sample', 'FontSize', fontX)
                ylabel('Stress [MPa]', 'FontSize', fontY)
                title(msg, 'FontSize', fontTitle)
                set(gca, 'FontSize', fontTicks)
                set(gca, 'XTick', linspace(1.0, L, XTickPartition + 1.0))
                set(gca, 'XTickLabel', round(linspace(1.0, L, XTickPartition + 1.0))); 
                
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                
                if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
                    grid on
                end
                
                dir = [root, 'MATLAB Figures/PS, Elastic principal stresses at worst item'];
                saveas(f4, dir, figureFormat)
                if strcmpi(figureFormat, 'fig') == true
                    postProcess.makeVisible([dir, '.fig'])
                end
            end
            
            %% PE1 (Maximum inelastic principal strain at worst item)
            e1 = getappdata(0, 'E1');
            e1 = e1(worstItem, :);
            e2 = getappdata(0, 'E2');
            e2 = e2(worstItem, :);
            e3 = getappdata(0, 'E3');
            e3 = e3(worstItem, :);
            
            setappdata(0, 'WNPE1', e1)
            setappdata(0, 'WNPE2', e2)
            setappdata(0, 'WNPE3', e3)
            
            if getappdata(0, 'figure_PE') == 1.0 && outputFigure == 1.0
                f5 = figure('visible', figureVisibility);
                subplot(3.0, 1.0, 1.0)
                plot(e1, '-', 'LineWidth', lineWidth, 'Color', midnightBlue)

                msg = sprintf('PE1, Maximum inelastic principal strain for item %.0f.%.0f', mainID, subID);
                ylabel('Strain', 'FontSize', fontY)
                title(msg, 'FontSize', fontTitle)
                set(gca, 'FontSize', fontTicks)
                set(gca, 'XTick', linspace(1.0, L, XTickPartition + 1.0))
                set(gca, 'XTickLabel', round(linspace(1.0, L, XTickPartition + 1.0))); 
                
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                
                if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
                    grid on
                end

                %% PE2 (Middle inelastic principal strain at worst item)
                
                subplot(3, 1, 2)
                plot(e2, '-', 'LineWidth', lineWidth, 'Color', midnightBlue)
                
                msg = sprintf('PE2, Middle inelastic principal strain for item %.0f.%.0f', mainID, subID);
                ylabel('Strain', 'FontSize', fontY)
                title(msg, 'FontSize', fontTitle)
                set(gca, 'FontSize', fontTicks)
                set(gca, 'XTick', linspace(1.0, L, XTickPartition + 1.0))
                set(gca, 'XTickLabel', round(linspace(1.0, L, XTickPartition + 1.0))); 
                
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                
                if strcmpi(gridLines, 'on') == 1.0 || gridLines == 1.0
                    grid on
                end
                
                %% PE3 (Minimum inelastic principal strain at worst item)
                
                subplot(3.0, 1.0, 3.0)
                plot(e3, '-', 'LineWidth', lineWidth, 'Color', midnightBlue)
                
                msg = sprintf('PE3, Minimum inelastic principal strain for item %.0f.%.0f', mainID, subID);
                xlabel('Sample', 'FontSize', fontX)
                ylabel('Strain', 'FontSize', fontY)
                title(msg, 'FontSize', fontTitle)
                set(gca, 'FontSize', fontTicks)
                set(gca, 'XTick', linspace(1.0, L, XTickPartition + 1.0))
                set(gca, 'XTickLabel', round(linspace(1.0, L, XTickPartition + 1.0))); 
                
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                
                if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
                    grid on
                end
                
                dir = [root, 'MATLAB Figures/PE, Inelastic principal strains at worst item'];
                saveas(f5, dir, figureFormat)
                if strcmpi(figureFormat, 'fig') == true
                    postProcess.makeVisible([dir, '.fig'])
                end
            end
            
            %% CN (Elastic normal stress on critical plane)
            normalOnCP = getappdata(0, 'CN');
            shearOnCP = getappdata(0, 'CS');
        
            if getappdata(0, 'figure_CNS') == 1.0 && outputFigure == 1.0
                msg = sprintf('CN, Maximum elastic normal stress history for item %.0f.%.0f', mainID, subID);
                    
                f6 = figure('visible', figureVisibility);
                subplot(2.0, 1.0, 1.0)
                plot(normalOnCP, '-', 'LineWidth', lineWidth, 'Color', fireBrick)
                
                ylabel('Stress [MPa]', 'FontSize', fontY)
                title(msg, 'FontSize', fontTitle)
                set(gca, 'FontSize', fontTicks)
                set(gca, 'XTick', linspace(1.0, L, XTickPartition + 1.0))
                set(gca, 'XTickLabel', round(linspace(1.0, L, XTickPartition + 1.0))); 
                
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                
                if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
                    grid on
                end
                
                %% CS (Elastic shear stress on critical plane)
                msg = sprintf('CS, Maximum elastic shear (Tresca) stress history for item %.0f.%.0f', mainID, subID);
                figureTitle = 'MATLAB Figures/CN + CS, Elastic normal and shear stress at worst item';
                
                subplot(2.0, 1.0, 2.0)
                plot(shearOnCP, '-', 'LineWidth', lineWidth, 'Color', forestGreen)

                xlabel('Sample', 'FontSize', fontX);
                ylabel('Stress [MPa]', 'FontSize', fontY)
                title(msg, 'FontSize', fontTitle)
                set(gca, 'FontSize', fontTicks)
                set(gca, 'XTick', linspace(1.0, L, XTickPartition + 1.0))
                set(gca, 'XTickLabel', round(linspace(1.0, L, XTickPartition + 1.0))); 
                
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                
                if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
                    grid on
                end
                
                dir = [root, figureTitle];
                saveas(f6, dir, figureFormat)
                if strcmpi(figureFormat, 'fig') == true
                    postProcess.makeVisible([dir, '.fig'])
                end
            end
            
            if algorithm == 1.0 || algorithm == 2.0
                thetaOnCP = getappdata(0, 'thetaOnCP');
                
                figureFormat = getappdata(0, 'figureFormat');
                
                root = getappdata(0, 'outputDirectory');
                
                midnightBlue = [25/255, 25/255, 112/255];
                lineWidth = getappdata(0, 'defaultLineWidth');
                fontX = getappdata(0, 'defaultFontSize_XAxis');
                fontY = getappdata(0, 'defaultFontSize_YAxis');
                fontTitle = getappdata(0, 'defaultFontSize_Title');
                fontTicks = getappdata(0, 'defaultFontSize_Ticks');
                gridLines = getappdata(0, 'gridLines');
                
                mainID = getappdata(0, 'worstMainID');
                subID = getappdata(0, 'worstSubID');
                
                smoothness = getappdata(0, 'cpSample');
                if isempty(smoothness)
                    smoothness = 1.0;
                elseif isnumeric(smoothness) == 0.0
                    smoothness = 1.0;
                elseif isnan(smoothness) || isreal(smoothness) == 0.0 || ...
                        isinf(smoothness) || isreal(smoothness) == 0.0
                    smoothness = 1.0;
                end
                
                damageParameter = getappdata(0, 'worstNodeDamageParamCube');
                damage = getappdata(0, 'worstNodeDamageCube');
                
                steps = getappdata(0, 'stepSize');
                step = steps(worstItem);
                
                %% DPP-THETA (Damage parameter vs THETA)
                
                setappdata(0, 'DPT', damageParameter)
                
                if outputFigure == 1.0 && getappdata(0, 'figure_DPP') == 1.0
                    f7 = figure('visible', figureVisibility);
                    
                    % Smooth the data
                    if length(damageParameter) > 9.0 && (max(damageParameter) - min(damageParameter)) ~= 0.0 && smoothness > 1.0 && smoothness > 0.0
                        damageParameter = interp(damageParameter, smoothness);
                    end
                    x = linspace(0.0, 180.0, length(damageParameter));
                    
                    plot(x, damageParameter, '-', 'LineWidth', lineWidth, 'Color', midnightBlue);  hold on
                    scatter(thetaOnCP, damageParameter((thetaOnCP+step)/step), 40, 'MarkerEdgeColor', [0.745, 0.0, 0.0],...
                    'MarkerFaceColor', [1.0, 0.1, 0.1], 'LineWidth', 1.5);
                    
                    msg = sprintf('DPP-THETA, Damage parameter vs theta for item %.0f.%.0f', mainID, subID);
                    xlabel('Angle [deg]', 'FontSize', fontX)
                    ylabel('Damage parameter [Strain]', 'FontSize', fontY)
                    title(msg, 'FontSize', fontTitle)
                    set(gca, 'FontSize', fontTicks)
                    set(gca, 'XTickLabel', 0:45:180);  set(gca, 'XTick', 0:45:180)
                    
                    try
                        axis tight
                    catch
                        % Don't tighten the axis
                    end
                    
                    if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
                        grid on
                    end
                    
                    dir = [root, 'MATLAB Figures/DPP, Damage parameter vs angle at worst item'];
                    saveas(f7, dir, figureFormat)
                    if strcmpi(figureFormat, 'fig') == true
                        postProcess.makeVisible([dir, '.fig'])
                    end
                end
                
                %% DP-THETA (Damage vs THETA)
                setappdata(0, 'DT', damage)
                
                if outputFigure == 1.0 && getappdata(0, 'figure_DP') == 1.0
                    f8 = figure('visible', figureVisibility);
                    
                    % Smooth the data
                    if length(damage) > 9.0 && (max(damage) - min(damage)) ~= 0.0 && smoothness > 0.0
                        damageTheta2 = interp(damage, smoothness);
                    else
                        damageTheta2 = damage;
                    end
                    x = linspace(0.0, 180.0, length(damageTheta2));
                    
                    plot(x, damageTheta2, '-', 'LineWidth', lineWidth, 'Color', midnightBlue);  hold on
                    scatter(thetaOnCP, damageTheta2((thetaOnCP+step)/step), 40, 'MarkerEdgeColor', [0.745, 0.0, 0.0],...
                    'MarkerFaceColor', [1.0, 0.1, 0.1], 'LineWidth', 1.5);
                    
                    msg = sprintf('DP-THETA, Damage vs theta for item %.0f.%.0f', mainID, subID);
                    xlabel('Angle [deg]', 'FontSize', fontX)
                    ylabel(sprintf('Damage [1/%s]', loadEqUnits), 'FontSize', fontY)
                    title(msg, 'FontSize', fontTitle)
                    set(gca, 'FontSize', fontTicks)
                    set(gca, 'XTickLabel', 0:45:180);  set(gca, 'XTick', 0:45:180)
                    
                    try
                        axis tight
                    catch
                        % Don't tighten the axis
                    end
                    
                    if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
                        grid on
                    end
                    
                    dir = [root, 'MATLAB Figures/DP, Damage vs angle at worst item'];
                    saveas(f8, dir, figureFormat)
                    if strcmpi(figureFormat, 'fig') == true
                        postProcess.makeVisible([dir, '.fig'])
                    end
                end
                
                %% LP-THETA (Life vs THETA)
                
                lifeTheta = 1.0./damage;
                
                setappdata(0, 'LT', lifeTheta)
                
                if outputFigure == 1.0 && getappdata(0, 'figure_LP') == 1.0
                    f9 = figure('visible', figureVisibility);
                    
                    % Smooth the data
                    if length(lifeTheta) > 9.0 && (max(lifeTheta) - min(lifeTheta)) ~= 0.0 && smoothness > 0.0
                        lifeTheta = interp(lifeTheta, smoothness);
                    end
                    x = linspace(0.0, 180.0, length(lifeTheta));
                    
                    plot(x, lifeTheta, '-', 'LineWidth', lineWidth, 'Color', midnightBlue);  hold on
                    scatter(thetaOnCP, lifeTheta((thetaOnCP+step)/step), 40, 'MarkerEdgeColor', [0.745, 0.0, 0.0],...
                    'MarkerFaceColor', [1.0, 0.1, 0.1], 'LineWidth', 1.5);
                    
                    msg = sprintf('LP-THETA, Life vs theta for item %.0f.%.0f', mainID, subID);
                    xlabel('Angle [deg]', 'FontSize', fontX)
                    ylabel(sprintf('Life [%s]', loadEqUnits), 'FontSize', fontY)
                    title(msg, 'FontSize', fontTitle)
                    set(gca, 'FontSize', fontTicks)
                    set(gca, 'XTickLabel', 0:45:180);  set(gca, 'XTick', 0:45:180)
                    
                    try
                        axis tight
                    catch
                        % Don't tighten the axis
                    end
                    
                    if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
                        grid on
                    end
                    
                    dir = [root, 'MATLAB Figures/LP, Life vs angle at worst item'];
                    saveas(f9, dir, figureFormat)
                    if strcmpi(figureFormat, 'fig') == true
                        postProcess.makeVisible([dir, '.fig'])
                    end
                end
                
                %% SHEAR/NORMAL STRESS VS THETA
                if outputFigure == 1.0
                    if getappdata(0, 'figure_CPS') == 1.0
                        %% SHEAR STRESS VS THETA
                        f10 = figure('visible', figureVisibility);
                        
                        shearStress = getappdata(0, 'shear_cp');
                        
                        % Smooth the data
                        if length(shearStress) > 9.0 && any(isinf(shearStress)) == 0.0 && (max(shearStress) - min(shearStress)) ~= 0.0 && smoothness > 0.0
                            shearStress = interp(shearStress, smoothness);
                        end
                        x = linspace(0.0, 180.0, length(shearStress));
                        
                        subplot(2.0, 1.0, 1.0)
                        plot(x, shearStress, '-', 'LineWidth', lineWidth, 'Color', midnightBlue);  hold on
                        scatter(thetaOnCP, shearStress((thetaOnCP+step)/step), 40, 'MarkerEdgeColor', [0.745, 0.0, 0.0],...
                        'MarkerFaceColor', [1.0, 0.1, 0.1], 'LineWidth', 1.5);
                        
                        if getappdata(0, 'cpShearStress') == 1.0
                            msg = sprintf('CPS-THETA, Maximum shear stress vs theta for item %.0f.%.0f', mainID, subID);
                        else
                            msg = sprintf('CPS-THETA, Resultant shear stress vs theta for item %.0f.%.0f', mainID, subID);
                        end
                        
                        xlabel('Angle [deg]', 'FontSize', fontX)
                        ylabel('Stress [MPa]', 'FontSize', fontY)
                        title(msg, 'FontSize', fontTitle)
                        set(gca, 'FontSize', fontTicks)
                        set(gca, 'XTickLabel', 0:45:180);  set(gca, 'XTick', 0:45:180)
                        
                        try
                            axis tight
                        catch
                            % Don't tighten the axis
                        end
                        
                        if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
                            grid on
                        end
                    end
                    
                    if getappdata(0, 'figure_CPN') == 1.0
                        %% NORMAL STRESS VS THETA
                        normalStress = getappdata(0, 'normal_cp');
                        
                        % Smooth the data
                        if length(normalStress) > 9.0 && any(isinf(normalStress)) == 0.0 && (max(normalStress) - min(normalStress)) ~= 0.0 && smoothness > 0.0
                            normalStress = interp(normalStress, smoothness);
                        end
                        x = linspace(0.0, 180.0, length(normalStress));
                        
                        subplot(2.0, 1.0, 2.0)
                        plot(x, normalStress, '-', 'LineWidth', lineWidth, 'Color', midnightBlue);  hold on
                        scatter(thetaOnCP, normalStress((thetaOnCP+step)/step), 40, 'MarkerEdgeColor', [0.745, 0.0, 0.0],...
                        'MarkerFaceColor', [1.0, 0.1, 0.1], 'LineWidth', 1.5);
                        
                        msg = sprintf('CPN-THETA, Normal stress vs theta for item %.0f.%.0f', mainID, subID);
                        xlabel('Angle [deg]', 'FontSize', fontX)
                        ylabel('Stress [MPa]', 'FontSize', fontY)
                        title(msg, 'FontSize', fontTitle)
                        set(gca, 'FontSize', fontTicks)
                        set(gca, 'XTickLabel', 0:45:180);  set(gca, 'XTick', 0:45:180)
                        
                        try
                            axis tight
                        catch
                            % Don't tighten the axis
                        end
                        
                        if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
                            grid on
                        end
                        
                        dir = [root, 'MATLAB Figures/CPS, Critical plane stresses vs angle at worst item'];
                        saveas(f10, dir, figureFormat)
                        if strcmpi(figureFormat, 'fig') == true
                            postProcess.makeVisible([dir, '.fig'])
                        end
                    end
                end
            end
            
            %% DAC DAMAGE ACCUMULATION AT WORST ITEM
            
            if outputFigure == 1.0 && getappdata(0, 'figure_DAC') == 1.0
                damagePerCycle = getappdata(0, 'worstNodeCumulativeDamage');
                numberOfCycles = length(damagePerCycle);
                
                if numberOfCycles > 1.0
                    cumulativeDamage = cumsum(damagePerCycle);
                    
                    % If the maximum damage is zero or INF, skip this variable
                    if (max(cumulativeDamage) == 0.0) || (max(cumulativeDamage) == inf)
                        messenger.writeMessage(299.0)
                    else
                        % Check whether damage crosses the infinite life envelope
                        crossing = -999.0;
                        cael = 0.5*getappdata(0, 'cael');
                        if 1.0/max(cumulativeDamage) < cael
                            % Search for the point at which finite life begins
                            if 1.0/cumulativeDamage(1.0) > cael
                                lifeValues = 1.0./cumulativeDamage;
                                crossing = lifeValues(lifeValues < cael);
                                crossing = find(lifeValues == crossing(1.0)) - 1.0;
                            end 
                        end
                        
                        cumulativeDamage = cumulativeDamage/max(cumulativeDamage);
                        
                        f11 = figure('visible', figureVisibility);
                        plot(cumulativeDamage, '-', 'LineWidth', lineWidth, 'Color', midnightBlue)
                        
                        if crossing ~= -999.0
                            l1 = line([crossing, crossing], [0.0, 1.0], 'lineWidth', lineWidth);
                            legend(l1, 'Infinite Life Envelope')
                        end

                        msg = sprintf('DAC, Cumulative damage at item %.0f.%.0f', mainID, subID);
                        xlabel('Cycle', 'FontSize', fontX)
                        ylabel('Normalised Damage', 'FontSize', fontY)
                        title(msg, 'FontSize', fontTitle)
                        set(gca, 'FontSize', fontTicks)
                        set(gca, 'XTick', linspace(1.0, numberOfCycles, XTickPartition + 1.0))
                        set(gca, 'XTickLabel', round(linspace(1.0, numberOfCycles, XTickPartition + 1.0)));
                        
                        try
                            axis tight
                        catch
                            % Don't tighten the axis
                        end
                        
                        if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
                            grid on
                        end
                        
                        dir = [root, 'MATLAB Figures/DAC, Cumulative damage at worst item'];
                        saveas(f11, dir, figureFormat)
                        if strcmpi(figureFormat, 'fig') == true
                            postProcess.makeVisible([dir, '.fig'])
                        end
                    end
                end
            end
            
            %% RHIST RAINFLOW HISTOGRAM OF CYCLES
            
            % This MATLAB figure requires the Statistics Toolbox
            isAvailable = checkToolbox('Statistics and Machine Learning Toolbox');
            
            if (isAvailable == 1.0) && (length(amplitudes) > 1.0)
                if (outputFigure == 1.0) && (outputField == 1.0) && (getappdata(0, 'figure_RHIST') == 1.0)
                    f12 = figure('visible', figureVisibility);
                    rhistData = [Sm'; 2.0.*amplitudes]';
                    nBins = getappdata(0, 'numberOfBins');
                    hist3(rhistData, [nBins, nBins])
                    
                    set(gcf, 'renderer', 'opengl');
                    set(get(gca, 'child'), 'FaceColor', 'interp', 'CDataMode', 'auto');
                    colorbar
                    
                    msg = sprintf('RHIST, Rainflow cycle histogram at item %.0f.%.0f', mainID, subID);
                    xlabel('Mean Stress (MPa)', 'FontSize', fontX)
                    ylabel('Stress Range (MPa)', 'FontSize', fontY)
                    title(msg, 'FontSize', fontTitle)
                    set(gca, 'FontSize', fontTicks)
                    
                    try
                        axis tight
                    catch
                        % Don't tighten the axis
                    end
                    
                    dir = [root, 'MATLAB Figures/RHIST, Rainflow cycle histogram at worst item'];
                    saveas(f12, dir, figureFormat)
                    if strcmpi(figureFormat, 'fig') == true
                        postProcess.makeVisible([dir, '.fig'])
                    end
                end
                
                %% RC RANGE vs CYCLES
                
                if (outputFigure == 1.0) && (outputField == 1.0) && (getappdata(0, 'figure_RC') == 1.0)
                    f13 = figure('visible', figureVisibility);
                    msg = sprintf('RC, Stress range distribution at item %.0f.%.0f', mainID, subID);
                    title(msg, 'FontSize', fontTitle)
                    rhistData = [Sm'; 2.0*amplitudes]';
                    [h, bins] = hist3(rhistData, [nBins, nBins]);
                    
                    plot(bins{2.0}, sum(h), '-', 'LineWidth', lineWidth, 'Color', midnightBlue)
                    
                    xlabel('Stress Range (MPa)', 'FontSize', fontX)
                    ylabel('Cycles', 'FontSize', fontY)
                    set(gca, 'FontSize', fontTicks)
                    
                    try
                        axis tight
                    catch
                        % Don't tighten the axis
                    end
                    
                    if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
                        grid on
                    end
                    
                    dir = [root, 'MATLAB Figures/RC, Stress range distribution at worst item'];
                    saveas(f13, dir, figureFormat)
                    if strcmpi(figureFormat, 'fig') == true
                        postProcess.makeVisible([dir, '.fig'])
                    end
                end
            elseif (isAvailable == 0.0) && (outputFigure == 1.0)
                messenger.writeMessage(128.0)
            end
            
            %% SIGS UNIAXIAL STRESS HISTORY (BEFORE AND AFTER FILTERING *)
            
            % *If applicable
            % Only if the Uniaxial Strain-Life algorithm is used
            % Only if peak-valley detection, noise reduction or high
            % frequency data was used
            if (outputFigure == 1.0 && algorithm == 3.0 && getappdata(0, 'figure_SIG') == 1.0) &&...
                    ((getappdata(0, 'noiseReduction') == 1.0 ||...
                    (getappdata(0, 'gateHistories') == 1.0) || (getappdata(0, 'gateHistories') == 2.0)) ||...
                    getappdata(0, 'gateTensors') == 1.0 || getappdata(0, 'gateTensors') == 2.0)
                
                f14 = figure('visible', figureVisibility);
                oldSignal = getappdata(0, 'SIGOriginalSignal');
                
                subplot(2, 1, 1)
                plot(oldSignal, '-', 'LineWidth', lineWidth, 'Color', midnightBlue);
                
                msg = sprintf('SIGS1, Uniaxial elastic stress history before gating');
                title(msg, 'FontSize', fontTitle)
                xlabel('Sample', 'FontSize', fontX)
                ylabel('Stress (MPa)', 'FontSize', fontY)
                title(msg, 'FontSize', fontTitle)
                set(gca, 'FontSize', fontTicks)
                set(gca, 'XTick', linspace(1.0, length(oldSignal), XTickPartition + 1.0))
                set(gca, 'XTickLabel', round(linspace(1.0, length(oldSignal), XTickPartition + 1.0)));
                
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                
                if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
                    grid on
                end
                
                subplot(2, 1, 2)
                plot(damageParameter, '-', 'LineWidth', lineWidth, 'Color', forestGreen);
                
                msg = sprintf('SIGS2, Uniaxial inelastic stress history after gating');
                title(msg, 'FontSize', fontTitle)
                xlabel('Sample', 'FontSize', fontX)
                ylabel('Stress (MPa)', 'FontSize', fontY)
                set(gca, 'FontSize', fontTicks)
                set(gca, 'XTick', linspace(1.0, L, XTickPartition + 1.0))
                set(gca, 'XTickLabel', round(linspace(1.0, L, XTickPartition + 1.0)));
                
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                
                if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
                    grid on
                end
                
                dir = [root, 'MATLAB Figures/SIGS, Uniaxial stress history before and after gating'];
                saveas(f14, dir, figureFormat)
                if strcmpi(figureFormat, 'fig') == true
                    postProcess.makeVisible([dir, '.fig'])
                end
            elseif (outputFigure == 1.0 && algorithm == 3.0 && getappdata(0, 'figure_SIG') == 1.0)
                f12 = figure('visible', figureVisibility);
                oldSignal = getappdata(0, 'SIGOriginalSignal');
                
                plot(oldSignal, '-', 'LineWidth', lineWidth, 'Color', midnightBlue);   hold on
                
                msg = sprintf('SIGS, Uniaxial stress history');
                xlabel('Sample', 'FontSize', fontX)
                ylabel('Stress (MPa)', 'FontSize', fontY)
                title(msg, 'FontSize', fontTitle)
                set(gca, 'FontSize', fontTicks)
                set(gca, 'XTick', linspace(1.0, L, XTickPartition + 1.0))
                set(gca, 'XTickLabel', round(linspace(1.0, L, XTickPartition + 1.0)));
                
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                
                if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
                    grid on
                end
                
                dir = [root, 'MATLAB Figures/SIGS, Uniaxial elastic stress history'];
                saveas(f12, dir, figureFormat)
                if strcmpi(figureFormat, 'fig') == true
                    postProcess.makeVisible([dir, '.fig'])
                end
            end
            
            %% SIGE UNIAXIAL INELASTIC STRAIN HISTORY
            if (outputFigure == 1.0 && algorithm == 3.0 && getappdata(0, 'figure_SIG') == 1.0)
                f13 = figure('visible', figureVisibility);
                
                plot(damageParameter_strain, '-', 'LineWidth', lineWidth, 'Color', midnightBlue);   hold on
                
                msg = sprintf('SIGE, Uniaxial inelastic strain history');
                xlabel('Sample', 'FontSize', fontX)
                ylabel('Strain', 'FontSize', fontY)
                title(msg, 'FontSize', fontTitle)
                set(gca, 'FontSize', fontTicks)
                set(gca, 'XTick', linspace(1.0, L, XTickPartition + 1.0))
                set(gca, 'XTickLabel', round(linspace(1.0, L, XTickPartition + 1.0)));
                
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                
                if strcmpi(gridLines, 'on') == 1.0 || str2double(gridLines) == 1.0
                    grid on
                end
                
                dir = [root, 'MATLAB Figures/SIGE, Uniaxial inelastic strain history'];
                saveas(f13, dir, figureFormat)
                if strcmpi(figureFormat, 'fig') == true
                    postProcess.makeVisible([dir, '.fig'])
                end
            end
            
            %% LH LOAD HISTORIES
            if getappdata(0, 'figure_LH') == 1.0 && outputFigure == 1.0 && algorithm ~= 3.0
                Sxx = getappdata(0, 'worstNodeSxx');
                Syy = getappdata(0, 'worstNodeSyy');
                Szz = getappdata(0, 'worstNodeSzz');
                Txy = getappdata(0, 'worstNodeTxy');
                Tyz = getappdata(0, 'worstNodeTyz');
                Txz = getappdata(0, 'worstNodeTxz');
                
                f12 = figure('visible', figureVisibility);
                
                subplot(3.0, 2.0, 1.0)
                plot(Sxx, '-', 'LineWidth', lineWidth, 'Color', midnightBlue)
                xlabel('Sample', 'FontSize', fontX)
                ylabel('Stress (MPa)', 'FontSize', fontY)
                title(sprintf('S11 for item %.0f.%.0f', mainID, subID'), 'FontSize', fontTitle)
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                if strcmpi(gridLines, 'on') == 1.0 || gridLines == 1.0
                    grid on
                end
                
                subplot(3.0, 2.0, 2.0)
                plot(Syy, '-', 'LineWidth', lineWidth, 'Color', midnightBlue)
                xlabel('Sample', 'FontSize', fontX)
                ylabel('Stress (MPa)', 'FontSize', fontY)
                title(sprintf('S22 for item %.0f.%.0f', mainID, subID'), 'FontSize', fontTitle)
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                if strcmpi(gridLines, 'on') == 1.0 || gridLines == 1.0
                    grid on
                end
                
                subplot(3.0, 2.0, 3.0)
                plot(Szz, '-', 'LineWidth', lineWidth, 'Color', midnightBlue)
                xlabel('Sample', 'FontSize', fontX)
                ylabel('Stress (MPa)', 'FontSize', fontY)
                title(sprintf('S33 for item %.0f.%.0f', mainID, subID'), 'FontSize', fontTitle)
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                if strcmpi(gridLines, 'on') == 1.0 || gridLines == 1.0
                    grid on
                end
                
                subplot(3.0, 2.0, 4.0)
                plot(Txy, '-', 'LineWidth', lineWidth, 'Color', midnightBlue)
                xlabel('Sample', 'FontSize', fontX)
                ylabel('Stress (MPa)', 'FontSize', fontY)
                title(sprintf('S12 for item %.0f.%.0f', mainID, subID'), 'FontSize', fontTitle)
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                if strcmpi(gridLines, 'on') == 1.0 || gridLines == 1.0
                    grid on
                end
                
                subplot(3.0, 2.0, 5.0)
                plot(Tyz, '-', 'LineWidth', lineWidth, 'Color', midnightBlue)
                xlabel('Sample', 'FontSize', fontX)
                ylabel('Stress (MPa)', 'FontSize', fontY)
                title(sprintf('S23 for item %.0f.%.0f', mainID, subID'), 'FontSize', fontTitle)
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                if strcmpi(gridLines, 'on') == 1.0 || gridLines == 1.0
                    grid on
                end
                
                subplot(3.0, 2.0, 6.0)
                plot(Txz, '-', 'LineWidth', lineWidth, 'Color', midnightBlue)
                xlabel('Sample', 'FontSize', fontX)
                ylabel('Stress (MPa)', 'FontSize', fontY)
                title(sprintf('S13 for item %.0f.%.0f', mainID, subID'), 'FontSize', fontTitle)
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                if strcmpi(gridLines, 'on') == 1.0 || gridLines == 1.0
                    grid on
                end
                
                dir = [root, 'MATLAB Figures/LH, Elastic load history'];
                saveas(f12, dir, figureFormat)
                if strcmpi(figureFormat, 'fig') == true
                    postProcess.makeVisible([dir, '.fig'])
                end
            end
        end
        
        %% Write history output to file:
        function [] = exportHistories(algorithm, loadEqUnits)
            % history output format string
            h = getappdata(0, 'historyFormatString');
            
            root = getappdata(0, 'outputDirectory');
            
            %{
                LOAD HISTORIES -> Multiple values at worst item over all
                signal increments
            %}
            
            worstMainID = getappdata(0, 'worstMainID');
            worstSubID = getappdata(0, 'worstSubID');
            
            INCi = getappdata(0, 'signalLength');
            INC = 1:INCi;
            
            VM = getappdata(0, 'WNVM');
            PS1 = getappdata(0, 'WNPS1');
            PS2 = getappdata(0, 'WNPS2');
            PS3 = getappdata(0, 'WNPS3');
            PE1 = getappdata(0, 'WNPE1');
            PE2 = getappdata(0, 'WNPE2');
            PE3 = getappdata(0, 'WNPE3');
            CN = getappdata(0, 'CN');
            CS = getappdata(0, 'CS');
            
            % Correct length of PE1 vector
            if length(PE1) < INCi
                append = INCi - length(PE1);
                PE1 = [PE1, zeros(1.0, append)];
            elseif length(PE1) > INCi
                PE1 = PE1(1.0:INCi);
            end
            % Correct length of PE2 vector
            if length(PE2) < INCi
                append = INCi - length(PE2);
                PE2 = [PE2, zeros(1.0, append)];
            elseif length(PE2) > INCi
                PE2 = PE2(1.0:INCi);
            end
            % Correct length of PE3 vector
            if length(PE3) < INCi
                append = INCi - length(PE3);
                PE3 = [PE3, zeros(1.0, append)];
            elseif length(PE3) > INCi
                PE3 = PE3(1.0:INCi);
            end
            
            data = [INC; VM; PS1; PS2; PS3; PE1; PE2; PE3; CN; CS]';
            
            %% Open file for writing:
            
            if getappdata(0, 'file_H_OUTPUT_LOAD') == 1.0
                dir = [root, 'Data Files/h-output-load.dat'];
                
                fid = fopen(dir, 'w+');
                
                fprintf(fid, 'WORST ITEM LOAD HISTORIES (%.0f.%.0f)\r\n', worstMainID, worstSubID);
                
                fprintf(fid, 'Units:\tMPa, Strain\r\n');
                
                fprintf(fid, 'Load Increment\tVM\tPS1\tPS2\tPS3\tPE1\tPE2\tPE3\tCN\tCS\r\n');
                fprintf(fid, sprintf('%%.0f\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\r\n', h, h, h, h, h, h, h, h, h), data');
                
                fclose(fid);
            end
            
            %{
                CYCLE HISTORIES -> Worst cycle per item and all cycles at
                worst item
            %}
            
            mainID = getappdata(0, 'mainID');
            subID = getappdata(0, 'subID');
            
            [r, ~] = size(mainID);
            if r == 1.0
                mainID = mainID';
            end
            [r, ~] = size(subID);
            if r == 1.0
                subID = subID';
            end
            
            Ci = getappdata(0, 'numberOfCycles');
            C = 1:Ci;
            
            WCA = getappdata(0, 'WCA');
            WCA_strain = getappdata(0, 'WCA_strain');
            
            WCM = getappdata(0, 'WCM');
            WCM_strain = getappdata(0, 'WCM_strain');
            
            A = WCA./WCM;
            R = (1.0 - A)./(1.0 + A);
            R(isnan(R) == 1.0) = -1.0;
            
            dataA = [mainID'; subID'; WCM; WCM_strain; WCA; WCA_strain; R]';
            
            WNM = getappdata(0, 'meansOnCP');
            WNM_strain = getappdata(0, 'meansOnCP_strain');
            
            WNA = getappdata(0, 'amplitudesOnCP');
            WNA_strain = getappdata(0, 'amplitudesOnCP_strain');
            
            A = WNA./WNM';
            R = (1.0 - A)./(1.0 + A);
            R(isnan(R) == 1.0) = -1.0;
            
            dataB = [C; WNM'; WNM_strain'; WNA; WNA_strain; R]';
            
            %% Open file for writing:
            
            if getappdata(0, 'file_H_OUTPUT_CYCLE') == 1.0
                dir = [root, 'Data Files/h-output-cycle.dat'];
                
                fid = fopen(dir, 'w+');
                
                [lengthA, ~] = size(dataA);
                [lengthB, ~] = size(dataB);
                if lengthA > lengthB
                    shortLength = lengthB;
                else
                    shortLength = lengthA;
                end
                
                fprintf(fid, 'ANHD, WORST CYCLE HISTORIES (ALL ITEMS)\t\t\t\t\t\t\tHD, ALL CYCLE HISTORIES AT WORST ITEM (%.0f.%.0f)\r\n', worstMainID, worstSubID);
                
                fprintf(fid, 'Units:\tMPa, Strain\r\n');
                
                fprintf(fid, 'Item #\tMean stress\tMean strain\tStress amplitude\tStrain amplitude\tLoad ratio\t\tCycle #\tMean stress\tMean strain\tStress amplitude\tStrain amplitude\tLoad ratio\r\n');
                fprintf(fid, sprintf('%%.0f.%%.0f\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t\t%%.0f\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\r\n', h, h, h, h, h, h, h, h, h, h), [dataA(1.0:shortLength, :), dataB(1.0:shortLength, :)]');
                
                if lengthA > lengthB
                    fprintf(fid, sprintf('%%.0f.%%.0f\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\r\n', h, h, h, h), dataA(shortLength + 1.0:end, :)');
                elseif lengthB > lengthA
                    fprintf(fid, sprintf('\t\t\t\t\t\t\t%%.0f\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\r\n', h, h, h, h, h), dataB(shortLength + 1.0:end, :)');
                end
                
                fclose(fid);
            end
            
            %{
                ANGLE HISTORIES -> Multiple values at worst item over all
                plane orientations
            %}
            
            if algorithm == 1.0 || algorithm == 2.0
                steps = getappdata(0, 'stepSize');
                step = steps(getappdata(0, 'worstItem'));
                planes = 0:step:180;
                
                ST = getappdata(0, 'shear_cp');
                NT = getappdata(0, 'normal_cp');
                
                PT = getappdata(0, 'DPT');
                DT = getappdata(0, 'DT');
                LT = getappdata(0, 'LT');
                
                %% Open file for writing:
                
                if getappdata(0, 'file_H_OUTPUT_ANGLE') == 1.0
                    dir = [root, 'Data Files/h-output-angle.dat'];
                    
                    fid = fopen(dir, 'w+');
                    
                    data = [planes; ST; NT; PT; DT; LT]';
                    
                    fprintf(fid, 'ST, NT, DPP, DP, LP, WORST ITEM ANGLE HISTORIES (%.0f.%.0f)\r\n\r\n', worstMainID, worstSubID);
                    
                    fprintf(fid, 'PHI = %.0f degrees\r\n', getappdata(0, 'phiOnCP'));
                    
                    if getappdata(0, 'cpShearStress') == 1.0
                        fprintf(fid, 'Plane orientation (THETA-degrees)\tMaximum shear stress (MPa)\tMaximum normal stress (MPa)\tDamage parameter (MPa)\tDamage\tLife (%s)\n', loadEqUnits);
                    else
                        fprintf(fid, 'Plane orientation (THETA-degrees)\tResultant shear stress (MPa)\tMaximum normal stress (MPa)\tDamage parameter (MPa)\tDamage\tLife (%s)\n', loadEqUnits);
                    end
                    
                    fprintf(fid, sprintf('%%.0f\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\r\n', h, h, h, h, h), data');
                    
                    fclose(fid);
                end
            end
            
            %{
                TENSOR HISTORIES -> Multiple values at worst item on the
                critical plane
            %}
            
            Sxx = getappdata(0, 'worstNodeSxx');
            Syy = getappdata(0, 'worstNodeSyy');
            Szz = getappdata(0, 'worstNodeSzz');
            Txy = getappdata(0, 'worstNodeTxy');
            Tyz = getappdata(0, 'worstNodeTyz');
            Txz = getappdata(0, 'worstNodeTxz');
            
            data = [INC; Sxx; Syy; Szz; Txy; Txz; Tyz]';
            
            %% Open file for writing:
            
            if getappdata(0, 'file_H_OUTPUT_TENSOR') == 1.0
                dir = [root, 'Data Files/h-output-tensor.dat'];
                
                fid = fopen(dir, 'w+');
                
                fprintf(fid, 'ST, WORST ITEM TENSOR HISTORY (%.0f.%.0f)\r\n\r\n', worstMainID, worstSubID);
                
                fprintf(fid, 'Units:\tMPa\r\n');
                
                fprintf(fid, 'Load Increment\tS11\tS22\tS33\tS12\tS13\tS23\r\n');
                
                fprintf(fid, sprintf('%%.0f\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\r\n', h, h, h, h, h, h), data');
                
                fclose(fid);
            end
        end
    end
end