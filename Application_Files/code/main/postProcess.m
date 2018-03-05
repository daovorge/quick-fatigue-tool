classdef postProcess < handle
%POSTPROCESS    QFT class for post-analysis processing.
%   This class contains methods for post-analysis processing tasks.
%   
%   POSTPROCESS is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%
%   See also postProcess.
%
%   Reference section in Quick Fatigue Tool User Guide
%      10 Output
%   
%   Quick Fatigue Tool 6.11-13 Copyright Louis Vallance 2018
%   Last modified 04-Mar-2018 19:58:22 GMT
    
    %%
    
    methods(Static = true)
        %% Get the worst cycle stress amplitude and mean stress
        function [] = getWorstCycleMeanAmp()
            N = getappdata(0, 'numberOfNodes');
            
            nodalCycles = getappdata(0, 'nodalPairs');
            nodalAmps = getappdata(0, 'nodalAmplitudes');
            
            WCM = zeros(1.0, N);
            WCA = zeros(1.0, N);
            
            for i = 1:N
                % Get cycles and amplitudes for current item
                cycles = nodalCycles{i};
                amps = nodalAmps{i};
                
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
            
            %{
            	Remove near-zero values which can arise due to numerical
                artifacting
            %}
            WCM(abs(WCM) < 1e-6) = 0.0;
            
            setappdata(0, 'WCA', WCA)
            setappdata(0, 'WCM', WCM)
            
            % Get mean stress for each cycle
            cycles = getappdata(0, 'cyclesOnCP');
            Sm = 0.5*(cycles(:, 1.0) + cycles(:, 2.0));
            setappdata(0, 'meansOnCP', Sm)
            setappdata(0, 'numberOfCycles', length(Sm))
        end
        
        %% Get the number of cycles in the loading
        function [] = getNumberOfCycles()
            cycles = getappdata(0, 'cyclesOnCP');
            [numberOfCycles, ~] = size(cycles);
            setappdata(0, 'numberOfCycles', numberOfCycles)
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
            
            % Get the worst mean stress for each item in the model
            WCA = getappdata(0, 'WCA');
            
            % Find the maximum value of the worst mean stress in the model
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
            
            %% WCM (Worst cycle mean stress)
            
            % Get the worst mean stress for each item in the model
            WCM = getappdata(0, 'WCM');
            
            % Find the maximum value of the worst mean stress in the model
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
            
            % Get the triaxiality factor for each analysis item
            triaxialityFactors = hydroStress./vonMises;
            triaxialityFactor = max(triaxialityFactors, [], 2.0)';
            
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
            WCM = getappdata(0, 'WCM');
            WCA = getappdata(0, 'WCA');
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
                
                fprintf(fid, 'Main ID\tSub ID\tL (%s)\tLL (%s)\tD\tDDL\tFOS\tSFA\tFRFR\tFRFH\tFRFV\tFRFW\tSMAX (MPa)\tSMXP\tSMXU\tTRF\tWCM (MPa)\tWCA (MPa)\tWCATAN (Deg)\tWCDP (MPa)\tYIELD\r\n', loadEqUnits, loadEqUnits);
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
                    
                    itemNumbers = linspace(1.0, N, N);
                    itemNumbers(coldItems) = [];
                    
                    mainID = mainID(itemNumbers);
                    subID = subID(itemNumbers);
                    
                    L = L(itemNumbers);
                    LL = LL(itemNumbers);
                    D = D(itemNumbers);
                    DDL = DDL(itemNumbers);
                    FOS = FOS(itemNumbers);
                    SFA = SFA(itemNumbers);
                    FRFR = FRFR(itemNumbers);
                    FRFH = FRFH(itemNumbers);
                    FRFV = FRFV(itemNumbers);
                    FRFW = FRFW(itemNumbers);
                    SMAX = SMAX(itemNumbers);
                    SMXP = SMXP(itemNumbers);
                    SMXU = SMXU(itemNumbers);
                    TRF = TRF(itemNumbers);
                    WCM = WCM(itemNumbers);
                    WCA = WCA(itemNumbers);
                    WCATAN = WCATAN(itemNumbers);
                    WCDP = WCDP(itemNumbers);
                    YIELD = YIELD(itemNumbers);
                    
                    data_i = [mainID'; subID'; L; LL; D; DDL; FOS; SFA; FRFR; FRFH; FRFV; FRFW; SMAX; SMXP; SMXU; TRF; WCM; WCA; WCATAN; WCDP; YIELD]';
                    
                    fprintf(fid, 'Main ID\tSub ID\tL (%s)\tLL (%s)\tD\tDDL\tFOS\tSFA\tFRFR\tFRFH\tFRFV\tFRFW\tSMAX (MPa)\tSMXP\tSMXU\tTRF\tWCM (MPa)\tWCA (MPa)\tWCATAN (Deg)\tWCDP (MPa)\tYIELD\r\n', loadEqUnits, loadEqUnits);
                    fprintf(fid, sprintf('%%.0f\t%%.0f\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%.0f\r\n',...
                    f, f, f, f, f, f, f, f, f, f, f, f, f, f, f, f, f, f), data_i');
                    
                    fclose(fid);
                end
            end
        end
        
        %% Get history output from analysis:
        function [] = getHistories(algorithm, loadEqUnits, outputField, outputFigure, damageParameter, G)
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
            
            % Get knock-down data
            snKnockDown = getappdata(0, 'snKnockDown');
            
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
                    scatter(WCM, WCA, 40, 'MarkerEdgeColor', [0.0, 0.5, 0.5],...
                        'MarkerFaceColor', [0.0, 0.7, 0.7], 'LineWidth', 1.5)
                    
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
                        
                        subplot(1, 2, 2)
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
            
            %% KDSN (Knock-down S-N Curves)
            
            if (getappdata(0, 'figure_KDSN') == 1.0) && (outputFigure == 1.0) && (getappdata(0, 'useSN') == 1.0) && (isempty(snKnockDown) == 0.0)
                % Get the group ID buffer
                groupIDBuffer = getappdata(0, 'groupIDBuffer');
                
                % Get the error flag
                kd_error = getappdata(0, 'kd_error');
                
                % Create a figure for each knock-down curve
                for i = 1:G
                    if (isempty(snKnockDown{i}) == 0.0) && (kd_error(i) == 0.0)
                        % Assign group parameters to the current set of analysis IDs
                        [~, ~] = group.switchProperties(i, groupIDBuffer(i));
                        
                        % Get the current material
                        [~, material, ~] = fileparts(char(groupIDBuffer(i).material));
                        
                        % Get S-N data
                        [nSets, ~] = size(getappdata(0, 's_values'));
                        if nSets > 1.0
                            S = getappdata(0, 's_values_reduced');
                        else
                            S = getappdata(0, 's_values');
                        end
                        N = getappdata(0, 'n_values');
                        
                        % Get the current figure handle
                        f2 = figure('visible', figureVisibility);
                        
                        loglog(N, S, '-', 'LineWidth', lineWidth, 'Color', midnightBlue);   hold on
                        
                        if G == 1.0
                            msg = sprintf('KDSN, Knock-down S-N Curve for %s', material);
                            dir = [root, sprintf('MATLAB Figures/KDSN, Knock-down S-N Curve')];
                        else
                            msg = sprintf('KDSN, Knock-down S-N Curve for %s (Group %.0f)', material, i);
                            dir = [root, sprintf('MATLAB Figures/KDSN, Knock-down S-N Curve (Group %.0f)', i)];
                        end
                        
                        xString = sprintf('%s to failure', loadEqUnits);
                        xlabel(xString, 'FontSize', fontX)
                        ylabel('Damage Parameter (MPa)', 'FontSize', fontY)
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
                        
                        saveas(f2, dir, figureFormat)
                        if strcmpi(figureFormat, 'fig') == true
                            postProcess.makeVisible([dir, '.fig'])
                        end
                    end
                end
            end
            
            %% VM (von Mises stress at worst item)
            
            vonMises = getappdata(0, 'VM');
            vonMises = vonMises(worstItem, :);
            
            setappdata(0, 'WNVM', vonMises)
                
            if  getappdata(0, 'figure_VM') == 1.0 && outputFigure == 1.0
                f3 = figure('visible', figureVisibility);
                
                plot(vonMises, '-', 'LineWidth', lineWidth, 'Color', midnightBlue)
                
                msg = sprintf('VM, von Mises stress for item %.0f.%.0f', mainID, subID);
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
                
                dir = [root, 'MATLAB Figures/VM, von Mises stress at worst item'];
                saveas(f3, dir, figureFormat)
                if strcmpi(figureFormat, 'fig') == true
                    postProcess.makeVisible([dir, '.fig'])
                end
            end
            
            %% PS1 (Maximum Principal stress at worst item)
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

                msg = sprintf('PS1, Maximum principal stress for item %.0f.%.0f', mainID, subID);
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

                %% PS2 (Middle Principal stress at worst item)
                
                subplot(3, 1, 2)
                plot(s2, '-', 'LineWidth', lineWidth, 'Color', midnightBlue)
                
                msg = sprintf('PS2, Middle principal stress for item %.0f.%.0f', mainID, subID);
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
                
                %% PS3 (Minimum Principal stress at worst item)
                
                subplot(3.0, 1.0, 3.0)
                plot(s3, '-', 'LineWidth', lineWidth, 'Color', midnightBlue)
                
                msg = sprintf('PS3, Minimum principal stress for item %.0f.%.0f', mainID, subID);
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
                
                dir = [root, 'MATLAB Figures/PS, Principal stresses at worst item'];
                saveas(f4, dir, figureFormat)
                if strcmpi(figureFormat, 'fig') == true
                    postProcess.makeVisible([dir, '.fig'])
                end
            end
            
            %%
            proportionalItems = getappdata(0, 'proportionalItems');
            
            %% CN (Normal stress on critical plane)
            normalOnCP = getappdata(0, 'CN');
            shearOnCP = getappdata(0, 'CS');
            
            if getappdata(0, 'figure_CNS') == 1.0 && outputFigure == 1.0
                if (algorithm == 10.0) || (algorithm == 7.0) || proportionalItems(worstItem) == 1.0
                    msg = sprintf('CN, Maximum normal stress history for item %.0f.%.0f', mainID, subID);
                else
                    msg = sprintf('CN, Maximum normal stress history on critical plane for item %.0f.%.0f', mainID, subID);
                end
                
                f5 = figure('visible', figureVisibility);
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
                
                %% CS (Shear stress on critical plane)
                if (algorithm == 10.0) || (algorithm == 7.0) || proportionalItems(worstItem) == 1.0
                    msg = sprintf('CS, Maximum shear (Tresca) stress history for item %.0f.%.0f', mainID, subID);
                    figureTitle = 'MATLAB Figures/CN + CS, Normal and shear stress at worst item';
                else
                    msg = sprintf('CS, Maximum shear stress history on critical plane for item %.0f.%.0f', mainID, subID);
                    figureTitle = 'MATLAB Figures/CN + CS, Normal and shear stress on critical plane at worst item';
                end
                
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
                saveas(f5, dir, figureFormat)
                if strcmpi(figureFormat, 'fig') == true
                    postProcess.makeVisible([dir, '.fig'])
                end
            end
            
            if (algorithm < 7.0) && (algorithm ~= 10.0) && (proportionalItems(worstItem) == 0.0)
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
                
                step = getappdata(0, 'stepSize');
                
                %% DPP-THETA (Damage parameter vs THETA)
                
                setappdata(0, 'DPT', damageParameter)
                
                if outputFigure == 1.0 && getappdata(0, 'figure_DPP') == 1.0
                    f6 = figure('visible', figureVisibility);
                    
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
                    ylabel('Damage parameter [MPa]', 'FontSize', fontY)
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
                    saveas(f6, dir, figureFormat)
                    if strcmpi(figureFormat, 'fig') == true
                        postProcess.makeVisible([dir, '.fig'])
                    end
                end
                
                %% DP-THETA (Damage vs THETA)
                setappdata(0, 'DT', damage)
                
                if outputFigure == 1.0 && getappdata(0, 'figure_DP') == 1.0
                    f7 = figure('visible', figureVisibility);
                    
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
                    saveas(f7, dir, figureFormat)
                    if strcmpi(figureFormat, 'fig') == true
                        postProcess.makeVisible([dir, '.fig'])
                    end
                end
                
                %% LP-THETA (Life vs THETA)
                
                lifeTheta = 1.0./damage;
                
                setappdata(0, 'LT', lifeTheta)
                
                if outputFigure == 1.0 && getappdata(0, 'figure_LP') == 1.0
                    f8 = figure('visible', figureVisibility);
                    
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
                    saveas(f8, dir, figureFormat)
                    if strcmpi(figureFormat, 'fig') == true
                        postProcess.makeVisible([dir, '.fig'])
                    end
                end
                
                %% SHEAR/NORMAL STRESS VS THETA
                
                if outputFigure == 1.0
                    if getappdata(0, 'figure_CPS') == 1.0
                        %% SHEAR STRESS VS THETA
                        f9 = figure('visible', figureVisibility);
                        
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
                        saveas(f9, dir, figureFormat)
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
                        
                        f10 = figure('visible', figureVisibility);
                        plot(cumulativeDamage, '-', 'LineWidth', lineWidth, 'Color', midnightBlue)
                        
                        if crossing ~= -999.0
                            l1 = line([crossing(1.0), crossing(1.0)], [0.0, 1.0], 'lineWidth', lineWidth);
                            legend(l1, 'Infinite Life Envelope')
                        end
                        
                        msg = sprintf('DAC, Cumulative damage for item %.0f.%.0f', mainID, subID);
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
                        saveas(f10, dir, figureFormat)
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
                    f11 = figure('visible', figureVisibility);
                    rhistData = [Sm'; 2.0.*amplitudes]';
                    nBins = getappdata(0, 'numberOfBins');
                    hist3(rhistData, [nBins, nBins])
                    
                    set(gcf, 'renderer', 'opengl');
                    set(get(gca, 'child'), 'FaceColor', 'interp', 'CDataMode', 'auto');
                    colorbar
                    
                    msg = sprintf('RHIST, Rainflow cycle histogram for item %.0f.%.0f', mainID, subID);
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
                    saveas(f11, dir, figureFormat)
                    if strcmpi(figureFormat, 'fig') == true
                        postProcess.makeVisible([dir, '.fig'])
                    end
                end
                
                %% RC RANGE vs CYCLES
                
                if (outputFigure == 1.0) && (outputField == 1.0) && (getappdata(0, 'figure_RC') == 1.0)
                    f12 = figure('visible', figureVisibility);
                    msg = sprintf('RC, Stress range distribution for item %.0f.%.0f', mainID, subID);
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
                    saveas(f12, dir, figureFormat)
                    if strcmpi(figureFormat, 'fig') == true
                        postProcess.makeVisible([dir, '.fig'])
                    end
                end
            elseif (isAvailable == 0.0) && (outputFigure == 1.0)
                messenger.writeMessage(128.0)
            end
            
            %% SIGS UNIAXIAL STRESS HISTORY (BEFORE AND AFTER FILTERING *)
            
            % *If applicable
            % Only if the Uniaxial Stress-Life algorithm is used
            % Only if peak-valley detection, noise reduction or high
            % frequency data was used
            if (outputFigure == 1.0 && algorithm == 10.0 && getappdata(0, 'figure_SIG') == 1.0) &&...
                    ((getappdata(0, 'noiseReduction') == 1.0 ||...
                    (getappdata(0, 'gateHistories') == 1.0) || (getappdata(0, 'gateHistories') == 2.0)) ||...
                    getappdata(0, 'gateTensors') == 1.0 || getappdata(0, 'gateTensors') == 2.0)
                
                f13 = figure('visible', figureVisibility);
                oldSignal = getappdata(0, 'SIGOriginalSignal');
                
                subplot(2, 1, 1)
                plot(oldSignal, '-', 'LineWidth', lineWidth, 'Color', midnightBlue);
                
                msg = sprintf('SIG1, Uniaxial load history before gating');
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
                
                msg = sprintf('SIG2, Uniaxial load history after gating');
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
                
                dir = [root, 'MATLAB Figures/SIGS, Uniaxial load history before and after gating'];
                saveas(f13, dir, figureFormat)
                if strcmpi(figureFormat, 'fig') == true
                    postProcess.makeVisible([dir, '.fig'])
                end
            elseif (outputFigure == 1.0 && algorithm == 10.0 && getappdata(0, 'figure_SIG') == 1.0)
                f12 = figure('visible', figureVisibility);
                oldSignal = getappdata(0, 'SIGOriginalSignal');
                
                plot(oldSignal, '-', 'LineWidth', lineWidth, 'Color', midnightBlue);   hold on
                
                msg = sprintf('SIGS, Uniaxial load history');
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
                
                dir = [root, 'MATLAB Figures/SIGS, Uniaxial load history'];
                saveas(f12, dir, figureFormat)
                if strcmpi(figureFormat, 'fig') == true
                    postProcess.makeVisible([dir, '.fig'])
                end
            end
            
            %% LH LOAD HISTORIES
            if getappdata(0, 'figure_LH') == 1.0 && outputFigure == 1.0 && algorithm ~= 10.0
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
                
                if getappdata(0, 'gateHistories') == 1.0
                    dir = [root, 'MATLAB Figures/LH, Load histories (after pre-gating) at worst item'];
                else
                    dir = [root, 'MATLAB Figures/LH, Load histories at worst item'];
                end
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
            
            % Get the worst analysis item
            worstItem = getappdata(0, 'worstItem');
            
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
            CN = getappdata(0, 'CN');
            CS = getappdata(0, 'CS');
            
            data = [INC; VM; PS1; PS2; PS3; CN; CS]';
            
            %% Open file for writing:
            
            if getappdata(0, 'file_H_OUTPUT_LOAD') == 1.0
                dir = [root, 'Data Files/h-output-load.dat'];
                
                fid = fopen(dir, 'w+');
                
                fprintf(fid, 'WORST ITEM LOAD HISTORIES (%.0f.%.0f)\r\n', worstMainID, worstSubID);
                
                fprintf(fid, 'Units:\tMPa\r\n');
                
                fprintf(fid, 'Load Increment\tVM\tPS1\tPS2\tPS3\tCN\tCS\r\n');
                fprintf(fid, sprintf('%%.0f\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\t%%%s\r\n', h, h, h, h, h, h), data');
                
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
            WCM = getappdata(0, 'WCM');
            
            A = WCA./WCM;
            R = (1.0 - A)./(1.0 + A);
            R(isnan(R) == 1.0) = -1.0;
            
            dataA = [mainID'; subID'; WCM; WCA; R]';
            
            WNM = getappdata(0, 'meansOnCP');
            WNA = getappdata(0, 'amplitudesOnCP');
            
            A = WNA./WNM';
            R = (1.0 - A)./(1.0 + A);
            R(isnan(R) == 1.0) = -1.0;
            
            dataB = [C; WNM'; WNA; R]';
            
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
                
                fprintf(fid, 'ANHD, WORST CYCLE HISTORIES (ALL ITEMS)\t\t\t\t\tHD, ALL CYCLE HISTORIES AT WORST ITEM (%.0f.%.0f)\r\n', worstMainID, worstSubID);
                
                fprintf(fid, 'Units:\tMPa\r\n');
                
                fprintf(fid, 'Item #\tMean stress\tStress amplitude\tLoad ratio\t\tCycle #\tMean stress\tStress amplitude\tLoad ratio\r\n');
                fprintf(fid, sprintf('%%.0f.%%.0f\t%%%s\t%%%s\t%%%s\t\t%%.0f\t%%%s\t%%%s\t%%%s\r\n', h, h, h, h, h, h), [dataA(1.0:shortLength, :), dataB(1.0:shortLength, :)]');
                
                if lengthA > lengthB
                    fprintf(fid, sprintf('%%.0f.%%.0f\t%%%s\t%%%s\t%%%s\r\n', h, h, h), dataA(shortLength + 1.0:end, :)');
                elseif lengthB > lengthA
                    fprintf(fid, sprintf('\t\t\t\t\t%%.0f\t%%%s\t%%%s\t%%%s\r\n', h, h, h), dataB(shortLength + 1.0:end, :)');
                end
                
                fclose(fid);
            end
            
            %{
                ANGLE HISTORIES -> Multiple values at worst item over all
                plane orientations
            %}
            %%
            proportionalItems = getappdata(0, 'proportionalItems');
            
            if proportionalItems(worstItem) == 0.0
                if (algorithm < 7.0) && (algorithm ~= 10.0)
                    step = getappdata(0, 'stepSize');
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
        
        %% Make saved figures visible
        function [] = makeVisible(file)
            f = load(file, '-mat');
            n = fieldnames(f);
            f.(n{1}).properties.Visible = 'on';
            save(file, '-struct', 'f')
        end
        
        %% WRITE PLASTIC ITEMS TO FILE
        function [] = writeLCFItems(life, jobName, mainIDs, subIDs, loadEqUnits)
            % Get the list of items
            lcfItems = find(life < 1e6);
            
            % Get the IDs associated with these items
            N = length(lcfItems);
            lcfMainIDs = zeros(1.0, N);
            lcfSubIDs = lcfMainIDs;
            lcfLife = lcfMainIDs;
            for i = 1:N
                lcfMainIDs(i) = mainIDs(lcfItems(i));
                lcfSubIDs(i) = subIDs(lcfItems(i));
                lcfLife(i) = life(lcfItems(i));
            end
            
            % Concatenate data
            data = [lcfItems; lcfMainIDs; lcfSubIDs; lcfLife]';
            
            % Print information to file
            
            root = getappdata(0, 'outputDirectory');
            
            if exist(sprintf('%s/Data Files', root), 'dir') == 0.0
                mkdir(sprintf('%s/Data Files', root))
            end
            
            dir = [root, 'Data Files/warn_lcf_items.dat'];
            
            fid = fopen(dir, 'w+');
            
            fprintf(fid, 'WARN_LCF_ITEMS\r\n');
            fprintf(fid, 'Job:\t%s\r\nLoading:\t%.3g\t%s\r\n', jobName, getappdata(0, 'loadEqVal'), getappdata(0, 'loadEqUnits'));
            
            fprintf(fid, 'Item #\tMain ID\tSub ID\tLife (%s)\r\n', loadEqUnits);
            fprintf(fid, '%.0f\t%.0f\t%.0f\t%.4e\r\n', data');
            
            fclose(fid);
        end
        
        %% WRITE OVERFLOW ITEMS TO FILE
        function [] = writeOverflowItems(damage, jobName, mainIDs, subIDs)
            % Get the list of items
            overflowItems = find((1./damage) < 1.0);
            
            % Get the IDs associated with these items
            N = length(overflowItems);
            overflowMainIDs = zeros(1, N);
            overflowSubIDs = overflowMainIDs;
            overflowDamage = overflowMainIDs;
            for i = 1:N
                overflowMainIDs(i) = mainIDs(overflowItems(i));
                overflowSubIDs(i) = subIDs(overflowItems(i));
                overflowDamage(i) = damage(overflowItems(i));
            end
            
            % Concatenate data
            data = [overflowItems; overflowMainIDs; overflowSubIDs; overflowDamage]';
            
            % Print information to file
            
            root = getappdata(0, 'outputDirectory');
            
            if exist(sprintf('%s/Data Files', root), 'dir') == 0.0
                mkdir(sprintf('%s/Data Files', root))
            end
            
            dir = [root, 'Data Files/warn_overflow_items.dat'];
            
            fid = fopen(dir, 'w+');
            
            fprintf(fid, 'WARN_OVERFLOW_ITEMS\r\n');
            fprintf(fid, 'Job:\t%s\r\nLoading:\t%.3g\t%s\r\n', jobName, getappdata(0, 'loadEqVal'), getappdata(0, 'loadEqUnits'));
            
            fprintf(fid, 'Item #\tMain ID\tSub ID\tDamage\r\n');
            fprintf(fid, '%.0f\t%.0f\t%.0f\t%.4e\r\n', data');
            
            fclose(fid);
        end
        
        %% WRITE YIELDING ITEMS TO FILE
        function [] = writeYieldingItems(jobName, mainID, subID)
            % Get the list of items which are yielding
            yield = getappdata(0, 'YIELD');
            
            % Convert into list of position IDs
            yield = find(yield == 1.0);
            
            % Get the strain energy associated with the yielding items
            totalStrainEnergy = getappdata(0, 'totalStrainEnergy');
            
            % Initialize the plastic strain energy variable
            plasticStrainEnergy = zeros(1.0, length(yield));
            
            % Calculate the plastic strain energy for each analysis group
            G = getappdata(0, 'numberOfGroups');
            
            % Get the group ID buffer
            groupIDBuffer = getappdata(0, 'groupIDBuffer');
            
            totalCounter = 1.0;
            
            for groups = 1:G
                %{
                    If the analysis is a MAXPS analysis, override the value of GROUP to
                    the group containing the MAXPS item
                %}
                if getappdata(0, 'peekAnalysis') == 1.0
                    groups = getappdata(0, 'peekGroup'); %#ok<FXSET>
                end
                
                if strcmpi(groupIDBuffer(1.0).name, 'default') == 1.0
                    % There is one, default group
                    items = yield;
                else
                    % Assign group parameters to the current set of analysis IDs
                    [~, groupIDs] = group.switchProperties(groups, groupIDBuffer(groups));
                    
                    %{
                        Get the group IDs assiciated with yielding items in
                        the current group
                    %}
                    items = intersect(yield, groupIDs);
                end
                
                if isempty(items) == 1.0
                    %{
                        There are no yielded items in the current group.
                        Continue to the next group
                    %}
                    continue
                else
                    %items = items == yield;
                end
                
                % Get the strain limit energy of the current group
                strainLimitEnergy = getappdata(0, 'strainLimitEnergy');
                
                % Get the plastic strain energy for the current group
                for i = 1:length(items)
                    plasticStrainEnergy(totalCounter) = totalStrainEnergy(items(i)) - strainLimitEnergy;
                    
                    totalCounter = totalCounter + 1.0;
                end
            end
            
            % Only take totalStrainEnergy values for yielding items
            totalStrainEnergy = totalStrainEnergy(yield);
            
            % Get the IDs associated with these items
            mainIDs = mainID(yield);
            subIDs = subID(yield);
            
            % Concatenate data
            data = [yield; mainIDs'; subIDs'; totalStrainEnergy; plasticStrainEnergy]';
            
            % Print information to file
            root = getappdata(0, 'outputDirectory');
            
            if exist(sprintf('%s/Data Files', root), 'dir') == 0.0
                mkdir(sprintf('%s/Data Files', root))
            end
            
            dir = [root, 'Data Files/warn_yielding_items.dat'];
            
            fid = fopen(dir, 'w+');
            
            fprintf(fid, 'WARN_YIELDING_ITEMS\r\n');
            fprintf(fid, 'Job:\t%s\r\nLoading:\t%.3g\t%s\r\n', jobName, getappdata(0, 'loadEqVal'), getappdata(0, 'loadEqUnits'));
            
            fprintf(fid, 'Item #\tMain ID\tSub ID\tTSE, Total Strain Energy (mJ)\tPSE, Plastic Strain Energy (mJ)\r\n');
            fprintf(fid, '%.0f\t%.0f\t%.0f\t%f\t%f\r\n', data');
            
            fclose(fid);
        end
        
        %% WRITE HOTSPOTS TO FILE
        function [] = writeHotSpots(nodalDamage, mainID, subID, jobName, loadEqUnits)
            % Get the design life
            designLife = getappdata(0, 'dLife');
            
            % Convert damage to life
            nodalLife = 1.0./nodalDamage;
            
            % Identify items whose life is below the design life
            hotspots = find(nodalLife < designLife);
            
            % If there are no hotspots, inform the user and RETURN
            if isempty(hotspots) == 1.0
                messenger.writeMessage(138.0)
                return
            end
            
            % Concatenate data
            data = [hotspots; mainID(hotspots)'; subID(hotspots)'; nodalLife(hotspots)]';
            
            % Check that the directory exists
            root = getappdata(0, 'outputDirectory');
            
            if exist(sprintf('%s/Data Files', root), 'dir') == 0.0
                mkdir(sprintf('%s/Data Files', root))
            end
            
            % Create the file
            dir = [pwd, sprintf('\\Project\\output\\%s\\Data Files\\', jobName), 'hotspots.dat'];
            fid = fopen(dir, 'w+');
            
            fprintf(fid, 'HOTSPOTS\r\n');
            fprintf(fid, 'Job:\t%s\r\n', jobName);
            
            fprintf(fid, 'Item #\tMain ID\tSub ID\tLife (%s)\r\n', loadEqUnits);
            fprintf(fid, '%.0f\t%.0f\t%.0f\t%.4e\r\n', data');
            
            fclose(fid);
            
            % Inform the user that hotpots have been written to file
            setappdata(0, 'numberOfHotSpots', length(hotspots))
            messenger.writeMessage(139.0)
        end
        
        %% WRITE COLLAPSED ELEMENTS TO FILE
        function [] = writeCollapsedElements()
            % Get the collapsed elements
            collapsedElements = getappdata(0, 'warning_180_collapsedElements');
            
            % Print information to file
            root = getappdata(0, 'outputDirectory');
            
            if exist(sprintf('%s/Data Files', root), 'dir') == 0.0
                mkdir(sprintf('%s/Data Files', root))
            end
            
            dir = [root, 'Data Files/warn_collapsed_elements.dat'];
            
            fid = fopen(dir, 'w+');
            
            fprintf(fid, 'WARN_COLLAPSED_ELEMENTS\r\n');
            fprintf(fid, 'Job:\t%s\r\nLoading:\t%.3g\t%s\r\n', getappdata(0, 'jobName'), getappdata(0, 'loadEqVal'), getappdata(0, 'loadEqUnits'));
            
            fprintf(fid, 'Element ID\tConnected nodes\r\n');
            
            for i = 1:length(collapsedElements)
                collapsedElement = collapsedElements{i};
                
                fprintf(fid, '%.0f\t', collapsedElement(1.0));
                
                for j = 2:length(collapsedElement) - 2.0
                    fprintf(fid, '%.0f\t', collapsedElement(j));
                end
                
                fprintf(fid, '%.0f\r\n', collapsedElement(end));
            end
            
            fclose(fid);
        end
        
        %% WRITE FIELD DATA TO AN .ODB FILE
        function [] = autoExportODB(fid_status, mainID)
            % Flag to indicate the ODB Interface is operating in auto mode
            setappdata(0, 'ODB_interface_auto', 1.0)
            
            % Get path and name of field data
            fieldDataPath = [getappdata(0, 'outputDirectory'), 'Data Files/f-output-all.dat'];
            [~, fieldDataName, EXT] = fileparts(fieldDataPath);
            fieldDataName = [fieldDataName, EXT];
            
            % Get the abaqus command line
            abqCmd = getappdata(0, 'autoExport_abqCmd');
            if isempty(abqCmd) == 1.0
                abqCmd = 'abaqus';
            end
            
            % Get path and name of model output database
            modelDatabasePath = getappdata(0, 'outputDatabase');
            if isempty(modelDatabasePath) == 1.0
                messenger.writeMessage(33.0)
                return
            elseif exist(modelDatabasePath, 'file') ~= 2.0
                setappdata(0, 'autoExport_modelDatabaseNotFound', modelDatabasePath)
                messenger.writeMessage(81.0)
                return
            end
            [~, modelDatabaseNameShort, ~] = fileparts(modelDatabasePath);
            
            % Print header
            fprintf('\n[POST] Quick Fatigue Tool 6.11-13 ODB Interface');
            fprintf(fid_status, '\n[POST] Quick Fatigue Tool 6.11-13 ODB Interface');
            
            % Warn user if there is only one item in the model
            if length(mainID) == 1.0
                messenger.writeMessage(204.0)
            end
            
            % Get the job name
            jobName = getappdata(0, 'jobName');
            
            % Get name and directory of results output database
            resultsDatabasePath = [getappdata(0, 'outputDirectory'), 'Data Files'];
            resultsDatabaseName = [modelDatabaseNameShort, sprintf('_%s', jobName), 'Results'];
            
            % Get the part instance name
            partInstanceList = getappdata(0, 'partInstance');
            if ischar(partInstanceList) == 1.0
                partInstanceList = cellstr(partInstanceList);
            end
            
            % Get the number of part instances
            nInstances = length(partInstanceList);
            
            % Get the step type
            stepType_m = getappdata(0, 'autoExport_stepType');
            if (stepType_m ~= 1.0) && (stepType_m ~= 2.0)
                stepType_m = 1.0;
            end
            
            if stepType_m == 1.0
                if nInstances > 1.0
                    stepType_m = [1.0, linspace(2.0, 2.0, (nInstances - 1.0))];
                else
                    stepType_m = 1.0;
                end
            else
                stepType_m = linspace(2.0, 2.0, nInstances);
            end
            
            % Get the ODB set settings
            if nInstances > 1.0
                createODBSet = 0.0;
            elseif getappdata(0, 'autoExport_createODBSet') == 1.0
                createODBSet = 1.0;
            else
                createODBSet = 0.0;
            end
            
            % Get the step name
            stepName = getappdata(0, 'stepName');
            
            % Collect requested fields
            %{
                Set the requested fields based on the output selection
                mode. If preselection is enabled, modify the default
                requests accordingly
            %}
            
            % Initialize the preselected default output variables
            requestedFields = [1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0,...
                1.0, 1.0, 1.0, 0.0, 0.0, 0.0, 1.0, 1.0, 0.0, 0.0, 0.0];
            
            switch getappdata(0, 'autoExport_selectionMode')
                case 1.0
                    requestedFields = [getappdata(0, 'autoExport_LL'),...
                        getappdata(0, 'autoExport_L'),...
                        getappdata(0, 'autoExport_D'),...
                        getappdata(0, 'autoExport_DDL'),...
                        getappdata(0, 'autoExport_FOS'),...
                        getappdata(0, 'autoExport_SFA'),...
                        getappdata(0, 'autoExport_FRFR'),...
                        getappdata(0, 'autoExport_FRFV'),...
                        getappdata(0, 'autoExport_FRFH'),...
                        getappdata(0, 'autoExport_FRFW'),...
                        getappdata(0, 'autoExport_SMAX'),...
                        getappdata(0, 'autoExport_SMXP'),...
                        getappdata(0, 'autoExport_SMXU'),...
                        getappdata(0, 'autoExport_TRF'),...
                        getappdata(0, 'autoExport_WCM'),...
                        getappdata(0, 'autoExport_WCA'),...
                        getappdata(0, 'autoExport_WCDP'),...
                        getappdata(0, 'autoExport_WCATAN'),...
                        getappdata(0, 'autoExport_YIELD')];
                case 2.0
                    % If the analysis was BS 7608, disable the FRF
                    if getappdata(0, 'algorithm') == 8.0
                        requestedFields(7.0:10.0) = 0.0;
                    else
                        % If the FOS algorithm is enabled
                        if (getappdata(0, 'enableFOS') == 1.0) && (getappdata(0, 'outputField') == 1.0)
                            requestedFields(5.0) = 1.0;
                        end
                        
                        % If the yield criterion was enabled
                        if (getappdata(0, 'yieldCriteria') == 1.0) || (getappdata(0, 'yieldCriteria') == 2.0)
                            requestedFields(19.0) = 1.0;
                        end
                    end
                case 3.0
                    %{
                        Set all fields to ONE. If the FOS or YIELD were not
                        enabled, do not activate these requests
                    %}
                    requestedFields = ones(1.0, 19.0);
                    
                    if getappdata(0, 'enableFOS') == 0.0
                        requestedFields(5.0) = 0.0;
                    end
                    if getappdata(0, 'yieldCriteria') == 0.0
                        requestedFields(19.0) = 0.0;
                    end
            end
            
            % Open the log file for writing
            fid_debug = fopen([sprintf('Project/output/%s/Data Files/', jobName), resultsDatabaseName, '.log'], 'w+');
            fprintf(fid_debug, 'Quick Fatigue Tool 6.11-13 ODB Interface Log');
            
            % Print Abaqus installation info to the debug log file
            try
                [status, result] = system(sprintf('%s whereami', abqCmd));
                
                if status == 1.0
                    % An exception occurred whilst getting installation info
                    fprintf(fid_debug, '\r\n\r\nError: Abaqus installation info was not found\r\n');
                    fprintf(fid_debug, '\tPlease ensure that the Abaqus command line argument points to a valid Abaqus batch file');
                    fprintf(fid_debug, '\r\n\tAn Abaqus installation is required to write fatigue results to the output database (.odb) file');
                    fprintf(fid_debug, '\r\n\r\nFatigue results have not been written to the output database');
                    fprintf(fid_debug, '\r\n\r\nEND OF FILE');
                else
                    fprintf(fid_debug, '\r\n\r\nAbaqus installation info:\r\n%s', result);
                    fprintf(fid_debug, '(NOTE: The Abaqus version is determined by the autoExport_abqCmd environment variable)\r\n');
                end
            catch exception
                % An unhandled exception was encountered
                fprintf('[POST] ODB Error: %s', exception.message);
                fprintf(fid_status, '[POST] ODB Error: %s', exception.message);
                fprintf('\n[ERROR] ODB Interface exited with errors');
                fprintf(fid_status, '\n[ERROR] ODB Interface exited with errors');
                return
            end
            
            % Verify the inputs
            error = python.verifyAuto(requestedFields,...
                fieldDataPath, fieldDataName, resultsDatabasePath, partInstanceList);
            
            % If there was an error whilst verifying the inputs, stop execution
            if error == 1.0
                return
            end
            
            % Copy the model output database to the abaqus directory
            % Try to upgrade the ODB
            if getappdata(0, 'autoExport_upgradeODB') == 1.0
                [status, result] = system(sprintf('%s -upgrade -job "%s" -odb "%s"', abqCmd, [resultsDatabasePath, '/', resultsDatabaseName], modelDatabasePath(1.0:end - 4.0)));

                if status == 1.0
                    % An exception occurred whilst upgrading the ODB file
                    fprintf('[POST] ODB Error: %s', result);
                    fprintf(fid_status, '\n[POST] ODB Error: %s', result);
                    
                    if isempty(strfind(result, 'is not recognized as an internal or external command,')) == 0.0
                        fprintf('\n[POST] Please ensure that the Abaqus command line argument points to a valid Abaqus batch file');
                        fprintf('\n[POST] An Abaqus installation is required to write fatigue results to the output database (.odb) file');
                        fprintf(fid_status, '\n[POST] Please ensure that the Abaqus command line argument points to a valid Abaqus batch file');
                        fprintf(fid_status, '\n[POST] An Abaqus installation is required to write fatigue results to the output database (.odb) file');
                    end
                    
                    fprintf('\n[ERROR] ODB Interface exited with errors');
                    fprintf(fid_status, '\n[ERROR] ODB Interface exited with errors');
                    return
                end
            end
            
            % If the ODB is already up-to-date, try to copy the file instead
            if exist([resultsDatabasePath, '/', resultsDatabaseName, '.odb'], 'file') == 0.0
                try
                    copyfile(modelDatabasePath, [resultsDatabasePath, '/', resultsDatabaseName, '.odb'])
                catch exception
                    % The file could not be copied
                    fprintf('[POST] ODB Error: %s', exception.message);
                    fprintf(fid_status, '[POST] ODB Error: %s', exception.message);
                    fprintf('\n[ERROR] ODB Interface exited with errors');
                    fprintf(fid_status, '\n[ERROR] ODB Interface exited with errors');
                    return
                end
            end            
            
            % Delete the upgrade log file
            delete([resultsDatabasePath, '/', resultsDatabaseName, '-upgrade', '.log'])
            if exist([pwd, '\', modelDatabaseNameShort, '-upgrade', '.log'], 'file') == 2.0
                delete([pwd, '\', modelDatabaseNameShort, '-upgrade', '.log'])
            end
            
            % Remove the lock file if it exists
            if exist([resultsDatabasePath, '/', modelDatabaseNameShort, '.lck'], 'file') == 2.0
                delete([resultsDatabasePath, '/', modelDatabaseNameShort, '.lck'])
            end
            
            % Get the selected position
            userPosition = getappdata(0, 'odbResultPosition');
            if strcmpi('unique nodal', userPosition) == 1.0
                userPosition = 2.0;
            elseif strcmpi('integration point', userPosition) == 1.0
                userPosition = 3.0;
            elseif strcmpi('centroid', userPosition) == 1.0
                userPosition = 4.0;
            else
                userPosition = 1.0;
            end
            if ischar(userPosition) == 0.0
                if (userPosition ~= 1.0) && (userPosition ~= 2.0) && (userPosition ~= 3.0) && (userPosition ~= 4.0)
                    userPosition = 1.0;
                end
            end
            
            fprintf(fid_debug, '\r\nODB export summary:');
            positions = {'Element-Nodal', 'Unique Nodal', 'Integration Point', 'Centroidal'};
            fprintf(fid_debug, '\r\nUser-selected results position: %s', positions{userPosition});
            
            % Check if position should be determined automatically
            autoPosition = getappdata(0, 'autoExport_autoPosition');
            if autoPosition == 1.0
                fprintf(fid_debug, '\r\nAllow Quick Fatigue Tool to determine results position based on field IDs: YES');
            else
                fprintf(fid_debug, '\r\nAllow Quick Fatigue Tool to determine results position based on field IDs: NO');
            end
            
            if isempty(stepName) == 1.0
                fprintf(fid_debug, '\r\nThe step name was not specified (a default name will be used)');
            else
                fprintf(fid_debug, '\r\nStep name: ''%s''', stepName);
            end
            switch getappdata(0, 'autoExport_selectionMode')
                case 1.0
                    fprintf(fid_debug, '\r\nField output request: SELECTED BY USER');
                case 2.0
                    fprintf(fid_debug, '\r\nField output request: PRESELECTED DEFAULTS');
                case 3.0
                    fprintf(fid_debug, '\r\nField output request: ALL');
            end
            
            for instanceNumber = 1:nInstances
                partInstanceName = partInstanceList{instanceNumber};
                stepType = stepType_m(instanceNumber);
                
                % Get the field data
                fprintf(fid_debug, '\r\n\r\nCollecting field data for instance ''%s''...', partInstanceName);
                fprintf('\n[POST] Collecting field data for instance ''%s''', partInstanceName);
                fprintf(fid_status, '\n[POST] Collecting field data');
                
                [positionLabels, position, positionLabelData, positionID, connectivity,...
                    mainIDs, subIDs, stepDescription, fieldData, fieldNames, fieldDescriptions,...
                    connectedElements, error] = python.getFieldData(fieldDataPath,...
                    requestedFields, userPosition, partInstanceName,...
                    autoPosition, fid_debug, resultsDatabasePath, resultsDatabaseName);
                
                if error > 0.0
                    setappdata(0, 'warning_061_number', error)
                    messenger.writeMessage(85.0)
                    
                    fprintf('\n[ERROR] ODB Interface exited with errors. Check the results log for details (Project/output/%s/Data Files/%s.log)', getappdata(0, 'jobName'), resultsDatabaseName);
                    fprintf(fid_status, '\n[ERROR] ODB Interface exited with errors. Check the results log for details (Project/output/%s/Data Files/%s.log)', getappdata(0, 'jobName'), resultsDatabaseName);
                    
                    % Delete the results output database from the output directory if applicable
                    if exist([pwd, sprintf('\\%s\\%s.odb', resultsDatabasePath, resultsDatabaseName)], 'file') == 2.0
                        delete([pwd, sprintf('\\%s\\%s.odb', resultsDatabasePath, resultsDatabaseName)])
                    end
                    
                    fclose(fid_debug);
                    return
                end
                
                % Create the Python script
                fprintf(fid_debug, '\r\n\r\nPreparing field data...');
                fprintf('\n[POST] Preparing field data:\n');
                fprintf(fid_status, '\n[POST] Preparing field data\n');
                
                % Determine whether the FEA was from an Abaqus/Explicit procedure
                isExplicit = getappdata(0, 'isExplicit');
                if isnumeric(isExplicit) == 0.0
                    isExplicit = 0.0;
                end
                
                % Get ODB set name (if applicable)
                ODBSetName = getappdata(0, 'autoExport_ODBSetName');
                if createODBSet == 1.0
                    if isempty(ODBSetName) == 1.0
                        ODBSetName = sprintf('QFT_%s_%s', partInstanceName, stepName);
                    end
                    if ischar(ODBSetName) == 0.0
                        ODBSetName = sprintf('QFT_%s_%s', partInstanceName, stepName);
                    end
                end
                
                % Write the Python script
                [scriptFile, newLocation, stepName, error] = python.writePythonScript(resultsDatabaseName,...
                    resultsDatabasePath, partInstanceName, positionLabels,...
                    position, positionLabelData, positionID, connectivity, mainIDs,...
                    subIDs, stepDescription, fieldData, fieldNames, fieldDescriptions, fid_debug,...
                    stepName, isExplicit, connectedElements, createODBSet,...
                    ODBSetName, stepType);
                
                % If there was an error while writing the field data, abort the
                % export process
                if error == 1.0
                    setappdata(0, 'warning_087_partInstance', partInstanceName)
                    messenger.writeMessage(87.0)
                    
                    fprintf('\n[ERROR] ODB Interface exited with errors. Check the results log for details (Project/output/%s/Data Files/%s.log)', getappdata(0, 'jobName'), resultsDatabaseName');
                    fprintf(fid_status, '\n[ERROR] ODB Interface exited with errors. Check the results log for details (Project/output/%s/Data Files/%s.log)', getappdata(0, 'jobName'), resultsDatabaseName');
                    
                    fclose(fid_debug);
                    return
                elseif error == 2.0
                    messenger.writeMessage(179.0)
                    
                    fprintf('\n[ERROR] ODB Interface exited with errors. Check the results log for details (Project/output/%s/Data Files/%s.log)', getappdata(0, 'jobName'), resultsDatabaseName');
                    fprintf(fid_status, '\n[ERROR] ODB Interface exited with errors. Check the results log for details (Project/output/%s/Data Files/%s.log)', getappdata(0, 'jobName'), resultsDatabaseName');
                    
                    fclose(fid_debug);
                    return
                end
                
                if getappdata(0, 'warning_180') == 1.0
                    messenger.writeMessage(180.0)
                    postProcess.writeCollapsedElements()
                end
                
                %{
                    If the user requested to retain the python script, copy
                    the file to the results database directory
                %}
                if getappdata(0, 'autoExport_executionMode') > 1.0
                    if nInstances > 1.0
                        copyfile(scriptFile, [resultsDatabasePath, '/', resultsDatabaseName, sprintf('_%s', partInstanceName), '.py'])
                    else
                        copyfile(scriptFile, [resultsDatabasePath, '/', resultsDatabaseName, '.py'])
                    end
                end
                
                % System command to execute python script
                if getappdata(0, 'autoExport_executionMode') < 3.0
                    fprintf(fid_debug, '\r\n\r\nWriting field data to ODB...');
                    fprintf('[POST] Writing field data to ODB');
                    fprintf(fid_status, '[POST] Writing field data to ODB');
                    
                    try
                        [~, message] = system(sprintf('%s python %s', abqCmd, scriptFile));
                        
                        if isempty(message) == 0.0
                            fprintf(fid_status, '\n[POST] ODB Error: %s', message);
                            
                            if isempty(strfind(message, sprintf('KeyError: ''%s''', stepName))) == 0.0
                                % The step name is invalid
                                fprintf('\n[POST] ODB Error: The step name ''%s'' could not be found in the ODB. Results will not be written to the output database.', stepName)
                                fprintf(fid_status, '\n[POST] ODB Error: The step name ''%s'' could not be found in the ODB. Results will not be written to the output database.', stepName);
                            elseif isempty(strfind(message, sprintf('KeyError: ''%s''', partInstanceName))) == 0.0
                                % The part instance name is invalid
                                fprintf('\n[POST] ODB Error: The part instance name ''%s'' could not be found in the ODB. Results will not be written to the output database.', partInstanceName)
                                fprintf(fid_status, '\n[POST] ODB Error: The part instance name ''%s'' could not be found in the ODB. Results will not be written to the output database.', partInstanceName);
                            elseif isempty(strfind(message, 'OdbError: Invalid node label')) == 0.0
                                %{
                                    The field data does not exactly match
                                    the part instance name, so an ODB
                                    element/node set could not be created
                                %}
                                fprintf('\n[POST] ODB Error: The ODB element/node set could not be written because the field data does not exactly match the specified part instance. Results will not be written to the output database.')
                                fprintf(fid_status, '\n[POST] ODB Error: The ODB element/node set could not be written because the field data does not exactly match the specified part instance. Results will not be written to the output database.');
                            elseif isempty(strfind(message, 'is not recognized as an internal or external command')) == 0.0
                                % There is no Abaqus executable on the host machine
                                fprintf('\n[POST] ODB Error: The Abaqus command ''%s'' could not be found on the system. Check your Abaqus installation. Results will not be written to the output database.', abqCmd)
                                fprintf(fid_status, '\n[POST] ODB Error: The Abaqus command ''%s'' could not be found on the system. Check your Abaqus installation. Results will not be written to the output database.', abqCmd);
                            else
                                % Unkown exception
                                fprintf('\n[POST] ODB Error: The Abaqus API returned the following error:\r\n%s\r\nResults will not be written to the output database.', message)
                                fprintf(fid_status, '\n[POST] ODB Error: The Abaqus API returned the following error:\r\n%s\r\nResults will not be written to the output database.', message);
                            end
                            
                            if getappdata(0, 'autoExport_executionMode') == 1.0
                                delete(scriptFile)
                            end
                            
                            % Delete the results output database from the output directory if applicable
                            if exist([pwd, sprintf('\\%s\\%s.odb', resultsDatabasePath, resultsDatabaseName)], 'file') == 2.0
                                delete([pwd, sprintf('\\%s\\%s.odb', resultsDatabasePath, resultsDatabaseName)])
                            end
                            
                            fprintf('\n[ERROR] ODB Interface exited with errors');
                            fprintf(fid_status, '\n[ERROR] ODB Interface exited with errors');
                            return
                        end
                    catch unhandledException
                        fprintf(fid_debug, '\r\nError: %s', unhandledException.message);
                        fprintf('\n[POST] ODB Error: An unknown exception was encountered while writing field data to the output database')
                        fprintf('\n[ERROR] ODB Interface exited with errors');
                        messenger.writeMessage(86.0)
                        
                        fclose(fid_debug);
                        
                        if getappdata(0, 'autoExport_executionMode') == 1.0
                            delete(scriptFile)
                        end
                        return
                    end
                elseif instanceNumber == nInstances
                    delete(newLocation)
                end
            end
            
            fprintf(fid_debug, ' Success\r\n\r\nFatigue results have been written to ''%s''', sprintf('%s/%s.odb', resultsDatabasePath, resultsDatabaseName));
            fprintf(fid_debug, '\r\n\r\nEND OF FILE');
            fprintf('\n[POST] Export complete. Check the log file in Project/output/%s/Data Files for detailed information', getappdata(0, 'jobName'));
            fprintf(fid_status, '\n[POST] Export complete. Check the log file in Project/output/%s/Data Files for detailed information', getappdata(0, 'jobName'));
            fclose(fid_debug);
            
            % Update the message file
            messenger.writeMessage(265.0)
            
            % Delete the Python script from the data directory
            delete(scriptFile)
            
            % Copy the results ODB path to the clipboard
            clipboard('copy', [pwd, sprintf('/Project/output/%s/Data Files/%s.odb', jobName, resultsDatabaseName)])
        end
        
        %% GET THE LARGEST STRESS IN THE LOADING (NEW)
        function [SMAX_item] = getMaximumStress()
            % Get the principal stress history
            s1 = getappdata(0, 'S1');
            s2 = getappdata(0, 'S2');
            s3 = getappdata(0, 'S3');
            
            [N, ~] = size(s1);
            
            % Get the analysis items
            mainID = getappdata(0, 'mainID_original');
            subID = getappdata(0, 'subID_original');
            
            % Initialize variables
            SMAX_ABS = zeros(1.0, N);
            
            % Get the hydrostatic stress
            hydroStress = (1.0/3.0).*(s1 + s2 + s3);
            
            % Get the numerically largest principal stress for each analysis item
            nodalS1 = max(s1, [], 2.0)';
            nodalS3 = min(s3, [], 2.0)';
            nodalS = [nodalS1', nodalS3'];
            
            %{
                The 3D Eigensolver can cause numerical artifacting, which
                occasionally results in the incorrect value of maximum
                stress. Resolve this by correcting any near-zero values
            %}
            diff = abs(1.0 - abs(max(nodalS, [], 2.0)./min(nodalS, [], 2.0)));
            diffLowerBound = diff > 0.0;
            diffUpperBound = diff < 1e-12;
            nearZeroIndices = diffLowerBound == diffUpperBound;
            nodalS1(nearZeroIndices) = -nodalS3(nearZeroIndices);
            
            SMAX_ABS(abs(nodalS1) >= abs(nodalS3)) = nodalS1(abs(nodalS1) >= abs(nodalS3));
            SMAX_ABS(abs(nodalS1) < abs(nodalS3)) = nodalS3(abs(nodalS1) < abs(nodalS3));
            
            if abs(min(SMAX_ABS)) > abs(max(SMAX_ABS))
                MAX_SMAX_ABS = min(SMAX_ABS);
                SMAX_item = find(SMAX_ABS == min(SMAX_ABS));
            else
                MAX_SMAX_ABS = max(SMAX_ABS);
                SMAX_item = find(SMAX_ABS == max(SMAX_ABS));
            end
            
            % If there is more than one value
            if length(SMAX_item) > 1.0
                SMAX_item = SMAX_item(1.0);
            end
            
            setappdata(0, 'SMAX', SMAX_ABS)
            setappdata(0, 'SMAX_ABS', MAX_SMAX_ABS)
            setappdata(0, 'SMAX_mainID', mainID(SMAX_item))
            setappdata(0, 'SMAX_subID', subID(SMAX_item))
            setappdata(0, 'hydrostaticStress', hydroStress)
            
            % Get the normalised stress components
            normStress(SMAX_ABS, mainID, subID)
        end
    end
end