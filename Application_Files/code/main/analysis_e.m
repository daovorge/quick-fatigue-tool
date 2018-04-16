classdef analysis_e < handle
%ANALYSIS    QFT class for general analysis tasks (strain-based).
%   ANALYSIS is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%   
%   Quick Fatigue Tool 6.12-00 Copyright Louis Vallance 2018
%   Last modified 31-Jan-2018 10:48:44 GMT
    
    %%
    
    methods(Static = true)
        %% Mean stress correction
        function [mscCycles, gamma, R, warning, overflowCycles] = msc(cycles_e, pairs_s, msCorrection, residual)
            % Initialize output
            warning = 0.0;
            overflowCycles = 0.0;
            mscCycles = [];
            gamma = [];
            R = [];
            
            % Check if the UTS is available
            uts = getappdata(0, 'uts');
            if isempty(uts) && (msCorrection == 5.0 || msCorrection == 7.0)
                mscCycles = cycles_e;
                return
            end
            
            % Get the mean stress from each cycle
            Sm = 0.5*(pairs_s(:, 1.0) + pairs_s(:, 2.0));
            
            % Add the residual stress to the mean stress
            Sm = Sm + residual;
            
            % Get the corrected stress amplitudes
            switch msCorrection
                case 1.0 % Morrow
                    % Get the unmodified fatigue strength coefficient
                    Sf = getappdata(0, 'Sf');
                    
                    % Correct Sf' using Sm
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
                    mscCycles = cycles_e;
                case 4.0 % Walker
                    %{
                        The Walker mean stress correction is applied to the
                        strain-life equation directly. This function
                        returns the value of gamma only.
                    %}
                    
                    gamma = getappdata(0, 'walkerGamma');
                    
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
                case 5.0 % Smith-Watson-Topper
                    %{
                        The SWT mean stress correction is applied to the
                        strain-life equation directly. This function
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
                otherwise
            end
            
            % Adjust bad R-values
            R(R > 1.0) = -1e9;
        end
        
        %% Get the principal strain history for the loading (if applicable)
        function [] = getPrincipalStrain(S1, S2, S3, E, kp, np)
            % Calculate the principal strains
            [~, E1, ~, ~] = css2b(S1, E, kp, np);
            [~, E2, ~, ~] = css2b(S2, E, kp, np);
            [~, E3, ~, ~] = css2b(S3, E, kp, np);
            
            % Save the principal strains
            setappdata(0, 'E1', E1)
            setappdata(0, 'E2', E2)
            setappdata(0, 'E3', E3)
        end
    end
end