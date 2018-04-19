classdef damageAccumulation < handle
%DAMAGEACCUMULATION    QFT class for message file.
%   This class contains methods to calculate the accumulated fatigue
%   damage.
%
%   DAMAGEACCUMULATION is used internally by Quick Fatigue Tool. The user
%   is not required to run this file.
%
%   Quick Fatigue Tool 6.12-00 Copyright Louis Vallance 2018
%   Last modified 17-Apr-2018 14:49:17 GMT

    %%

    methods(Static = true)
        
        %% Linear damage accumulation
        function [life] = linear(quotient, b2)
            life = 0.5*quotient^(1.0/2*b2);
        end
        
        %% Nonlinear damage accumulation
        function nonlinear()
            clc
            
            %% Material properties
            Sf = 930.0;
            b = -0.095;
            a0 = 0.0;
            alpha = 0.4;
            enduranceLimit = 1e7;
            
            %% Forward extrapolation (iterative solver)
            forwardExtrapolation = 1.0;
            minCycleIncremnet = 1.0;
            maxCycleIncremnet = 1e5;
            maxCycles = 500.0;
            maxIterations = 200.0;
            extrapolationTolerance = 1.0;
            
            %% Constants
            tol = 1.110223024625157e-16;
            
            %% Fatigue loading
            cycles = [350, 200, 240];
            quotient = cycles./Sf;
            
            % Reference life for damage accumulation curves
            Nf = 0.5.*quotient.^(1.0/b);
            % Total life from all cycle using Miner's Rule
            linearLife = round(1.0/sum(1.0./Nf));
            
            if linearLife > enduranceLimit
                linearLife = enduranceLimit;
            end
            
            %% Iterative solver
            % Initialise damage variable
            nCycles = length(Nf);
            D = 0.0;
            n2 = 0.0;
            iteration = 0.0;
            hitEndurance = 0.0;
            
            % Calculate number of forward extrapolation cycles
            if forwardExtrapolation == 1.0
                cyclesForward = maxCycles;
            else
                cyclesForward = 1.0;
            end
            
            % Track iteration-by-iteraion damage values
            d_buffer = [];
            % Track iteration-by-iteraion cycle numbers
            cf_buffer = [];
            
            timer = tic;
            while (D + tol) < 1.0
                n2 = n2 + cyclesForward;
                iteration = iteration + 1.0;
                
                % Get the damage for the first cycle
                D = (1.0/0.18).*(a0 + (0.18 - a0).*((n2./Nf(1.0)).^((2.0/3.0).*Nf(1.0).^alpha)));
                
                for i = 2:nCycles
                    %{
                        Find the equivalent number of cycles for the same
                        damage on the next curve
                    %}
                    equivalentCycles = round(Nf(i)*((0.18*D - a0)/(0.18 - a0))^(1.0/((2.0/3.0)*(Nf(i))^0.4)));
                    
                    D = (1.0/0.18).*(a0 + (0.18 - a0).*(((n2 + equivalentCycles)./Nf(i)).^((2.0/3.0).*Nf(i).^alpha)));
                end
                
                if (n2 > enduranceLimit)
                    %{
                        The endurance limit has been reached, so abandon
                        the calculation
                    %}
                    n2 = n2 - cyclesForward;
                    iteration = iteration - 1.0;
                    
                    % Update the damage buffer
                    d_buffer(iteration) = D; %#ok<AGROW>
                    
                    % Base solution quality on the endurance limit
                    hitEndurance = 1.0;
                    
                    break
                elseif (forwardExtrapolation == 1.0) && (iteration == maxIterations)
                    %{
                        The maximum number of iterations has been reached,
                        so abandon the calculation
                    %}
                    
                    % Update the damage buffer
                    d_buffer(iteration) = D; %#ok<AGROW>
                    cf_buffer = [cf_buffer, cyclesForward]; %#ok<AGROW>
                    
                    break
                end
                
                % Adjust the forward damage extrapolation if necessary
                if forwardExtrapolation == 1.0
                    if D > extrapolationTolerance
                        while D > extrapolationTolerance
                            %{
                                The current damage increment exceeds the
                                damage extrapolation tolerance. Reduce the
                                number of cycles if possible, and retry the
                                iteration
                            %}
                            if (0.25*cyclesForward) >= minCycleIncremnet
                                % Reverse the cycle number
                                n2 = n2 - cyclesForward;
                                
                                cyclesForward = round(0.25*cyclesForward);
                                
                                % Increment the cycle with the new value
                                n2 = n2 + cyclesForward;
                                
                                % Get the damage for the first cycle in the loading
                                D = (1.0/0.18).*(a0 + (0.18 - a0).*((n2./Nf(1.0)).^((2.0/3.0).*Nf(1.0).^alpha)));
                                
                                for i = 2:nCycles
                                    %{
                                        Find the equivalent number of
                                        cycles for the same damage on the
                                        next curve
                                    %}
                                    equivalentCycles = round(Nf(i)*((0.18*D - a0)/(0.18 - a0))^(1.0/((2.0/3.0)*(Nf(i))^0.4)));
                                    
                                    D = (1.0/0.18).*(a0 + (0.18 - a0).*(((n2 + equivalentCycles)./Nf(i)).^((2.0/3.0).*Nf(i).^alpha)));
                                end
                            else
                                %{
                                    The number of forawrd extrapolation
                                    cycles cannnot be reduced any further.
                                    Accpet the current damage solution
                                %}
                                break
                            end
                        end
                    elseif D < (0.5*extrapolationTolerance)
                        %{
                            The current damage increment is less than 50%
                            of the damage extrapolation tolerance. Increase
                            the number of cycles
                        %}
                        if cyclesForward + 0.25*cyclesForward <= maxCycleIncremnet
                            cyclesForward = cyclesForward + round(0.25*cyclesForward);
                        end
                    end
                end
                
                % Update the damage buffer
                d_buffer(iteration) = D; %#ok<AGROW>
                cf_buffer = [cf_buffer, cyclesForward]; %#ok<AGROW>
            end
            time = toc(timer);
            
            if (D + tol >= 1.0) && (iteration == 1.0)
                % The loading resulted in non-fatigue failure
                n2 = n2 - cyclesForward;
                iteration = 1.0;
                d_buffer(end) = 1.0;
            elseif (D + tol) > 1.0
                % If the iterative solver overshot, go back one iteration
                n2 = n2 - cyclesForward;
                iteration = iteration - 1.0;
                d_buffer(end) = [];
                cf_buffer(end) = [];
            end
            
            %% Plot result (debug)
            clf
            
            subplot(1.0, 2.0, 1.0)
            nRatios = linspace(0.0, 1.0, iteration + 1.0);
            P1 = plot(nRatios, [0.0, d_buffer], '-r', 'linewidth', 2.0);
            hold on
            P2 = plot([0.0, 1.0], [0.0, 1.0], '-g', 'linewidth', 2.0);
            axis tight; grid on
            legend([P1, P2], 'Nonlinear Life', 'Linear Life')
            xlabel('Cycle ratio (n/Nf)');  ylabel('Damage')
            
            subplot(1.0, 2.0, 2.0)
            plot(linspace(1.0, length(cf_buffer), length(cf_buffer)), cf_buffer, '-r', 'linewidth', 2.0);
            xlabel('Iteration');  ylabel('Cycle increment size')
            axis tight; grid on
            
            %% Print result to command window (debug)
            fprintf('Nonlinear Life = %.0f cycles, %.0f iterations, D = %f, (%fs)\n', n2, iteration, d_buffer(end), time)
            fprintf('Linear Life = %.0f cycles\n', linearLife)
            
            if hitEndurance == 1.0
                quality = 1.0 - abs(d_buffer(end) - (1.0/linearLife));
            else
                quality = 1.0 - abs(d_buffer(end) - 1.0);
            end
            
            if quality < 0.5
                fprintf('BAD QUALITY (%.0f)\n', quality*100.0)
            else
                fprintf('QUALITY = %.0f\n', quality*100.0)
            end
        end
        
        %% Tabular damage accumulation
        function tabular()
            %% Get user-defined damage accumulation data
            % Damage acculumation file
            damageAccumulationFile = 'data.txt';
            
            % Check quality of data
            [damageAccumulationData, damageAccumulationLives, error] = damageAccumulation.tabularCheck(damageAccumulationFile);
            
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
                D = interp1(nOverNf_values, D_values, (n/Nf(1.0)), 'linear', 'extrap');
                
                for i = 2:nCycles
                    %{
                        Find the equivalent number of cycles for the same
                        damage on the next curve
                    %}
                    equivalentCycles = round(interp1(D_values, nOverNf_values, D));
                    D = interp1(nOverNf_values, D_values, ((n + equivalentCycles)/Nf(i)), 'linear', 'extrap');
                end
                
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
        function [damageAccumulationData, damageAccumulationLives, error] = tabularCheck(damageAccumulationFile)
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
                if cols < 3.0
                    error = 1.0;
                    setappdata(0, 'E139', 1.0)
                    
                    return
                end
                
                % Get the (n/Nf) and D values
                nNf_values = damageAccumulationData(2.0:end, 1.0);
                D_values = damageAccumulationData(2.0:end, 2.0:end);
                
                %% MINIMUM PAIR CHECK
                if rows < 3.0
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
                for i = 2:(rows - 1.0)
                    if nNf_values(i) <= nNf_values(i - 1.0)
                        setappdata(0, 'E048', 1.0)
                        error = 1.0;
                        
                        return
                    end
                end
                
                %% NEGATIVE n/Nf CHECK
                if any(nNf_values < 0.0) == 1.0
                    error = 1.0;
                    setappdata(0, 'E138', 1.0)
                    
                    return
                end
                
                %% NEGATIVE D CHECK
                if any(D_values < 0.0) == 1.0
                    error = 1.0;
                    setappdata(0, 'E138', 1.0)
                    
                    return
                end
                
                %% ADJACENT D VALUE CHECK
                %{
                    If there are any adjacent D values, adjust them so
                    that the neighbouring value is very slightly
                    different
                %}
                message240Warning = 0.0;
                maxIterations = length(D_values);
                
                for i = 1:(cols - 1.0)
                    index = 1.0;
                    
                    while index < (maxIterations - 1.0)
                        if D_values(index, i) == D_values(index + 1.0, i)
                            if maxIterations == 2.0
                                % e.g. [1.0, 1.0]
                                D_values(index + 1.0, i) = D_values(index + 1.0, i) + 1e-6;
                            elseif (index + 1.0 == maxIterations) && (D_values(index - 1.0, i) < D_values(index, i))
                                % e.g. [..., 1.0, 2.0, 2.0]
                                D_values(index, i) = D_values(index, i) - 1e-6;
                            elseif (index + 1.0 == maxIterations) && (D_values(index - 1.0, i) > D_values(index, i))
                                % e.g. [..., 2.0, 1.0, 1.0]
                                D_values(index, i) = D_values(index, i) + 1e-6;
                            elseif (index == 1.0) && (D_values(index + 2.0, i) > D_values(index + 1.0, i))
                                % e.g. [1.0, 1.0, 2.0,...]
                                D_values(index + 1.0, i) = D_values(index + 1.0, i) + 1e-6;
                            elseif (index == 1.0) && (D_values(index + 2.0, i) < D_values(index + 1.0, i))
                                % e.g. [2.0, 2.0, 1.0,...]
                                D_values(index + 1.0, i) = D_values(index + 1.0, i) - 1e-6;
                            elseif D_values(index + 2.0, i) < D_values(index + 1.0, i)
                                % e.g. [..., 2.0, 2.0, 1.0,...]
                                D_values(index + 1.0, i) = D_values(index + 1.0, i) - 1e-6;
                            elseif D_values(index + 2.0, i) > D_values(index + 1.0, i)
                                % e.g. [..., 1.0, 1.0, 2.0,...]
                                D_values(index + 1.0, i) = D_values(index + 1.0, i) + 1e-6;
                            elseif D_values(index + 2.0, i) == D_values(index + 1.0, i)
                                % e.g. [..., 1.0, 1.0, 1.0,...]
                                if D_values(index - 1.0, i) < D_values(index, i)
                                    D_values(index, i) = D_values(index + 1.0, i) - 1e-6;
                                else
                                    D_values(index, i) = D_values(index + 1.0, i) + 1e-6;
                                end
                            end
                            
                            message240Warning = 1.0;
                            
                            index = index + 1.0;
                        else
                            index = index + 1.0;
                        end
                    end
                end
                
                % Warn the user if applicable
                if message240Warning == 1.0
                    messenger.writeMessage(240.0)
                end
            end
            
            %% CONCATENATE NEW n/Nf-D VALUES
            damageAccumulationLives = damageAccumulationData(1.0, 1:(end - 1.0));
            damageAccumulationData = [nNf_values, D_values];
            setappdata(0, 'damageAccumulationData', damageAccumulationData)
            setappdata(0, 'damageAccumulationLives', damageAccumulationLives)
        end
    end
end