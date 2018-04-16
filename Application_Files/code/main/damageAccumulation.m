classdef damageAccumulation < handle
%DAMAGEACCUMULATION    QFT class for message file.
%   This class contains methods to calculate the accumulated fatigue
%   damage.
%
%   DAMAGEACCUMULATION is used internally by Quick Fatigue Tool. The user
%   is not required to run this file.
%
%   Quick Fatigue Tool 6.12-00 Copyright Louis Vallance 2018
%   Last modified 16-Apr-2018 16:14:08 GMT

    %%

    methods(Static = true)
        
        %% Linear damage accumulation
        function [life] = linear(quotient, b2)
            life = 0.5*quotient^(1.0/2*b2);
        end
        
        %% Nonlinear damage accumulation
        function nonlinear()
            %% Material properties
            Sf = 930.0;
            b = -0.095;
            a0 = 0.0;
            alpha = 0.4;
            enduranceLimit = 1e7;
            
            %% Forward extrapolation (iterative solver)
            forwardExtrapolation = 0.0;
            extrapolationFactor = 0.001;
            
            %% Fatigue loading
            cycles = [451.7364129, 291.6655254];
            quotient = cycles./Sf;
            
            % Reference life for damage accumulation curves
            Nf = 0.5.*quotient.^(1.0/b);
            % Total life from all cycle using Miner's Rule
            linearLife = round(1.0/sum(1.0./Nf));
            
            if linearLife > enduranceLimit
                linearLife = enduranceLimit;
            end
            
            %% Method A (iterative)
            % Initialise damage variable
            nCycles = length(Nf);
            D = 0.0;
            n2 = 0.0;
            iteration = 0.0;
            
            % Calculate number of forward extrapolation cycles
            if forwardExtrapolation == 1.0
                cyclesForward = round(extrapolationFactor*linearLife);
                if cyclesForward < 1.0
                    cyclesForward = 1.0;
                end
            else
                cyclesForward = 1.0;
            end
            
            timer = tic;
            while D < 1.0
                n2 = n2 + cyclesForward;
                iteration = iteration + 1.0;
                
                % Get the damage for the first cycle
                Di = (1.0/0.18).*(a0 + (0.18 - a0).*((n2./Nf(1.0)).^((2.0/3.0).*Nf(1.0).^alpha)));
                
                for i = 2:nCycles
                    %{
                        Find the equivalent number of cycles for the same
                        damage on the next curve
                    %}
                    equivalentCycles = round(Nf(i)*((0.18*Di - a0)/(0.18 - a0))^(1.0/((2.0/3.0)*(Nf(i))^0.4)));
                    
                    Di = (1.0/0.18).*(a0 + (0.18 - a0).*(((n2 + equivalentCycles)./Nf(i)).^((2.0/3.0).*Nf(i).^alpha)));
                end
                
                D = D + (Di - D);
                
                if n2 > enduranceLimit
                    n2 = n2 - cyclesForward;
                    iteration = iteration - 1.0;
                    
                    break
                end
            end
            time = toc(timer);
            
            % If the iterative solver overshot, go back one iteration
            if D > 1.0
                n2 = n2 - cyclesForward;
                iteration = iteration - 1.0;
            end
            
            %% Method B (direct)
%             timer = tic;
%             n2 = linspace(1.0, enduranceLimit, enduranceLimit);
%             nCycles = length(Nf);
%             F = zeros(nCycles, enduranceLimit);
%             for i = 1:nCycles
%                 F(i, :) = (1.0./0.18).*(a0 + (1.0./(1.0 + (2.0./3.0).*(Nf(i).^0.4))).*((0.18 - a0).*n2.*(n2./Nf(i)).^((2.0./3.0).*Nf(i).^0.4)));
%             end
%             [A, n2] = min(abs(F - 1.0));
%             if A == 1.0
%                 n2 = enduranceLimit;
%             elseif F(n2) > 1.0
%                 n2 = n2 - 1.0;
%             end
%             time2 = toc(timer);
            
            %% Plot result (debug)
%             nRatios = linspace(0.0, 1.0, index + 1.0);
%             P1 = plot(nRatios, [0.0, d_buffer], '-r', 'linewidth', 2.0);
%             hold on
%             P2 = plot([0.0, 1.0], [0.0, 1.0], '-g', 'linewidth', 2.0);
%             axis tight; grid
%             legend([P1, P2], 'Nonlinear Life', 'Linear Life')
%             xlabel('Cycle ratio (n/Nf)');  ylabel('Damage')
            
            %% Print result to command window
            fprintf('Nonlinear Life (Method A) = %.0f cycles, %.0f iterations (%fs)\n', n2, iteration, time)
