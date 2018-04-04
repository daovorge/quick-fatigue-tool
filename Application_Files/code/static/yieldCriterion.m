function [] = yieldCriterion(N, algorithm, fid_status, jobName, mainID, subID, dataCheck)
%YIELDCRITERION    QFT function to calculate yield criteria.
%   YIELDCRITERION is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%
%   See also composite, LaRC05.
%
%   Reference section in Quick Fatigue Tool User Guide
%      12.2 Yield criteria
%
%   Quick Fatigue Tool 6.11-13 Copyright Louis Vallance 2018
%   Last modified 04-Apr-2018 15:53:10 GMT
    
    %%

% Only find yielded items if requested
yieldCriteria = getappdata(0, 'yieldCriteria');

% Get the history gating value
historyGate = getappdata(0, 'historyGate');

% Check that the yield criterion definition is correct
if (yieldCriteria < 1.0) || (yieldCriteria > 4.0) || (algorithm == 8.0)
    setappdata(0, 'YIELD', linspace(-1.0, -1.0, N))
    setappdata(0, 'warning_063', 0.0)
    return
end

fprintf('\n[PRE] Evaluating yield criterion')
fprintf(fid_status, '\n[PRE] Evaluating yield criterion');

% Get the number of groups for the analysis
G = getappdata(0, 'numberOfGroups');

% Get the group ID buffer
groupIDBuffer = getappdata(0, 'groupIDBuffer');

% Initialize yield variables
totalStrainEnergy_buffer = zeros(1.0, N);
yield = zeros(1.0, N);

% Flag to set the material model
materialResponse = getappdata(0, 'materialResponse');

