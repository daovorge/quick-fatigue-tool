classdef algorithm_uel < handle
%ALGORITHM_UEL    QFT class for Uniaxial Strain-Life algorithm.
%   This class contains methods for the Uniaxial Strain-Life fatigue
%   analysis algorithm.
%   
%   ALGORITHM_UEL is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%   
%   See also algorithm_bs7608, algorithm_findley, algorithm_nasa,
%   algorithm_ns, algorithm_sbbm, algorithm_sip, algorithm_usl,
%   algorithm_user.
%   
%   Reference section in Quick Fatigue Tool User Guide
%      6.9 Uniaxial Strain-Life
%   
%   Quick Fatigue Tool 6.10-09 Copyright Louis Vallance 2017
%   Last modified 06-Jun-2017 11:07:58 GMT
    
    %%
    
    methods(Static = true)
        %% ENTRY FUNCTION
        function [nodalAmplitudes_stress, nodalAmplitudes_strain, nodalPairs_stress, nodalPairs_strain, nodalDamage,...
                nodalDamageParameter, damageParameter_stress, damageParameter_strain] = main(Sxx, ~, ~, ~, ~, ~,...
                signalLength, node, nodalDamage, msCorrection,...
                nodalDamageParameter, gateTensors, tensorGate, S1, S2, S3)
            
            %% The damage parameter is just the Sxx component
            damageParameter_stress = Sxx;
            
            % Remove NaN values from damage DAMAGEPARAMETER
            damageParameter_stress(isnan(damageParameter_stress)) = 0.0;
            
            %% Get material properties
            E = getappdata(0, 'E');
            kp = getappdata(0, 'kp');
            np = getappdata(0, 'np');
            
            % Get the residual stress
            residual = getappdata(0, 'residualStress');
            
            %% Get the principal strain history at this item
            analysis_e.getPrincipalStrain(S1, S2, S3, E, kp, np);
            
            %% Convert the uniaxial stress into uniaxial strain
            % Gate the tensors if applicable
            if gateTensors > 0.0
                damageParameter_stress = analysis.gateTensors(damageParameter_stress, gateTensors, tensorGate);
            end
            
            [rfData, damageParameter_strain, damageParameter_stress, ~] = css2c(damageParameter_stress, E, kp, np);
            
            %% Rainflow count the stress
            if signalLength < 3.0
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
            nodalAmplitudes_stress{node} = cycles_stress;
            nodalAmplitudes_strain{node} = cycles_strain;
            
            nodalPairs_stress{node} = pairs_stress;
            nodalPairs_strain{node} = pairs_strain;
            
            %% Get current damage parameter
            nodalDamageParameter(node) = max(cycles_strain);
            
            %% Perform a mean stress correction on the nodal damage parameter if necessary
            if msCorrection < 7.0
                x = nodalPairs_stress{node};
                largestPair = find(cycles_stress == max(cycles_stress));
                [nodalDamageParameter(node), ~, ~, ~, ~] = analysis_e.msc(max(cycles_strain), x(largestPair(1.0), :), msCorrection, S1, residual);
            end
            
            %% Perform a damage calculation on the current analysis item
            nodalDamage(node) = algorithm_uel.damageCalculation(cycles_stress, cycles_strain, msCorrection, pairs_stress, pairs_strain, S1, residual);
        end
        
        %% DAMAGE CALCULATION
        function damage = damageCalculation(cycles_stress, cycles_strain, msCorrection, pairs_stress, pairs_strain, S1, residual)
            
            %% CALCULATE DAMAGE FOR EACH STRESS CYCLE
            
            % Get number of repeats of loading
            repeats = getappdata(0, 'repeats');
            numberOfCycles = length(cycles_strain);
            cumulativeDamage = zeros(1.0, numberOfCycles);
            
            % Get the fatigue limit
            modifyEnduranceLimit = getappdata(0, 'modifyEnduranceLimit');
            ndEndurance = getappdata(0, 'ndEndurance');
            fatigueLimit = getappdata(0, 'fatigueLimit');
            fatigueLimit_original = fatigueLimit;
            enduranceScale = getappdata(0, 'enduranceScaleFactor');
            cyclesToRecover = abs(round(getappdata(0, 'cyclesToRecover')));
            overflowCycles = zeros(1.0, numberOfCycles);
            kt = getappdata(0, 'kt');
            cael = getappdata(0, 'cael');
            
            % Discrete life domain if using LCF portion of SN curve
            Nf = linspace(1.0, cael, 1e6);
            
            % Perform mean stress correction if necessary
             if msCorrection < 7.0
                [cycles_strain, gamma, R, mscWarning, overflowCycles] = analysis_e.msc(cycles_strain, pairs_stress, msCorrection, S1, residual);
            else
                mscWarning = 0.0;
            end
            
            % Calculate Kt factors for each value of Nf if applicable
            if kt ~= 1.0
                radius = getappdata(0, 'notchRootRadius');
                constant = getappdata(0, 'notchSensitivityConstant');

                ktn = analysis.getKtn(Nf, constant, radius);
            else
                ktn = ones(1.0, length(Nf));
            end
            
            % Get the material properties
            E = getappdata(0, 'E');
            Sf = getappdata(0, 'Sf');
            b = getappdata(0, 'b');
            b2 = getappdata(0, 'b2');
            b2Nf = getappdata(0, 'b2Nf');
            Ef = getappdata(0, 'Ef');
            c = getappdata(0, 'c');
            
            % Get the morrow Sf values if applicable
            morrowSf = getappdata(0, 'morrowSf');
                
            for index = 1:numberOfCycles
                % If the cycle is purely compressive, assume no damage
                if (min(pairs_strain(index, :)) < 0.0 && max(pairs_strain(index, :)) <= 0.0) && (getappdata(0, 'ndCompression') == 1.0)
                    cumulativeDamage(index) = 0.0;
                    continue
                end
                
                % If the mean stress was too large, report infinite damage
                if mscWarning == 1.0 && any(overflowCycles == index) == 1.0
                    cumulativeDamage(index) = inf;
                    continue
                end
                
                % Modify the endurance limit if applicable
                [fatigueLimit, zeroDamage] = analysis.modifyEnduranceLimit(modifyEnduranceLimit, ndEndurance, fatigueLimit, fatigueLimit_original, cycles_stress(index), cyclesToRecover, residual, enduranceScale);
                if (zeroDamage == 1.0) && (kt == 1.0)
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
                        case 1.0 % Morrow
                            BM = (morrowSf(index)/E).*((Nf).^b) + Ef.*((Nf).^c);
                        case 4.0 % Walker
                            BM = (Sf/E).*(Nf.*((0.5.*(1.0 - R(index))).^((1.0 - gamma)/b))).^b + Ef.*(Nf.*((0.5.*(1.0 - R(index))).^((1.0 - gamma)/b))).^c;
                        case 5.0 % Smith-Watson-Topper
                            BM = (Sf/E).*(Nf.*((0.5.*(1.0 - R(index))).^((1.0 - gamma)/b))).^b + Ef.*(Nf.*((0.5.*(1.0 - R(index))).^((1.0 - gamma)/b))).^c;
                        otherwise % No mean stress correction
                            BM = (Sf/E).*(Nf).^b + Ef.*(Nf).^c;
                    end
                    
                    life = 0.5*interp1((1.0./ktn).*BM, Nf, cycles_strain(index), 'linear', 'extrap');
                    
                    %{
                        If the life was above the knee-point, re-calculate
                        the life using B2
                    %}
                    if life > b2Nf
                        switch msCorrection
                            case 1.0 % Morrow
                                BM = (morrowSf(index)/E).*((Nf).^b2) + Ef.*((Nf).^c);
                            case 4.0 % Walker
                                BM = (Sf/E).*(Nf.*((0.5.*(1.0 - R(index))).^((1.0 - gamma)/b2))).^b2 + Ef.*(Nf.*((0.5.*(1.0 - R(index))).^((1.0 - gamma)/b2))).^c;
                            case 5.0 % Smith-Watson-Topper
                                BM = (Sf/E).*(Nf.*((0.5.*(1.0 - R(index))).^((1.0 - gamma)/b))).^b + Ef.*(Nf.*((0.5.*(1.0 - R(index))).^((1.0 - gamma)/b))).^c;
                            otherwise % No mean stress correction
                                BM = (Sf/E).*(Nf).^b2 + Ef.*(Nf).^c;
                        end
                        
                        life = 0.5*interp1((1.0./ktn).*BM, Nf, cycles(index), 'linear', 'extrap');
                    end
                    
                    if life < 0.0
                        life = 0.0;
                    end
                    
                    % Invert the life value to get the damage
                    cumulativeDamage(index) = 1.0/life;
                end
            end
            
            %% SAVE THE CUMULATIVE DAMAGE
            setappdata(0, 'cumulativeDamage', cumulativeDamage);
            
            %% SUM CUMULATIVE DAMAGE TO GET TOTAL DAMAGE FOR CURRENT NODE
            damage = sum(cumulativeDamage)*repeats;
        end
        
        %% POST ANALYSIS AT WORST ITEM
        function [] = worstItemAnalysis(signalLength, nodalAmplitudes_stress, nodalAmplitudes_strain, nodalPairs, nodalPairs_strain)
            nodalPairs = nodalPairs{:};
            nodalPairs_strain = nodalPairs_strain{:};
            
            nodalAmplitudes_stress = nodalAmplitudes_stress{:};
            nodalAmplitudes_strain = nodalAmplitudes_strain{:};
            
            % Save data for history output
            setappdata(0, 'CS', zeros(1.0, signalLength))
            setappdata(0, 'CN', zeros(1.0, signalLength))
            
            setappdata(0, 'cyclesOnCP', nodalPairs)
            setappdata(0, 'cyclesOnCP_strain', nodalPairs_strain)
            
            setappdata(0, 'amplitudesOnCP', nodalAmplitudes_stress)
            setappdata(0, 'amplitudesOnCP_strain', nodalAmplitudes_strain)
            
            %{
                Get the damage per cycle for the worst node for the damage
                accumulation plot
            %}
            setappdata(0, 'worstNodeCumulativeDamage', getappdata(0, 'cumulativeDamage'))
        end
    end
end