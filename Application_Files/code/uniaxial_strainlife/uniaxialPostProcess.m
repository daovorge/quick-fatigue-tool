classdef uniaxialPostProcess < handle
%UNIAXIALPOSTPROCESS    QFT class for Uniaxial Strain-Life.
%   This class contains methods for the Multiaxial Gauge Fatigue
%   application.
%   
%   UNIAXIALPOSTPROCESS is used internally by Quick Fatigue Tool. The
%   user is not required to run this file.
%   
%   See also uniaxialAnalysis, uniaxialPreProcess, UniaxialStrainLife
%   
%   Reference section in Quick Fatigue Tool Appendices
%      A3.6 Uniaxial Strain-Life
%   
%   Quick Fatigue Tool 6.11-04 Copyright Louis Vallance 2017
%   Last modified 21-Sep-2017 09:00:05 GMT
    
    %%
    
    methods (Static = true)
        %% Write results to the output file
        function [] = outputLog(handles, nCycles, life, cael, analysisTime, gamma, outputPath, dateString)
            setappdata(0, 'uniaxialStrainLife_unableOutput', 0.0)
            
            %% Open the file
            try
                fid = fopen([outputPath, '/results.log'], 'w+');
                if fid == -1.0
                    errordlg('Unable to write output to file. Make sure the results location has read/write access.', 'Quick Fatigue Tool')
                    uiwait
                    setappdata(0, 'uniaxialStrainLife_unableOutput', 1.0)
                    return
                end
            catch
                [message, errorNumber] = ferror(fid);
                message = sprintf('%s\n\nError number: %f', message, errorNumber);
                errordlg(message, 'Quick Fatigue Tool')
            end
            
            %% Header
            % Write file header
            fprintf(fid, 'Quick Fatigue Tool 6.11-04 on machine %s (User is %s)\r\n', char(java.net.InetAddress.getLocalHost().getHostName()), char(java.lang.System.getProperty('user.name')));
            fprintf(fid, '(Copyright Louis Vallance 2017)\r\n');
            fprintf(fid, 'Last modified 21-Sep-2017 09:00:05 GMT\r\n\r\n');
            
            fprintf(fid, 'UNIAXIAL STRAIN-LIFE RESULTS (%s)\r\n', dateString);
            
            %% Gauge definition
            fprintf(fid, '\r\n<INPUT DEFINITION>\r\n');
            fprintf(fid, 'Load history: %s\r\n', get(handles.edit_inputFile, 'string'));
            if get(handles.rButton_stress, 'value') == 1.0
                fprintf(fid, 'Input quantity: Stress (elastic)\r\n');
                fprintf(fid, 'Input units: MPa\r\n');
            else
                if get(handles.rButton_typeElastic, 'value') == 1.0
                    fprintf(fid, 'Input quantity: Strain (elastic)\r\n');
                else
                    fprintf(fid, 'Input quantity: Strain (total)\r\n');
                end
                
                if get(handles.rButon_strainUnitsStrain, 'value') == 1.0
                    fprintf(fid, 'Input units: Strain (E)\r\n');
                else
                    fprintf(fid, 'Input units: Microstrain (uE)\r\n');
                end
            end
            
            %% Material definition
            fprintf(fid, '\r\n<MATERIAL DEFINITION>\r\n');
            fprintf(fid, 'Analysis material: %s\r\n', get(handles.edit_material, 'string'));
            
            %% Analysis definition
            fprintf(fid, '\r\n<ANALYSIS DEFINITION>\r\n');
            fprintf(fid, 'Analysis algorithm: Uniaixal Strain-Life\r\n');
            
            if get(handles.rButton_typeElastic, 'value') == 1.0
                fprintf(fid, 'Stress concentration factor: %f\r\n', str2double(get(handles.edit_scf, 'string')));
            end
            
            switch get(handles.pMenu_msc, 'value')
                case 1.0
                    fprintf(fid, 'Mean stress correction: None\r\n');
                case 2.0
                    fprintf(fid, 'Mean stress correction: Morrow\r\n');
                case 3.0
                    fprintf(fid, 'Mean stress correction: Smith-Watson-Topper\r\n');
                case 4.0
                    fprintf(fid, 'Mean stress correction: Walker (standard values)\r\n');
                    if gamma == -9999.0
                        fprintf(fid, 'Gamma: [FROM LOAD RATIOS]\r\n');
                    else
                        fprintf(fid, 'Gamma: %f\r\n', gamma);
                    end
                case 5.0
                    fprintf(fid, 'Mean stress correction: Walker (regression fit)\r\n');
                    fprintf(fid, 'Gamma: %f\r\n', gamma);
                case 6.0
                    fprintf(fid, 'Mean stress correction: Walker (gamma value)\r\n');
                    fprintf(fid, 'Gamma: %f\r\n', gamma);
            end
            
            %% Results
            fprintf(fid, '\r\n<RESULTS>\r\n');
                
            fprintf(fid, 'Cycles                                    : %.0f\r\n\r\n', nCycles);
            if life > cael
                fprintf(fid, 'Life-Repeats                              : No Damage\r\n\r\n');
                fprintf('Life-Repeats                                : No Damage\n\n');
            elseif life <= 1.0
                fprintf(fid, 'Life-Repeats                              : No Life\r\n\r\n');
                fprintf('Life-Repeats                                : No Life\n\n');
            else
                fprintf(fid, 'Life-Repeats                              : %.0f\r\n\r\n', life);
                fprintf('Life-Repeats                                : %.0f\n\n', life);
            end
            
            hrs = floor(analysisTime/3600);
            mins = floor((analysisTime - (3600*hrs))/60);
            secs = analysisTime - (hrs*3600) - (mins*60);
            c = clock;
            
            fprintf(fid, 'Analysis time                             : %.0f:%.0f:%.3f\r\n\r\n', hrs, mins, secs);
            fprintf(fid, 'FATIGUE ANALYSIS COMPLETE (%s)\r\n\r\n', datestr(datenum(c(1), c(2), c(3), c(4), c(5), c(6))));
            fprintf(fid, '========================================================================================');
            
            % Print summary to command window
            fprintf('Analysis time                               : %.0f:%.0f:%.3f\n\n', hrs, mins, secs)
            fprintf('Fatigue analysis complete (%s)\n\n',...
                datestr(datenum(c(1), c(2), c(3), c(4), c(5), c(6))))
            
            fclose(fid);
        end
        
        function [] = outputMsgBox(nCycles, life, cael, outputPath)
            message1 = sprintf('Analysis complete.\n\n');
            message2 = sprintf('Number of cycles: %.0f\n\n', nCycles);
            if life > 0.5*cael
                message3 = sprintf('Life-Repeats: No damage');
            elseif life <= 1.0
                message3 = sprintf('Life-Repeats: No life');
            else
                message3 = sprintf('Life-Repeats: %.0f', life);
            end
            if getappdata(0, 'uniaxialStrainLife_unableOutput') == 1.0
                message4 = sprintf('\n\nFatigue results were not written to file.');
            else
                message4 = sprintf('\n\nFatigue results have been written to ''%s''', outputPath);
            end
            rmappdata(0, 'uniaxialStrainLife_unableOutput')
            
            if ispc == 1.0
                response = questdlg([message1, message2, message3, message4], 'Quick Fatigue Tool', 'Open results folder', 'Close', 'Open results folder');
                switch response
                    case 'Open results folder'
                        winopen(outputPath);
                    otherwise
                end
            else
                msgbox([message1, message2, message3, message4], 'Quick Fatigue Tool');
            end
        end
        
        %% Output MATLAB figures
        function [] = outputFigures(step, thetaC, signalLength, Exx, Eyy,...
                Ezz, S11, S22, S33, msCorrection, timeHistoryE1, timeHistoryE2, timeHistoryE3)
            %% Output MATLAB figures
            outOfPlane = getappdata(0, 'multiaxialFatigue_outOfPlane');
            
            midnightBlue = [25/255, 25/255, 112/255];
            outputPath = getappdata(0, 'outputPath');
            
            dir = [outputPath, '/MATLAB Figures'];
            if exist(dir, 'dir') == 0.0
                mkdir(dir)
            end
            
            damageParameter = getappdata(0, 'worstNodeDamageParamCube');
            damage = getappdata(0, 'worstNodeDamageCube');
            
            %% PE Principal strain
            f1 = figure('visible', 'off');
            if outOfPlane == 1.0
                subplot(3.0, 1.0, 1.0)
                plot(timeHistoryE1, Exx, '-', 'LineWidth', 1.0, 'Color', midnightBlue);  hold on
                msg = sprintf('PE1, Maximum principal strain');
                ylabel('Strain', 'FontSize', 12.0)
                title(msg, 'FontSize', 14.0)
                set(gca, 'FontSize', 12.0)
                grid on
                
                subplot(3.0, 1.0, 2.0)
                plot(timeHistoryE2, Eyy, '-', 'LineWidth', 1.0, 'Color', midnightBlue)
                msg = sprintf('PE2, Middle principal strain');
                ylabel('Strain', 'FontSize', 12.0)
                title(msg, 'FontSize', 14.0)
                set(gca, 'FontSize', 12.0)
                grid on
                
                subplot(3.0, 1.0, 3.0)
                plot(timeHistoryE3, Ezz, '-', 'LineWidth', 1.0, 'Color', midnightBlue)
                msg = sprintf('PE3, Minimum principal strain');
                ylabel('Strain', 'FontSize', 12.0)
                title(msg, 'FontSize', 14.0)
                set(gca, 'FontSize', 12.0)
                grid on
            else
                subplot(2.0, 1.0, 1.0)
                plot(timeHistoryE1, Exx, '-', 'LineWidth', 1.0, 'Color', midnightBlue);  hold on
                msg = sprintf('PE1, Maximum in-plane principal strain');
                ylabel('Strain', 'FontSize', 12.0)
                title(msg, 'FontSize', 14.0)
                set(gca, 'FontSize', 12.0)
                grid on
                
                subplot(2.0, 1.0, 2.0)
                plot(timeHistoryE2, Eyy, '-', 'LineWidth', 1.0, 'Color', midnightBlue)
                msg = sprintf('PE2, Minimum in-plane principal strain');
                ylabel('Strain', 'FontSize', 12.0)
                title(msg, 'FontSize', 14.0)
                set(gca, 'FontSize', 12.0)
                grid on
            end
            xlabel('Time', 'FontSize', 12.0)
            
            try
                axis tight
            catch
                % Don't tighten the axis
            end
            
            fileName = [dir, '/PE, Correlated Principal strains'];
            saveas(f1, fileName, 'fig')
            postProcess.makeVisible([fileName, '.fig'])
            
            %% PS Principal stress
            
            if msCorrection > 0.0
                f2 = figure('visible', 'off');
                
                if outOfPlane == 1.0
                    subplot(3.0, 1.0, 1.0)
                    plot(timeHistoryE1, S11, '-', 'LineWidth', 1.0, 'Color', midnightBlue)
                    msg = sprintf('PS1, Maximum principal stress');
                    ylabel('Stress [MPa]', 'FontSize', 12.0)
                    title(msg, 'FontSize', 14.0)
                    set(gca, 'FontSize', 12.0)
                    grid on
                    
                    subplot(3.0, 1.0, 2.0)
                    plot(timeHistoryE2, S22, '-', 'LineWidth', 1.0, 'Color', midnightBlue)
                    msg = sprintf('PS2, Middle principal stress');
                    ylabel('Stress [MPa]', 'FontSize', 12.0)
                    title(msg, 'FontSize', 14.0)
                    set(gca, 'FontSize', 12.0)
                    grid on
                    
                    subplot(3.0, 1.0, 3.0)
                    plot(timeHistoryE3, S33, '-', 'LineWidth', 1.0, 'Color', midnightBlue)
                    msg = sprintf('PS3, Minimum principal stress');
                    ylabel('Stress [MPa]', 'FontSize', 12.0)
                    title(msg, 'FontSize', 14.0)
                    set(gca, 'FontSize', 12.0)
                    grid on
                else
                    subplot(2.0, 1.0, 1.0)
                    plot(timeHistoryE1, S11, '-', 'LineWidth', 1.0, 'Color', midnightBlue)
                    msg = sprintf('PS1, Maximum in-plane principal stress');
                    ylabel('Stress [MPa]', 'FontSize', 12.0)
                    title(msg, 'FontSize', 14.0)
                    set(gca, 'FontSize', 12.0)
                    grid on
                    
                    subplot(2.0, 1.0, 2.0)
                    plot(timeHistoryE2, S22, '-', 'LineWidth', 1.0, 'Color', midnightBlue)
                    msg = sprintf('PS2, Minimum in-plane principal stress');
                    ylabel('Stress [MPa]', 'FontSize', 12.0)
                    title(msg, 'FontSize', 14.0)
                    set(gca, 'FontSize', 12.0)
                    grid on
                end
                xlabel('Time', 'FontSize', 12.0)
                
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                
                fileName = [dir, '/PS, Correlated Principal stresses'];
                saveas(f2, fileName, 'fig')
                postProcess.makeVisible([fileName, '.fig'])
            end
            
            %% DPP-THETA (Damage parameter vs THETA)
            
            f3 = figure('visible', 'off');
            
            x = linspace(0.0, 180.0, length(damageParameter));
            
            plot(x, damageParameter, '-', 'LineWidth', 1.0, 'Color', midnightBlue);  hold on
            scatter(thetaC, damageParameter((thetaC+step)/step), 40, 'MarkerEdgeColor', [0.745, 0.0, 0.0],...
                'MarkerFaceColor', [1.0, 0.1, 0.1], 'LineWidth', 1.5);
            
            msg = sprintf('DPP-THETA, Damage parameter vs theta');
            xlabel('Angle [deg]', 'FontSize', 12.0)
            ylabel('Damage parameter [MPa]', 'FontSize', 12.0)
            title(msg, 'FontSize', 14.0)
            set(gca, 'FontSize', 12.0)
            set(gca, 'XTickLabel', 0:45:180);  set(gca, 'XTick', 0:45:180)
            
            try
                axis tight
            catch
                % Don't tighten the axis
            end
            
            grid on
            
            fileName = [dir, '/DPP, Damage parameter vs angle'];
            saveas(f3, fileName, 'fig')
            postProcess.makeVisible([fileName, '.fig'])
            
            %% DP-THETA (Damage vs THETA)
            
            f4 = figure('visible', 'off');
            
            x = linspace(0.0, 180.0, length(damage));
            
            plot(x, damage, '-', 'LineWidth', 1.0, 'Color', midnightBlue);  hold on
            scatter(thetaC, damage((thetaC+step)/step), 40, 'MarkerEdgeColor', [0.745, 0.0, 0.0],...
                'MarkerFaceColor', [1.0, 0.1, 0.1], 'LineWidth', 1.5);
            
            msg = sprintf('DP-THETA, Damage vs theta');
            xlabel('Angle [deg]', 'FontSize', 12.0)
            ylabel(sprintf('Damage [1/Nf]'), 'FontSize', 12.0)
            title(msg, 'FontSize', 14.0)
            set(gca, 'FontSize', 12.0)
            set(gca, 'XTickLabel', 0:45:180);  set(gca, 'XTick', 0:45:180)
            
            try
                axis tight
            catch
                % Don't tighten the axis
            end
            
            grid on
            
            fileName = [dir, '/DP, Damage vs angle'];
            saveas(f4, fileName, 'fig')
            postProcess.makeVisible([fileName, '.fig'])
            
            %% LP-THETA (Life vs THETA)
            
            lifeTheta = 1.0./damage;
            
            f5 = figure('visible', 'off');
            
            x = linspace(0.0, 180.0, length(lifeTheta));
            
            plot(x, lifeTheta, '-', 'LineWidth', 1.0, 'Color', midnightBlue);  hold on
            scatter(thetaC, lifeTheta((thetaC+step)/step), 40, 'MarkerEdgeColor', [0.745, 0.0, 0.0],...
                'MarkerFaceColor', [1.0, 0.1, 0.1], 'LineWidth', 1.5);
            
            msg = sprintf('LP-THETA, Life vs theta');
            xlabel('Angle [deg]', 'FontSize', 12.0)
            ylabel(sprintf('Life Nf'), 'FontSize', 12.0)
            title(msg, 'FontSize', 14.0)
            set(gca, 'FontSize', 12.0)
            set(gca, 'XTickLabel', 0:45:180);  set(gca, 'XTick', 0:45:180)
            
            try
                axis tight
            catch
                % Don't tighten the axis
            end
            
            grid on
            
            fileName = [dir, '/LP, Life vs angle'];
            saveas(f5, fileName, 'fig')
            postProcess.makeVisible([fileName, '.fig'])
            
            %% SHEAR/NORMAL strain VS THETA
            
            %% SHEAR strain VS THETA
            f6 = figure('visible', 'off');
            
            shearStress = getappdata(0, 'shear_cp');
            
            x = linspace(0.0, 180.0, length(shearStress));
            
            subplot(2.0, 1.0, 1.0)
            plot(x, shearStress, '-', 'LineWidth', 1.0, 'Color', midnightBlue);  hold on
            scatter(thetaC, shearStress((thetaC+step)/step), 40, 'MarkerEdgeColor', [0.745, 0.0, 0.0],...
                'MarkerFaceColor', [1.0, 0.1, 0.1], 'LineWidth', 1.5);
            
            msg = sprintf('CPS-THETA, Maximum shear strain vs theta');
            xlabel('Angle [deg]', 'FontSize', 12.0)
            ylabel('strain', 'FontSize', 12.0)
            title(msg, 'FontSize', 14.0)
            set(gca, 'FontSize', 14.0)
            set(gca, 'XTickLabel', 0:45:180);  set(gca, 'XTick', 0:45:180)
            
            try
                axis tight
            catch
                % Don't tighten the axis
            end
            
            grid on
            
            %% NORMAL strain VS THETA
            normalStress = getappdata(0, 'normal_cp');
            
            x = linspace(0.0, 180.0, length(normalStress));
            
            subplot(2.0, 1.0, 2.0)
            plot(x, normalStress, '-', 'LineWidth', 1.0, 'Color', midnightBlue);  hold on
            scatter(thetaC, normalStress((thetaC+step)/step), 40, 'MarkerEdgeColor', [0.745, 0.0, 0.0],...
                'MarkerFaceColor', [1.0, 0.1, 0.1], 'LineWidth', 1.5);
            
            msg = sprintf('CPN-THETA, Normal strain vs theta');
            xlabel('Angle [deg]', 'FontSize', 12.0)
            ylabel('strain', 'FontSize', 12.0)
            title(msg, 'FontSize', 14.0)
            set(gca, 'FontSize', 12.0)
            set(gca, 'XTickLabel', 0:45:180);  set(gca, 'XTick', 0:45:180)
            
            try
                axis tight
            catch
                % Don't tighten the axis
            end
            
            grid on
            
            fileName = [dir, '/CPS, Critical plane strains vs angle'];
            saveas(f6, fileName, 'fig')
            postProcess.makeVisible([fileName, '.fig'])
            
            %% RHIST RAINFLOW HISTOGRAM OF CYCLES
            pairs = getappdata(0, 'cyclesOnCP');
            Sm = 0.5*(pairs(:, 1.0) + pairs(:, 2.0));
            amplitudes = getappdata(0, 'amplitudesOnCP');
            
            f7 = figure('visible', 'off');
            rhistData = [Sm'; 2.0.*amplitudes]';
            hist3(rhistData, [32.0, 32.0])
            
            set(gcf, 'renderer', 'opengl');
            set(get(gca, 'child'), 'FaceColor', 'interp', 'CDataMode', 'auto');
            colorbar
            
            msg = sprintf('RHIST, Rainflow cycle histogram');
            xlabel('Mean Strain', 'FontSize', 12.0)
            ylabel('Strain Range', 'FontSize', 12.0)
            title(msg, 'FontSize', 14.0)
            set(gca, 'FontSize', 12.0)
            
            try
                axis tight
            catch
                % Don't tighten the axis
            end
            
            fileName = [dir, '/RHIST, Rainflow cycle histogram'];
            saveas(f7, fileName, 'fig')
            postProcess.makeVisible([fileName, '.fig'])
            
            %% CN (Normal strain on critical plane)
            
            normalOnCP = getappdata(0, 'CN');
            msg = sprintf('CN, Maximum normal strain history on critical plane');
            
            f8 = figure('visible', 'off');
            subplot(2.0, 1.0, 1.0)
            plot(normalOnCP, '-', 'LineWidth', 1.0, 'Color', [178/255, 34/255, 34/255])
            
            ylabel('Strain', 'FontSize', 12.0)
            title(msg, 'FontSize', 14.0)
            set(gca, 'FontSize', 14.0)
            set(gca, 'XTick', linspace(1.0, signalLength, 4.0 + 1.0))
            set(gca, 'XTickLabel', round(linspace(1.0, signalLength, 4.0 + 1.0)));
            
            try
                axis tight
            catch
                % Don't tighten the axis
            end

            grid on
            
            %% CS (Shear strain on critical plane)
            
            shearOnCP = getappdata(0, 'CS');
            msg = sprintf('CS, Maximum shear strain history on critical plane');
            
            subplot(2.0, 1.0, 2.0)
            plot(shearOnCP, '-', 'LineWidth', 1.0, 'Color', [34/255, 139/255, 34/255])
            
            xlabel('Sample', 'FontSize', 12.0);
            ylabel('Stress [MPa]', 'FontSize', 12.0)
            title(msg, 'FontSize', 14.0)
            set(gca, 'FontSize', 12.0)
            set(gca, 'XTick', linspace(1.0, signalLength, 4.0 + 1.0))
            set(gca, 'XTickLabel', round(linspace(1.0, signalLength, 4.0 + 1.0)));
            
            try
                axis tight
            catch
                % Don't tighten the axis
            end
            
            grid on
            
            fileName = [dir, '/CN + CS, Normal and shear strain on critical plane'];
            saveas(f8, fileName, 'fig')
            postProcess.makeVisible([fileName, '.fig'])

            if msCorrection > 0.0
                %% CSS1 (Cyclic stress-strain for PS1)
                
                % Get the buffers containing the stress-strain curves
                trueStressCurveBuffer = getappdata(0, 'trueStressCurveBuffer_1');
                trueStrainCurveBuffer = getappdata(0, 'trueStrainCurveBuffer_1');
                
                % Get the monotonic stress-strain curve
                stressCurve = trueStressCurveBuffer{1.0};
                strainCurve = trueStrainCurveBuffer{1.0};
                
                for i = 1:length(trueStrainCurveBuffer) - 1.0
                    % Get the cyclic stress-strain curve
                    endStress = stressCurve(end);
                    endStrain = strainCurve(end);
                    
                    stressCurve = [stressCurve, trueStressCurveBuffer{i + 1.0} + endStress]; %#ok<AGROW>
                    strainCurve = [strainCurve, trueStrainCurveBuffer{i + 1.0} + endStrain]; %#ok<AGROW>
                end
                
                f9 = figure('visible', 'off');
                plot(strainCurve, stressCurve, 'lineWidth', 1.0, 'color', midnightBlue)
                msg = sprintf('CSS1, Cyclic stress-strain for PE1 and PS1');
                
                if outOfPlane == 1.0
                    xlabel('Maximum principal strain', 'FontSize', 12.0);
                    ylabel('Maximum principal stress [MPa]', 'FontSize', 12.0)
                else
                    xlabel('Maximum in-plane principal strain', 'FontSize', 12.0);
                    ylabel('Maximum in-plane principal stress [MPa]', 'FontSize', 12.0)
                end
                
                title(msg, 'FontSize', 14.0)
                set(gca, 'FontSize', 12.0)
                
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                
                grid on
                
                fileName = [dir, sprintf('/CSS1, Cyclic stress-strain for PE1 and PS1')];
                saveas(f9, fileName, 'fig')
                postProcess.makeVisible([fileName, '.fig'])
                
                %% CSS2 (Cyclic stress-strain for PS2)
                
                % Get the buffers containing the stress-strain curves
                trueStressCurveBuffer = getappdata(0, 'trueStressCurveBuffer_2');
                trueStrainCurveBuffer = getappdata(0, 'trueStrainCurveBuffer_2');
                
                % Get the monotonic stress-strain curve
                stressCurve = trueStressCurveBuffer{1.0};
                strainCurve = trueStrainCurveBuffer{1.0};
                
                for i = 1:length(trueStrainCurveBuffer) - 1.0
                    % Get the cyclic stress-strain curve
                    endStress = stressCurve(end);
                    endStrain = strainCurve(end);
                    
                    stressCurve = [stressCurve, trueStressCurveBuffer{i + 1.0} + endStress]; %#ok<AGROW>
                    strainCurve = [strainCurve, trueStrainCurveBuffer{i + 1.0} + endStrain]; %#ok<AGROW>
                end
                
                f10 = figure('visible', 'off');
                plot(strainCurve, stressCurve, 'lineWidth', 1.0, 'color', midnightBlue)
                msg = sprintf('CSS2, Cyclic stress-strain for PE2 and PS2');
                
                if outOfPlane == 1.0
                    xlabel('Middle principal strain', 'FontSize', 12.0);
                    ylabel('Middle principal stress [MPa]', 'FontSize', 12.0)
                else
                    xlabel('Minimum in-plane principal strain', 'FontSize', 12.0);
                    ylabel('Minimum in-plane principal stress [MPa]', 'FontSize', 12.0)
                end
                
                title(msg, 'FontSize', 14.0)
                set(gca, 'FontSize', 12.0)
                
                try
                    axis tight
                catch
                    % Don't tighten the axis
                end
                
                grid on
                
                fileName = [dir, '/CSS2, Cyclic stress-strain for PE2 and PS2'];
                saveas(f10, fileName, 'fig')
                postProcess.makeVisible([fileName, '.fig'])
                
                %% CSS3 (Cyclic stress-strain for PS3)
                if outOfPlane == 1.0
                    % Get the buffers containing the stress-strain curves
                    trueStressCurveBuffer = getappdata(0, 'trueStressCurveBuffer_3');
                    trueStrainCurveBuffer = getappdata(0, 'trueStrainCurveBuffer_3');
                    
                    % Get the monotonic stress-strain curve
                    stressCurve = trueStressCurveBuffer{1.0};
                    strainCurve = trueStrainCurveBuffer{1.0};
                    
                    for i = 1:length(trueStrainCurveBuffer) - 1.0
                        % Get the cyclic stress-strain curve
                        endStress = stressCurve(end);
                        endStrain = strainCurve(end);
                        
                        stressCurve = [stressCurve, trueStressCurveBuffer{i + 1.0} + endStress]; %#ok<AGROW>
                        strainCurve = [strainCurve, trueStrainCurveBuffer{i + 1.0} + endStrain]; %#ok<AGROW>
                    end
                    
                    f11 = figure('visible', 'off');
                    plot(strainCurve, stressCurve, 'lineWidth', 1.0, 'color', midnightBlue)
                    msg = sprintf('CSS3, Cyclic stress-strain for PE3 and PS3');
                    xlabel('Minimum principal strain', 'FontSize', 12.0);
                    ylabel('Minimum principal stress [MPa]', 'FontSize', 12.0)
                    title(msg, 'FontSize', 14.0)
                    set(gca, 'FontSize', 12.0)
                    
                    try
                        axis tight
                    catch
                        % Don't tighten the axis
                    end
                    
                    grid on
                    
                    fileName = [dir, '/CSS3, Cyclic stress-strain for PE3 and PS3'];
                    saveas(f11, fileName, 'fig')
                    postProcess.makeVisible([fileName, '.fig'])
                end
            end
        end
        
        %% Export tables
        function [] = outputTables(WCAE, pairE, outputPath, type, dParamS, dParamE, dParamOriginal, dParamGated)
            %%
            %{
                LOAD HISTORIES -> Load history before and after gating
            %}
            LO = length(dParamOriginal);
            LG = length(dParamGated);
            
            %% Open file for writing:
            fid = fopen([outputPath, '/h-output-load.dat'], 'w+');
            
            fprintf(fid, 'LH, INPUT LOAD HISTORY\r\n');
            if type == 1.0
                fprintf(fid, 'Units\tMPa\r\n');
                fprintf(fid, 'Elastic stress (before gating)\tElastic stress (after gating)\r\n');
            else
                fprintf(fid, 'Units\tE\r\n');
                fprintf(fid, 'Inelastic strain (before gating)\tInelastic strain (after gating)\r\n');
            end
            
            if LO > LG
                for i = 1:LG
                    fprintf(fid, '%f\t%f\r\n', dParamOriginal(i), dParamGated(i));
                end
                for i = (LG + 1.0):LO
                    fprintf(fid, '%f\t\r\n', dParamOriginal(i));
                end
            else
                for i = 1:LO
                    fprintf(fid, '%f\t%f\r\n', dParamOriginal(i), dParamGated(i));
                end
                for i = (LO + 1.0):LG
                    fprintf(fid, '\t%f\r\n', dParamGated(i));
                end
            end
            
            fclose(fid);
            
            %%
            %{
                CYCLIC HISTORIES -> Inelastic stress and strain histories
            %}
            data = [dParamE; dParamS]';
            
            %% Open file for writing:
            fid = fopen([outputPath, '/h-output-css.dat'], 'w+');
            
            fprintf(fid, 'CSS, INELASTIC LOAD HISTORIES\r\n');
            fprintf(fid, 'Strain (E)\tStress (MPa)\r\n');
            
            fprintf(fid, '%f\t%f\r\n', data');
            
            fclose(fid);
            
            %%
            %{
                CYCLE HISTORIES -> Worst cycle per item and all cycles at worst
                item
            %}
            WCME = 0.5*(pairE(:, 1.0)' + pairE(:, 2.0)');
            
            C = 1:length(WCME);
            
            data = [C; WCME; WCAE]';
            
            %% Open file for writing:
            fid = fopen([outputPath, '/h-output-cycle.dat'], 'w+');
            
            fprintf(fid, 'HD, ALL CYCLE HISTORIES\r\n');
            fprintf(fid, 'Cycle #\tMean strain (E)\tStrain amplitude (E)\r\n');
            
            fprintf(fid, '%.0f\t%.4f\t%.4f\r\n', data');
            
            fclose(fid);
        end
    end
end