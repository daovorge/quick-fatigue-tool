classdef analysis_e < handle
%ANALYSIS    QFT class for general analysis tasks (strain-based).
%   ANALYSIS is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%   
%   Quick Fatigue Tool 6.10-09 Copyright Louis Vallance 2017
%   Last modified 25-Apr-2017 12:13:25 GMT
    
    %%
    
    methods(Static = true)
        %% Mean stress correction
        function [mscCycles, warning, overflowCycles] = msc(cycles, pairs, msCorrection)
            % Initialize output
            warning = 0.0;
            overflowCycles = 0.0;
            mscCycles = [];
            
            % Check if the UTS is available
            uts = getappdata(0, 'uts');
            if isempty(uts) && (msCorrection == 5.0 || msCorrection == 7.0)
                mscCycles = cycles;
                return
            end
            
            % Check if the UCS is available
            ucs = getappdata(0, 'ucs');
            if isempty(ucs)
                ucs = uts;
            end
            
            % Get the mean stress from each cycle
            Sm = 0.5*(pairs(:, 1.0) + pairs(:, 2.0));
            
            % Get the corrected stress amplitudes
            switch msCorrection
                case 1.0 % Morrow
                    Sf = getappdata(0, 'Sf');
                    
                    morrowSf = Sf - Sm;
                    
                    % Check for negative values
                    for i = 1:length(Sm)
                        if morrowSf(i) < 0.0
                            morrowSf(i) = 1e-06;
                            
                            % Warn the user
                            messenger.writeMessage(257.0)
                        end
                    end
                    setappdata(0, 'morrowSf', morrowSf)
                    mscCycles = cycles;
                case 4.0 % Walker
                    gamma = getappdata(0, 'walkerGamma');
                    
                    % Get the maximum cycle and load ratio
                    [numberOfPairs, ~] = size(pairs);
                    maxCycle = zeros(1.0, numberOfPairs);
                    minCycle = maxCycle;
                    for i = 1:numberOfPairs
                        maxCycle(i) = max(pairs(i, :));
                        minCycle(i) = min(pairs(i, :));
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
                    
                    mscCycles = maxCycle.*((1.0-R)./2.0).^gamma;
                    for i = 1:numberOfPairs
                        if isreal(mscCycles(i)) == 0.0 || isinf(mscCycles(i)) || isnan(mscCycles(i))
                            mscCycles(i) = cycles(i);
                        end
                    end
                case 5.0 % Smith-Watson-Topper
                        % SWT correction is applied indirectly
                        [numberOfPairs, ~] = size(pairs);
                        maxCycle = zeros(1.0, numberOfPairs);
                        minCycle = maxCycle;
                        for i = 1:numberOfPairs
                            maxCycle(i) = max(pairs(i, :));
                            minCycle(i) = min(pairs(i, :));
                        end
                        R = minCycle./maxCycle;
                        mscCycles = maxCycle.*((1.0-R)./2.0).^0.5;
                        for i = 1:numberOfPairs
                            if isreal(mscCycles(i)) == 0.0 || isinf(mscCycles(i)) || isnan(mscCycles(i))
                                mscCycles(i) = cycles(i);
                            end
                        end
                case -1.0 % User-defined
                    % Get the user-defined mean stress correction data
                    mscData = getappdata(0, 'userMSCData');
                    mscData_m = mscData(:, 1.0);
                    mscData_a = mscData(:, 2.0);
                    
                    % Initialise the MSC cycles buffer
                    mscCycles = zeros(1.0, length(Sm));
                    
                    % Normalize the mean stress of the cycle with the UTS
                    % or the UCS
                    Sm(Sm > 0.0) = Sm(Sm > 0.0)/uts;
                    Sm(Sm < 0.0) = Sm(Sm < 0.0)/ucs;
                    
                    % For each cycle, find the MSC factor
                    for i = 1:length(Sm)
                        % If the mean stress of the cycle is outside the
                        % range of the data, take the edge amplitude value
                        if Sm(i) < mscData_m(end)
                            Sa_prime = mscData_a(end);
                            
                            % Avoid division by zero
                            if Sa_prime == 0.0
                                Sa_prime = 1e-6;
                            end
                            
                            % Calculate the MSC scaling factor
                            MSC = 1.0/Sa_prime;
                            
                            % Scale the current cycle to its equivalent
                            % value
                            mscCycles(i) = cycles(i)*MSC;
                            
                            messenger.writeMessage(58.0)
                        elseif Sm(i) > mscData_m(1.0)
                            Sa_prime = mscData_a(1.0);
                            
                            % Avoid division by zero
                            if Sa_prime == 0.0
                                Sa_prime = 1e-6;
                            end
                            
                            % Calculate the MSC scaling factor
                            MSC = 1.0/Sa_prime;
                            
                            % Scale the current cycle to its equivalent
                            % value
                            mscCycles(i) = cycles(i)*MSC;
                            
                            messenger.writeMessage(58.0)
                        elseif isempty(find(mscData_m == Sm(i), 1.0)) == 0.0
                            % The mean stress of the current cycle is an 
                            % exact match so there is no need to interpolate
                            
                            Sa_prime = mscData_a(find(mscData_m == Sm(i), 1.0));
                            
                            % Avoid division by zero
                            if Sa_prime == 0.0
                                Sa_prime = 1e-6;
                            end
                            
                            % Calculate the MSC scaling factor
                            MSC = 1.0/Sa_prime;
                            
                            % Scale the current cycle to its equivalent
                            % value
                            mscCycles(i) = cycles(i)*MSC;
                        else
                            % Find which two mean stress points the cycle lies
                            % between
                            for j = 1:length(mscData_m) - 1.0
                                if (Sm(i) < mscData_m(j)) && (Sm(i) > mscData_m(j + 1.0))
                                    Sm_lo = mscData_m(j);
                                    Sm_lo_j = j;
                                    
                                    Sm_hi = mscData_m(j + 1.0);
                                    Sm_hi_j = j + 1.0;
                                    break
                                end
                            end
                            
                            % Get the corresponding values of the stress
                            % amplitude data points
                            Sa_lo = mscData_a(Sm_lo_j);
                            Sa_hi = mscData_a(Sm_hi_j);
                            
                            % Make the equation of the straight line
                            % joining the two Sm-Sa data points
                            m = (Sa_hi - Sa_lo)/(Sm_hi - Sm_lo);
                            
                            Sa_prime = m.*(Sm(i) - Sm_hi) + Sa_hi;
                            
                            % Avoid division by zero
                            if Sa_prime == 0.0
                                Sa_prime = 1e-6;
                            end
                            
                            % Calculate the MSC scaling factor
                            MSC = 1.0/Sa_prime;
                            
                            % Scale the current cycle to its equivalent
                            % value
                            mscCycles(i) = cycles(i)*MSC;
                        end
                    end
                otherwise
            end
        end
        
        %% Get the principal strain history for the loading (if applicable)
        function [] = getPrincipalStrain(S1, S2, S3, E, kp, np)
            % Calculate the principal strains
            [~, E1, ~, ~] = css2(S1, E, kp, np);
            [~, E2, ~, ~] = css2(S2, E, kp, np);
            [~, E3, ~, ~] = css2(S3, E, kp, np);
            
            % Save the principal strains
            setappdata(0, 'E1', E1)
            setappdata(0, 'E2', E2)
            setappdata(0, 'E3', E3)
        end
    end
end