startID = 1.0;
totalCounter = 1.0;

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
    
    %{
                    If the total strain energy theory is selected, make sure
                    the poisson ratio is defined
    %}
    v = getappdata(0, 'poisson');
    
    % Store the current group number
    setappdata(0, 'message_groupNumber', groups)
    
    % Check that the proof stress is defined
    if algorithm == 8.0
        proof = getappdata(0, 'bs7608Twops');
    else
        proof = getappdata(0, 'twops');
    end
    
    E = getappdata(0, 'E');
    kp = getappdata(0, 'kp');
    np = getappdata(0, 'np');
    
    % Check material properties
    if isempty(proof) == 1.0
        setappdata(0, 'YIELD', linspace(-2.0, -2.0, N))
        messenger.writeMessage(118.0)
        totalCounter = totalCounter + 1.0;
        continue
    elseif ((isempty(E) == 1.0) || (isempty(kp) == 1.0) || (isempty(np) == 1.0)) && (materialResponse == 2.0)
        % Nonlinear elastic model was requested, but material properties are insufficient
        materialResponse = 1.0;
        messenger.writeMessage(119.0)
    elseif (isempty(v) == 1.0) && (yieldCriteria == 1.0)
        setappdata(0, 'YIELD', linspace(-2.0, -2.0, N))
        messenger.writeMessage(162.0)
        totalCounter = totalCounter + 1.0;
        continue
    end
    
    % Set the strain limit energy for the current group
    strainLimitEnergy = proof^2.0;
    
    s1 = getappdata(0, 'S1');
    s2 = getappdata(0, 'S2');
    s3 = getappdata(0, 'S3');
    
    s1 = s1(startID:(startID + N) - 1.0, :);
    s2 = s2(startID:(startID + N) - 1.0, :);
    s3 = s3(startID:(startID + N) - 1.0, :);
    
    % Remove compressive stresses if ndCompression=1
    if getappdata(0, 'ndCompression') == 1.0
        s1(s1 < 0.0) = 0.0;
        s2(s2 < 0.0) = 0.0;
        s3(s3 < 0.0) = 0.0;
    end
    
    % Correct the principal stresses for the effect of nonlinearity
    for i = 1:N
        s1_i = s1(i, :);
        s2_i = s2(i, :);
        s3_i = s3(i, :);
        
        if materialResponse == 2.0
            try
                % Gate the history
                gate = preProcess.autoGate(s1_i, historyGate);
                [peaks, valleys] = preProcess.peakdet(s1_i, gate);
                
                if isempty(peaks) == 0.0 && isempty(valleys) == 0.0
                    % Order the P-V time values from low to high
                    times = sort([peaks(:, 1.0)', valleys(:, 1.0)']);
                    
                    % Reconstruct the history signal
                    newLength = length(times);
                    s1_i = zeros(1.0, newLength);
                    
                    peak_j = 1.0; valley_j = 1.0;
                    
                    for j = 1.0:newLength
                        if any(peaks(:, 1.0) == times(j))
                            s1_i(j) = peaks(peak_j, 2.0);
                            peak_j = peak_j + 1.0;
                        else
                            s1_i(j) = valleys(valley_j, 2.0);
                            valley_j = valley_j + 1.0;
                        end
                    end
                end
                
                [~, ~, s1_i, error] = css2b(s1_i, E, kp, np);
                
                % Gate the history
                gate = preProcess.autoGate(s2_i, historyGate);
                [peaks, valleys] = preProcess.peakdet(s2_i, gate);
                
                if isempty(peaks) == 0.0 && isempty(valleys) == 0.0
                    % Order the P-V time values from low to high
                    times = sort([peaks(:, 1.0)', valleys(:, 1.0)']);
                    
                    % Reconstruct the history signal
                    newLength = length(times);
                    s2_i = zeros(1.0, newLength);
                    
                    peak_j = 1.0; valley_j = 1.0;
                    
                    for j = 1.0:newLength
                        if any(peaks(:, 1.0) == times(j))
                            s2_i(j) = peaks(peak_j, 2.0);
                            peak_j = peak_j + 1.0;
                        else
                            s2_i(j) = valleys(valley_j, 2.0);
                            valley_j = valley_j + 1.0;
                        end
                    end
                    
                    [~, ~, s2_i, error] = css2b(s2_i, E, kp, np);
                end
                
                % Gate the history
                gate = preProcess.autoGate(s3_i, historyGate);
                [peaks, valleys] = preProcess.peakdet(s3_i, gate);
                
                if isempty(peaks) == 0.0 && isempty(valleys) == 0.0
                    % Order the P-V time values from low to high
                    times = sort([peaks(:, 1.0)', valleys(:, 1.0)']);
                    
                    % Reconstruct the history signal
                    newLength = length(times);
                    s3_i = zeros(1.0, newLength);
                    
                    peak_j = 1.0; valley_j = 1.0;
                    
                    for j = 1.0:newLength
                        if any(peaks(:, 1.0) == times(j))
                            s3_i(j) = peaks(peak_j, 2.0);
                            peak_j = peak_j + 1.0;
                        else
                            s3_i(j) = valleys(valley_j, 2.0);
                            valley_j = valley_j + 1.0;
                        end
                    end
                    
                    [~, ~, s3_i, error] = css2b(s3_i, E, kp, np);
                end
            catch
                error = 2.0;
            end
            
            %{
                            If there was an error during the conversion,
                            warn the user
            %}
            if error == 1.0
                yield(totalCounter:(totalCounter + N) - 1.0) = -2.0;
                setappdata(0, 'yieldCriteria', 0.0)
                setappdata(0, 'message_214_E', E)
                setappdata(0, 'message_214_K', kp)
                setappdata(0, 'message_214_N', np)
                setappdata(0, 'message_214_groupMaterial', groupIDBuffer(groups).material)
                setappdata(0, 'message_214_groupName', groupIDBuffer(groups).name)
                setappdata(0, 'message_214_groupNumber', groups)
                messenger.writeMessage(214.0)
                
                totalCounter = totalCounter + N;
                break
            elseif error == 2.0
                yield(totalCounter:(totalCounter + N) - 1.0) = -2.0;
                setappdata(0, 'yieldCriteria', 0.0)
                setappdata(0, 'message_242_groupMaterial', groupIDBuffer(groups).material)
                setappdata(0, 'message_242_groupName', groupIDBuffer(groups).name)
                setappdata(0, 'message_242_groupNumber', groups)
                messenger.writeMessage(242.0)
                
                totalCounter = totalCounter + N;
                break
            end
            
            %{
                            Make sure principal stress histories are the
                            same length after correcting for plasticity
            %}
            lengths = [length(s1_i), length(s2_i), length(s3_i)];
            signalLength = max(lengths);
            
            if lengths(1.0) < signalLength
                s1_i = [s1_i, zeros(1.0, signalLength - lengths(1.0))]; %#ok<AGROW>
            end
            if lengths(2.0) < signalLength
                s2_i = [s2_i, zeros(1.0, signalLength - lengths(2.0))]; %#ok<AGROW>
            end
            if lengths(3.0) < signalLength
                s3_i = [s3_i, zeros(1.0, signalLength - lengths(3.0))]; %#ok<AGROW>
            end
        end
        
        % Get the maximum strain energy in the loading for each analysis item
        %{
                        Evaluate the principal stresses based on the
                        selected yield criterion
        %}
        switch yieldCriteria
            case 1.0 % Total strain energy theory
                totalStrainEnergy = max(s1_i.^2.0 + s2_i.^2.0 + s3_i.^2.0 - (2.0*v).*((s1_i.*s2_i) + (s2_i.*s3_i) + (s1_i.*s3_i)));
                if totalStrainEnergy >= strainLimitEnergy
                    yield(totalCounter) = 1.0;
                end
                
                totalStrainEnergy_buffer(totalCounter) = max(totalStrainEnergy);
                
                totalCounter = totalCounter + 1.0;
            case 2.0 % Shear strain energy theory
                totalStrainEnergy = max(0.5.*((s1_i - s2_i).^2.0 + (s2_i - s3_i).^2.0 + (s3_i - s1_i).^2.0));
                if totalStrainEnergy >= strainLimitEnergy
                    yield(totalCounter) = 1.0;
                end
                
                totalStrainEnergy_buffer(totalCounter) = max(totalStrainEnergy);
                
                totalCounter = totalCounter + 1.0;
            case 3.0 % Tresca failure theory
                tMax = max(abs(s1_i - s3_i));
                if tMax >= proof
                    yield(totalCounter) = 1.0;
                end
                
                totalStrainEnergy_buffer(totalCounter) = tMax^2.0;
                
                totalCounter = totalCounter + 1.0;
            case 4.0 % von Mises yield criterion
                sPrime = max((s1_i.^2.0 + s2_i.^2.0 + s3_i.^2.0 - s1_i.*s2_i - s2_i.*s3_i - s3_i.*s1_i).^0.5);
                if sPrime >= proof
                    yield(totalCounter) = 1.0;
                end
                
                totalStrainEnergy_buffer(totalCounter) = sPrime^2.0;
                
                totalCounter = totalCounter + 1.0;
        end
    end
    
    % Save the strain limit energy
    group_materialProps = getappdata(0, 'group_materialProps');
    group_materialProps(groups).strainLimitEnergy = strainLimitEnergy;
    setappdata(0, 'group_materialProps', group_materialProps)
    setappdata(0, 'strainLimitEnergy', strainLimitEnergy)
    
    % Normalise the total strain energy by the strain limit energy
    totalStrainEnergy_buffer = totalStrainEnergy_buffer/strainLimitEnergy;
    
    % Save thte total strain energy
    setappdata(0, 'totalStrainEnergy', totalStrainEnergy_buffer)
    setappdata(0, 'totalStrainEnergy_group', totalStrainEnergy_buffer(startID:totalCounter - 1.0))
    
    yield_group = yield(startID:(startID + N) - 1.0);
    setappdata(0, 'warning_066_N', length(yield_group(yield_group == 1.0)))
    
    messenger.writeMessage(66.0)
    
    % Save the current material state
    group.saveMaterial(groups)
    
    % Update the start ID
    startID = startID + N;
