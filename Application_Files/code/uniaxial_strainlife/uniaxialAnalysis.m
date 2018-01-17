classdef uniaxialAnalysis < handle
%UNIAXIALANALYSIS    QFT class for Uniaxial Strain-Life.
%   This class contains methods for the Uniaxial Strain-Life application.
%   
%   UNIAXIALANALYSIS is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%   
%   See also uniaxialPostProcess, uniaxialPreProcess, UniaxialStrainLife
%   
%   Reference section in Quick Fatigue Tool Appendices
%      A3.6 Uniaxial Strain-Life
%   
%   Quick Fatigue Tool 6.11-11 Copyright Louis Vallance 2017
%   Last modified 19-Jun-2017 13:56:11 GMT
    
    %%
    
    methods (Static = true)
        %% Entry function for Uniaxial Strain-Life
        function [damage, nCycles, error, amplitudes_strain, pairs_strain, damageParameter_stress, damageParameter_strain, damageParameter] = main(damageParameter, cael, E, Sf, b, Ef, c, kp, np, gamma, msCorrection, L, ndEndurance, fatigueLimitSress, scf, type)
            %% Initialize variables
            damage = 0.0;
            nCycles = 0.0;
            error = 0.0;
            errorA = 0.0;
            errorB = 0.0;
            amplitudes_strain = [];
            pairs_strain = [];
            
            %% Convert the uniaxial stress into uniaxial strain
            % Gate the tensors
            damageParameter = analysis.gateTensors(damageParameter, 2.0, 5.0);
            
            % Convert the elastic stress into inelastic strain
            if type == 1.0
                %{
                    Get the nonlinear elastic stress and strain history
                    from the elastic stress or strain history
                %}
                [rfData, damageParameter_strain, damageParameter_stress, errorA, errorB] = css2c(damageParameter, E, kp, np, scf);
            else
                %{
                    Get the nonlinear elastic stress history from the
                    nonlinear elastic strain history
                %}
                [rfData, damageParameter_stress, ~, ~] = uniaxialPreProcess.getInelasticStressFromInelasticStrain(damageParameter, E, kp, np);
                damageParameter_strain = damageParameter;
            end
            
            % Check for errors
            if errorA == 1.0
                error = 1.0;
                return
            elseif errorB == 1.0
                error  = 2.0;
                return
            end
            
            %% Rainflow count the stress
            if L < 3.0
                % If the signal length is less than 3, there is no need to cycle count
                cycles_stress = 0.5*abs(max(damageParameter_stress) - min(damageParameter_stress));
                cycles_strain = 0.5*abs(max(damageParameter_strain) - min(damageParameter_strain));
                
                pairs_stress = [min(damageParameter_stress), max(damageParameter_stress)];
                pairs_strain = [min(damageParameter_strain), max(damageParameter_strain)];
            else
                % Get rainflow pairs from rfData
                pairs_stress = rfData(:, 1.0:2.0);
                pairs_strain = rfData(:, 3.0:4.0);
                
                % Get the amplitudes from the rainflow pairs
                [cycles_stress, ~] = analysis.getAmps(pairs_stress);
                [cycles_strain, ~] = analysis.getAmps(pairs_strain);
            end
            
            %% Store worst cycles for current item
            amplitudes_strain = cycles_strain;
            
            %% Get the number of cycles
            nCycles = length(amplitudes_strain);
            
            %% Perform a mean stress correction on the nodal damage parameter if necessary
            if msCorrection > 1.0
                largestPair = find(cycles_stress == max(cycles_stress));
                [~, ~, ~, ~, ~, ~] = uniaxialAnalysis.msc(max(cycles_strain), pairs_stress(largestPair(1.0), :), msCorrection, gamma, Sf);
            end
            
            %% Perform a damage calculation on the current analysis item
            [damage, ~] = uniaxialAnalysis.damageCalculation(cycles_stress, cycles_strain, msCorrection, pairs_stress,...
                cael, E, Sf, b, Ef, c, gamma, ndEndurance, fatigueLimitSress);
        end
        
        %% DAMAGE CALCULATION
        function [damage, cumulativeDamage] = damageCalculation(cycles_stress, cycles_strain, msCorrection, pairs_stress, cael, E, Sf, b, Ef, c, gamma, ndEndurance, fatigueLimit)
            
            %% CALCULATE DAMAGE FOR EACH STRESS CYCLE
            
            % Get number of repeats of loading
            numberOfCycles = length(cycles_strain);
            cumulativeDamage = zeros(1.0, numberOfCycles);
            
            % Get the fatigue limit
            fatigueLimit_original = fatigueLimit;
            overflowCycles = zeros(1.0, numberOfCycles);
            
            % Discrete life domain if using LCF portion of SN curve
            Nf = linspace(1.0, cael, 1e6);
            
            % Perform mean stress correction if necessary
            if msCorrection > 1.0
                [cycles_strain, gamma, R, mscWarning, overflowCycles, morrowSf] = uniaxialAnalysis.msc(cycles_strain, pairs_stress, msCorrection, gamma, Sf);
            else
                mscWarning = 0.0;
            end
                
            for index = 1:numberOfCycles
                % If the mean stress was too large, report infinite damage
                if mscWarning == 1.0 && any(overflowCycles == index) == 1.0
                    cumulativeDamage(index) = inf;
                    continue
                end
                
                % Modify the endurance limit if applicable
                [fatigueLimit, zeroDamage] = analysis.modifyEnduranceLimit(1.0, ndEndurance, fatigueLimit, fatigueLimit_original, cycles_stress(index), 50.0, 0.0, 0.25);
                if zeroDamage == 1.0
                    cumulativeDamage(index) = 0.0;
                    continue
                end
                
                %{
                    If the current cycle is negative, continue to the next
                    value in order to avoid complex damage values
                %}
                if cycles_strain(index) < 0.0
                    cumulativeDamage(index) = 0.0;
                else
                    % Define the E-N curve
                    switch msCorrection
                        case 1.0 % No mean stress correction
                            BM = (Sf/E).*(Nf).^b + Ef.*(Nf).^c;
                        case 2.0 % Morrow
                            BM = (morrowSf(index)/E).*((Nf).^b) + Ef.*((Nf).^c);
                        case 3.0 % Smith-Watson-Topper
                            BM = (Sf/E).*(Nf.*((0.5.*(1.0 - R(index))).^((1.0 - 0.5)/b))).^b + Ef.*(Nf.*((0.5.*(1.0 - R(index))).^((1.0 - 0.5)/b))).^c;
                        otherwise %  Walker
                            BM = (Sf/E).*(Nf.*((0.5.*(1.0 - R(index))).^((1.0 - gamma)/b))).^b + Ef.*(Nf.*((0.5.*(1.0 - R(index))).^((1.0 - gamma)/b))).^c;
                    end
                    
                    life = 0.5*interp1(BM, Nf, cycles_strain(index), 'linear', 'extrap');
                    
                    if life < 0.0
                        life = 0.0;
                    end
                    
                    % Invert the life value to get the damage
                    cumulativeDamage(index) = 1.0/life;
                end
            end
            
            %% SUM CUMULATIVE DAMAGE TO GET TOTAL DAMAGE FOR CURRENT NODE
            damage = sum(cumulativeDamage);
        end
        
        %% Mean stress correction
        function [mscCycles, gamma, R, warning, overflowCycles, morrowSf] = msc(cycles_e, pairs_s, msCorrection, gamma, Sf)
            % Initialize output
            warning = 0.0;
            overflowCycles = 0.0;
            morrowSf = [];
            R = [];
            
            % Get the mean stress from each cycle
            Sm = 0.5*(pairs_s(:, 1.0) + pairs_s(:, 2.0));
            
            % Get the corrected stress amplitudes
            switch msCorrection
                case 2.0 % Morrow
                    % Correct Sf' using Sm
                    morrowSf = Sf - Sm;
                    
                    % Check for negative values
                    for i = 1:length(Sm)
                        if morrowSf(i) < 0.0
                            morrowSf(i) = 1e-06;
                        end
                    end

                    mscCycles = cycles_e;
                case 3.0 % Smith-Watson-Topper
                    %{
                        The SWT mean stress correction is applied to the
                        strain-life equation directly. This function only
                        returns the value of gamma only.
                        
                        The SWT correction is the Walker correction with
                        gamma = 0.5.
                    %}
                    
                    % Get the maximum cycle and load ratio
                    [numberOfPairs, ~] = size(pairs_s);
                    maxCycle = zeros(1.0, numberOfPairs);
                    minCycle = maxCycle;
                    for i = 1:numberOfPairs
                        maxCycle(i) = max(pairs_s(i, :));
                        minCycle(i) = min(pairs_s(i, :));
                    end
                    R = minCycle./maxCycle;
                    
                    mscCycles = cycles_e;
                otherwise % Walker
                    %{
                        The Walker mean stress correction is
                        applied to the strain-life equation directly. This
                        function only returns the value of gamma only.
                    %}
                    
                    % Get the maximum cycle and load ratio
                    [numberOfPairs, ~] = size(pairs_s);
                    maxCycle = zeros(1.0, numberOfPairs);
                    minCycle = maxCycle;
                    for i = 1:numberOfPairs
                        maxCycle(i) = max(pairs_s(i, :));
                        minCycle(i) = min(pairs_s(i, :));
                    end
                    R = minCycle./maxCycle;
                    
                    if gamma == -9999.0
                        % Calculate gamma based on load ratio
                        gamma = zeros(1.0, numberOfPairs);
                        for i = 1:numberOfPairs
                            if R(i) < 0.0
                                gamma(i) = 1.0;
                            else
                                gamma(i) = 0.5;
                            end
                        end
                    end
                    
                    mscCycles = cycles_e;
            end
        end
    end
end