%             fprintf('Nonlinear Life (Method B) = %.0f cycles (%fs)\n', n2, time2)
            fprintf('Linear Life = %.0f cycles\n', linearLife)
        end
        
        %% Tabular damage accumulation
        function tabular()
            %% Get user-defined damage accumulation data
            % Damage acculumation file
            damageAccumulationFile = 'data.txt';
            
            % Check quality of data
            [damageAccumulationData, error] = damageAccumulation.tabularCheck(damageAccumulationFile);
            
            % Check error status
            if error == 1.0
                return
            end
            
            % Sort the damage accumulation data
            nOverNf_values = damageAccumulationData(:, 1.0);
            D_values = damageAccumulationData(:, 2.0);
            
            %% Material properties
            Sf = 930.0;
            b = -0.095;
            enduranceLimit = 1e7;
            
            %% Forward extrapolation (iterative solver)
            forwardExtrapolation = 1.0;
            extrapolationFactor = 0.001;
            
            %% Fatigue loading
            cycles = 451.7364129;
            quotient = cycles./Sf;
            
            % Reference life for damage accumulation curves
            Nf = 0.5.*quotient.^(1.0/b);
            % Total life from all cycle using Miner's Rule
            linearLife = round(1.0/sum(1.0./Nf));
            
            %% Method A (new iterative)
            % Initialise damage variable
            nCycles = length(Nf);
            D = 0.0;
            n = 0.0;
            iteration = 0.0;
            
            d_buffer = []; % Debug
            
            % Calculate number of forward extrapolation cycles
            if forwardExtrapolation == 1.0
                cyclesForward = round(extrapolationFactor*linearLife);
                if cyclesForward < 1.0
                    cyclesForward = 1.0;
                end
            else
                cyclesForward = 1.0;
            end
            
            timer = tic;
            while D < 1.0
                n = n + cyclesForward;
                iteration = iteration + 1.0;
                
                % Get the damage for the first cycle
                Di = interp1(nOverNf_values, D_values, (n/Nf(1.0)), 'linear', 'extrap');
                
                for i = 2:nCycles
                    %{
                        Find the equivalent number of cycles for the same
                        damage on the next curve
                    %}
                    equivalentCycles = round(interp1(D_values, nOverNf_values, Di));
                    Di = interp1(nOverNf_values, D_values, ((n + equivalentCycles)/Nf(i)), 'linear', 'extrap');
                end
                
                D = D + (Di - D);
                
                d_buffer(iteration) = D; %#ok<AGROW> % Debug
                
                if n > enduranceLimit
                    n = n - cyclesForward;
                    iteration = iteration - 1.0;
                    
                    break
                end
            end
            time = toc(timer);
            
            % If the iterative solver overshot, go back one iteration
            if D > 1.0
                d_buffer(end) = []; % Debug
                n = n - cyclesForward;
                iteration = iteration - 1.0;
            end
            
            %% Plot result (debug)
            nRatios = linspace(0.0, 1.0, iteration + 1.0);
            P1 = plot(nRatios, [0.0, d_buffer], '-r', 'linewidth', 2.0);
            hold on
            P2 = plot([0.0, 1.0], [0.0, 1.0], '-g', 'linewidth', 2.0);
            axis tight; grid
            legend([P1, P2], 'Nonlinear Life', 'Linear Life')
            xlabel('Cycle ratio (n/Nf)');  ylabel('Damage')
            
            %% Print result to command window
            fprintf('Nonlinear Life (Method A) = %.0f cycles, %.0f iterations (%fs)\n', n, iteration, time)
            fprintf('Linear Life = %.0f cycles\n', linearLife)
        end
        
        %% Check tabular damage accumulation data
        function [damageAccumulationData, error] = tabularCheck(damageAccumulationFile)
            error = 0.0;
            setappdata(0, 'damageAccumulationFile', damageAccumulationFile)
            
            if exist(damageAccumulationFile, 'file') == 0.0
                % Check that the file file exists
                setappdata(0, 'E049', 1.0)
                error = 1.0;
                
                return
            else
                %% FILE OPEN CHECK
                try
                    damageAccumulationData = dlmread(damageAccumulationFile);
                catch errorMessage
                    setappdata(0, 'E050', 1.0)
                    setappdata(0, 'error_log_050_message', errorMessage)
                    error = 1.0;
                    
                    return
                end
                
                %% COLUMN NUMBER CHECK
                [rows, cols] = size(damageAccumulationData);
                if cols ~= 2.0
                    error = 1.0;
                    setappdata(0, 'E139', 1.0)
                    
                    return
                end
                
                % Get the (n/Nf) and D values
                nNf_values = damageAccumulationData(:, 1.0);
                D_values = damageAccumulationData(:, 2.0);
                
                %% MINIMUM PAIR CHECK
                if rows < 2.0
                    error = 1.0;
                    setappdata(0, 'E140', 1.0)
                    
                    return
                end
                
                %% n/Nf OVER-UNITY CHECK
                if any(nNf_values > 1.0) == 1.0
                    error = 1.0;
                    setappdata(0, 'E140', 1.0)
                    
                    return
                end
                
                %% D OVER-UNITY CHECK
                if any(D_values > 1.0) == 1.0
                    error = 1.0;
                    setappdata(0, 'E140', 1.0)
                    
                    return
                end
                
                %% INCREASING n/Nf CHECK
                for i = 2:rows
                    if nNf_values(i) <= nNf_values(i - 1.0)
                        setappdata(0, 'E048', 1.0)
                        error = 1.0;
                        
                        return
                    end
                end
                
                %% NEGATIVE n/Nf-D CHECK
                if (any(D_values < 0.0) == 1.0) || (any(nNf_values < 0.0) == 1.0)
                    error = 1.0;
                    setappdata(0, 'E138', 1.0)
                    
                    return
                end
                
                %% INTERMEDIATE POINT CHECK
                if length(D_values) > 2.0
                    markForDelete = [];
                    
                    for i = 2:length(D_values) - 1.0
                        m1 = (D_values(i) - D_values(i - 1.0))/(nNf_values(i) - nNf_values(i - 1.0));
                        m2 = (D_values(i + 1.0) - D_values(i))/(nNf_values(i + 1.0) - nNf_values(i));
                        
                        if (m1/m2 < 1.000000000000007) && (m1/m2 > 0.999999999999993)
                            markForDelete = [markForDelete, i]; %#ok<AGROW>
                        end
                    end
                    
                    D_values(markForDelete) = [];
                    nNf_values(markForDelete) = [];
                end
                
                %% ADJACENT D VALUE CHECK
                %{
                    If there are any adjacent D values, adjust them so
                    that the neighbouring value is very slightly
                    different
                %}
                message240Warning = 0.0;
                
                index = 1.0;
                maxIterations = length(D_values);
                while index < (maxIterations - 1.0)
                    if D_values(index) == D_values(index + 1.0)
                        if maxIterations == 2.0
                            % e.g. [1.0, 1.0]
                            D_values(index + 1.0) = D_values(index + 1.0) + 1e-6;
                        elseif (index + 1.0 == maxIterations) && (D_values(index - 1.0) < D_values(index))
                            % e.g. [..., 1.0, 2.0, 2.0]
                            D_values(index) = D_values(index) - 1e-6;
                        elseif (index + 1.0 == maxIterations) && (D_values(index - 1.0) > D_values(index))
                            % e.g. [..., 2.0, 1.0, 1.0]
                            D_values(index) = D_values(index) + 1e-6;
                        elseif (index == 1.0) && (D_values(index + 2.0) > D_values(index + 1.0))
                            % e.g. [1.0, 1.0, 2.0,...]
                            D_values(index + 1.0) = D_values(index + 1.0) + 1e-6;
                        elseif (index == 1.0) && (D_values(index + 2.0) < D_values(index + 1.0))
                            % e.g. [2.0, 2.0, 1.0,...]
                            D_values(index + 1.0) = D_values(index + 1.0) - 1e-6;
                        elseif D_values(index + 2.0) < D_values(index + 1.0)
                            % e.g. [..., 2.0, 2.0, 1.0,...]
                            D_values(index + 1.0) = D_values(index + 1.0) - 1e-6;
                        elseif D_values(index + 2.0) > D_values(index + 1.0)
                            % e.g. [..., 1.0, 1.0, 2.0,...]
                            D_values(index + 1.0) = D_values(index + 1.0) + 1e-6;
                        elseif D_values(index + 2.0) == D_values(index + 1.0)
                            % e.g. [..., 1.0, 1.0, 1.0,...]
                            if nNf_values(index + 1.0) ~= 0.0
                                D_values(index + 1.0) = [];
                                nNf_values(index + 1.0) = [];
                                
                                maxIterations = maxIterations - 1.0;
                            elseif D_values(index - 1.0) < D_values(index)
                                D_values(index) = D_values(index + 1.0) - 1e-6;
                            else
                                D_values(index) = D_values(index + 1.0) + 1e-6;
                            end
                        end
                        
                        message240Warning = 1.0;
                        
                        index = index + 1.0;
                    else
                        index = index + 1.0;
                    end
                end
                
                % Warn the user if applicable
                if message240Warning == 1.0
                    messenger.writeMessage(240.0)
                end
                
                %% UNCLOSED ENVELOPE CHECK
                if (nNf_values(end) < 0.0) && (D_values(end) > 0.0)
                    messenger.writeMessage(241.0)
                end
                
                %% D VALUE CURVATURE CHECK
                positiveIndexes = nNf_values > 0.0;
                D_values_p = D_values(positiveIndexes);
                sm_values_p = nNf_values(positiveIndexes);
                
                if isempty(D_values_p) == 0.0
                    for i = 1:length(D_values_p)
                        %{
                            Get the equation of the straight line from the
                            origin to the current D-n/Nf value
                        %}
                        i2 = length(D_values_p) - (i - 1.0);
                        for j = 1:(i - 1.0)
                            j2 = length(D_values_p) - (j - 1.0);
                            if D_values_p(j2) <= ((D_values_p(i2)/sm_values_p(i2))*sm_values_p(j2))
                                error = 1.0;
                                setappdata(0, 'E137', 1.0)
                                
                                return
                            end
                        end
                    end
                end
            end
            
            %% CONCATENATE NEW n/Nf-D VALUES
            damageAccumulationData = [nNf_values, D_values];
            setappdata(0, 'damageAccumulationData', damageAccumulationData)
        end
    end
end