end

% Save the field variables
setappdata(0, 'YIELD', yield)

%% Write items to file

% Get the strain energy associated with the yielding items
totalStrainEnergy = getappdata(0, 'totalStrainEnergy');

% Get the normalised strain limit energy of the current group
strainLimitEnergy = 1.0;

% Get the plastic strain energy for the current group
plasticStrainEnergy = totalStrainEnergy - strainLimitEnergy;
plasticStrainEnergy(plasticStrainEnergy < 0.0) = 0.0;

failureIndex = totalStrainEnergy.^0.5;

% Get the maximum stress at each item
S1 = getappdata(0, 'S1');
S3 = getappdata(0, 'S3');
smax = max([max(S1, [], 2.0), min(S3, [], 2.0)], [], 2.0);
smin = min([max(S1, [], 2.0), min(S3, [], 2.0)], [], 2.0);
smax(abs(smin) > smax) = smin(abs(smin) > smax);

% Concatenate data
data = [mainID'; subID'; smax'; yield; failureIndex; plasticStrainEnergy]';

% Print information to file
root = getappdata(0, 'outputDirectory');

if exist(sprintf('%s/Data Files', root), 'dir') == 0.0
    mkdir(sprintf('%s/Data Files', root))
end

dir = [root, 'Data Files/yield_assessment.dat'];

fid = fopen(dir, 'w+');
fprintf(fid, 'YIELD ASSESSMENT RESULTS\r\n');
fprintf(fid, 'Job:\t%s\r\nLoading:\t%.3g\t%s\r\n', jobName, getappdata(0, 'loadEqVal'), getappdata(0, 'loadEqUnits'));

switch yieldCriteria
    case 4.0
        yieldIndex = 'VMCRT';
    case 3.0
        yieldIndex = 'TRCRT';
    case 2.0
        yieldIndex = 'SSCRT';
    case 1.0
        yieldIndex = 'TSCRT';
end
fprintf(fid, 'Main ID\tSub ID\tSMAX (MPa)\tYIELD\t%s\tPEEQ\r\n', yieldIndex);
fprintf(fid, '%.0f\t%.0f\t%f\t%.0f\t%.9f\t%f\r\n', data');

fclose(fid);

messenger.writeMessage(120.0)

%% Write results to ODB if applicable
if (getappdata(0, 'autoExport_ODB') == 1.0) && (dataCheck == 1.0)
    if getappdata(0, 'autoExport_uniaxial') == 1.0
        messenger.writeMessage(203.0)
    else
        staticOutput.exportODB(fid_status, mainID, 1.0)
    end
end
end