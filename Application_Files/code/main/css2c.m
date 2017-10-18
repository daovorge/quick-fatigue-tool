function [rfData, epsilon, sigma, error, warning, matMemFirstExcursion] = css2c(sigma_e, E, kp, np, scf)
%CSS2C    QFT function to calculate nonlinear elastic stress-strain.
%   This function calculates the nonlinear elastic stress and strain from
%   an elastic stress tensor.
%   
%   CSS2C is used internally by Quick Fatigue Tool. The user
%   is not required to run this file.
%
%	CSS2C is a variation of CSS2. The original function calculates the
%	hysteresis loop by interpolation even if the current stress range is
%   identical to the previous stress range. In this function, if the
%   current and previous stress ranges are identical, the current
%   hysteresis point is assumed to be equal to the previous point. The rest
%   of CSS2C is the same as CSS2.
%
%   CSS2C is the same as CSS2B, except that the rainlow cycle counting is
%   performed by RAINFLOW_2(FT) instead of from the hysteresis loops
%   directly inside CSS2C. This is found to be more reliable.
%   
%   Quick Fatigue Tool 6.11-06 Copyright Louis Vallance 2017
%   Last modified 30-Aug-2017 15:40:20 GMT
    
    %%
    
error = 0.0;
warning = 0.0;

%% Prepare the stress signal
% If the signal is all zero, return zeros of the same length
if any(sigma_e) == 0.0
    epsilon = zeros(1.0, length(sigma_e));
    sigma = zeros(1.0, length(sigma_e));
    return
end

%{
    Remove duplicate points in the signal which would cause the algorithm
    to crash
%}
index = 1.0;
while 1.0
    if index == length(sigma_e)
        break
    elseif sigma_e(index) == sigma_e(index + 1.0)
        sigma_e(index) = [];
    else
        index = index + 1.0;
    end
end

% Append the signal with zero if necessary
removeZero = 0.0;
if sigma_e(1.0) ~= 0.0
    sigma_e = [0.0, sigma_e];
    removeZero = 1.0;
end

% Apply peak-valley detection to to the signal
if length(sigma_e) > 2.0
    finished = 0.0;
    index = 2.0;
    while finished == 0.0
        if length(sigma_e) < 3.0 || index == length(sigma_e)
            finished = 1.0;
        elseif sigma_e(index) > sigma_e(index - 1.0) && sigma_e(index) < sigma_e(index + 1.0) ||...
                sigma_e(index) < sigma_e(index - 1.0) && sigma_e(index) > sigma_e(index + 1.0)
            % Remove the point from the signal
            sigma_e(index) = [];
        else
            index = index + 1.0;
        end
    end
end

%% Initialize analysis variables
precision = 1e3;
overshoot = 1.5;
method = 'linear';

% Get the signal length
signalLength = length(sigma_e);

% Initialize the true strain values
epsilon = zeros(1.0, signalLength);
sigma = zeros(1.0, signalLength);

% Scale the elastic stress by the SCF
sigma_e = sigma_e.*scf;

%% Calcualte the monotonic stage
%{
    The first excursion is assumed to be monotonic, therefore
    it is calculated separately
%}
%{
    Get the range of strains along the R-O curve. Since the
    true strain at the current stress is not yet known, the
    upper bound of the curve is estimated as the elastic
    strain. This is a safe guess since the strain stress is
    larger than the true strain
%}
trueStrainCurve = linspace(1e-12, (overshoot*sigma_e(2.0))/E, precision);

%{
    The true stress curve is found by substituting the true
    strain curve into the monotonic R-O equation
%}
% Neuber substitution from sigma_e*eps_e == sigma_t*eps_t
Nb = (sigma_e(2.0)^2)./(E.*trueStrainCurve);

% Newton's method. Solution is where f=0
f = real((Nb./E) + (Nb./kp).^(1.0/np) - trueStrainCurve);

%{
    If the material properties are ill-defined, the variable F may contain
    spurious values which will cause the code to crash during
    interpolation. Check F for spurious values and abort the calculation if
    necessary
%}
if (any(isinf(f)) == 1.0) || (any(isnan(f)) == 1.0)
    error = 1.0;
    return
end

%{
    The true strain at the current stress is found by
    interpolating the R-O curve. Linear extrapolation should
    not be required since the strain datapoints should always
    contain the true strain value somewhere within it
%}
epsilon(2.0) = interp1(f, trueStrainCurve, 0.0, method, 'extrap');

% Get the true stress curve datapoints from the true strain
trueStressCurve = linspace(0.0, epsilon(2.0)*E, precision);

%{
    Get the true strain curve datapoints by substitution of trueStressCurve
    into the Ramber-Osgood equation
%}
trueStrainCurve = real((trueStressCurve./E) + (trueStressCurve./kp).^(1.0/np));

%{
    The true stress from the elastic stress is the point on the true stres
    curve at the calculated true strain
%}
sigma(2.0) = interp1(trueStrainCurve, trueStressCurve, epsilon(2.0), method, 'extrap');

%{
    If the value of EPSILON(2.0) is less than TRUESTRAINCURVE(2.0), this
    indicates that the magnitude of the monotonic stress exceeds the
    precision of the hardening equation. Warn the user that the results
    will not be accurate
%}
if abs(epsilon(2.0)) < abs(trueStrainCurve(2.0))
    setappdata(0, 'message_205_sigma', sigma_e(2.0))
    setappdata(0, 'message_205_epsilon', epsilon(2.0))
    setappdata(0, 'message_205_strain', trueStrainCurve(2.0))
    messenger.writeMessage(205.0)
    warning = 1.0;
end

%% Calculate the cyclic stage
%{
    The remainder of stress-strain data points are assumed to
    be cyclically stable i.e. the cyclic version of the R-O
    equation can be used to determine every other stress point
    in the strain history
%}

currentStressRange = abs(sigma_e(2.0));

stressRangeBuffer = currentStressRange;

allowClosure = 1.0;

matMemFirstExcursion = 1.0;
matMemFirstExcursionIndex = 2.0;
ratchetStress = 0.0;

for i = 3:signalLength
    %{
        Calculate the current strain range. If the signal did
        not reverse direction, the current strain range must
        take into account the entire excursion, not just the
        current strain increment
    %}
    previousStressRange = currentStressRange;
    currentStressRange = abs(sigma_e(i) - sigma_e(i - 1.0));
    stressRangeBuffer(i - 1.0) = currentStressRange;
    
    % Record the direciton of the current excursion
    if sigma_e(i) - sigma_e(i - 1.0) > 0.0
        % The current excursion is moving forward
        currentDirection = 1.0;
    else
        % The current excursion is moving backwards
        currentDirection = -1.0;
    end
    
    %{
        The current strain range is smaller than the first
        cyclic excursion since the previous cycle closure.
        Successive cycle closures cannot assume the path of the
        monotonic excursion
    %}
    if currentStressRange < stressRangeBuffer(matMemFirstExcursionIndex)
        matMemFirstExcursion = 0.0;
    end
    
    %{
        It is now possible for hysteresis loops to be closed.
        If the current strain range exceeds the previous strain
        range, a loop has bee closed
                    
        When a loop is closed, the material memory effect
        becomes observable, so the next stress data point must
        be calculated from the curve defining the stress value
        two indexes previously
                
        The cycle is only closed if the current (larger) strain
        range is in the opposite direction to the previous
        strain range
    %}
    if (currentStressRange > previousStressRange) && (i > 3.0) && (allowClosure == 1.0)
        %%
        %{
            A cycle has been closed
                    
            The current strain range exceeds the previous
            strain range, therefore material memory must be
            accounted for
                    
            The first cycle closure can only occur at the
            earliest on the third reversal. Therefore, do not
            allow cycle closures before i > 3.0
        %}
        
        %{
            Since the cycle closure includes the effect of
            material memory, the next reversal may not close a cycle
        %}
        allowClosure = 0.0;
        
        %{
            The stable loop strain range is taken to be the
            strain range of the previously closed cycle
        %}
        matMemFirstExcursionIndex = i;
        
        %{
            Calculate the portion of the strain range which
            accounts only for the distance beyond the cycle
            closure point
        %}
        stressRangeBeyondClosure = currentStressRange - previousStressRange;
        
        %{
            The stress is calculated from the curve two
            excursions ago. The current stress range is the
            strain range from this excursion, plus the
            additional strain range beyond the current cycle
            closure point
        %}
        if matMemFirstExcursion == 1.0
            stressRange = stressRangeBuffer(1.0) + stressRangeBeyondClosure + ratchetStress;
        else
            stressRange = stressRangeBuffer(i - 3.0) + stressRangeBeyondClosure;
        end
        
        if currentDirection == -1.0
            trueStrainCurve = linspace(1e-12, -overshoot*(stressRange/E), precision);
        else
            trueStrainCurve = linspace(1e-12, overshoot*(stressRange/E), precision);
        end
        
        % Calculate the stress-strain curve
        %{
            If the excursion used for the material memory is
            the first excursion in the loading, the monotonic
            stress-strain curve must be used instead
        %}
        if matMemFirstExcursion == 1.0
            ratchetStress = ratchetStress + stressRangeBeyondClosure;
            
            Nb = (stressRange^2.0)./(E.*trueStrainCurve);
            f = real((Nb./E) + (Nb./kp).^(1.0/np) - trueStrainCurve);
        else
            Nb = (stressRange^2)./(E.*trueStrainCurve);
            f = real((Nb./E) + 2.0.*(Nb./(2.0*kp)).^(1.0/np) - trueStrainCurve);
        end
        
        % Solve for the strain range
        strainRange = interp1(f, trueStrainCurve, 0.0, method, 'extrap');
        
        if matMemFirstExcursion == 1.0
            epsilon(i) = epsilon(1.0) + strainRange;
        else
            epsilon(i) = epsilon(i - 3.0) + strainRange;
        end
        
        % Solve for the stress range
        if matMemFirstExcursion == 1.0
            currentStrainRange = epsilon(i);
        else
            currentStrainRange = abs(epsilon(i) - epsilon(i - 1.0));
        end
        
        trueStressCurve = linspace(0.0, currentStrainRange*E, precision);
        
        if matMemFirstExcursion == 1.0
            trueStrainCurve = real((trueStressCurve./E) + (trueStressCurve./(kp)).^(1.0/np));
        else
            trueStrainCurve = real((trueStressCurve./E) + 2.0.*(trueStressCurve./(2.0*kp)).^(1.0/np));
        end
        
        if all(trueStrainCurve == 0.0) == 1.0
            sigma(i) = sigma(i - 1.0);
        else
            stressRange = interp1(trueStrainCurve, trueStressCurve, currentStrainRange, method, 'extrap');
            
            if matMemFirstExcursion == 1.0
                if currentDirection == -1.0
                    sigma(i) = sigma(1.0) - stressRange;
                else
                    sigma(i) = sigma(1.0) + stressRange;
                end
            else
                if currentDirection == -1.0
                    sigma(i) = sigma(i - 3.0) - stressRange;
                else
                    sigma(i) = sigma(i - 3.0) + stressRange;
                end
            end
        end
    elseif ((currentStressRange == 2.0*previousStressRange) && (i == 3.0)) || ((currentStressRange == previousStressRange) && (i > 3.0) && (allowClosure == 1.0))
        %%
        %{
            On the first cyclic excursion (i == 3.0), the stress range is
            exacty double that of the monotonic excursion, creating a
            symmetrical hysteresis loop. The current stress and strain is
            equal to minus the previous point
            
            OR
            
            The stress ranage of the  current cyclic excursion (i > 3.0) is
            equal to the stress range of the previous cyclic excursion. The
            current stress and strain is equal to the previous point
        %}
        if i == 3.0
            % i == 3.0
            epsilon(i) = -epsilon(i - 1.0);
            sigma(i) = -sigma(i - 1.0);
        else
            % i > 3.0
            epsilon(i) = epsilon(i - 2.0);
            sigma(i) = sigma(i - 2.0);
        end
    else
        %%
        %{
            No cycle has been closed

            The current stress curve starts at the previously
            calculated true stress value, and ends at a
            location defined by the elastic stress
            corresponding to the current strain point
        %}
        
        %{
            Since this reversal did not result in cycle
            closure, the next reversal may close a cycle
        %}
        allowClosure = 1.0;
        
        if currentDirection == -1.0
            trueStrainCurve = linspace(1e-12, -overshoot*(currentStressRange/E), precision);
        else
            trueStrainCurve = linspace(1e-12, overshoot*(currentStressRange/E), precision);
        end
        
        Nb = (currentStressRange.^2.0)./(E.*trueStrainCurve);
        f = real((Nb./E) + 2.0.*(Nb./(2.0*kp)).^(1.0/np) - trueStrainCurve);
        
        % Solve for the strain range
        strainRange = interp1(f, trueStrainCurve, 0.0, method, 'extrap');
        
        epsilon(i) = epsilon(i - 1.0) + strainRange;
        
        % Solve for the stress range
        currentStrainRange = abs(epsilon(i) - epsilon(i - 1.0));
        trueStressCurve = linspace(0.0, currentStrainRange*E, precision);
        
        trueStrainCurve = real((trueStressCurve./E) + 2.0.*(trueStressCurve./(2.0*kp)).^(1.0/np));
        
        if all(trueStrainCurve == 0.0) == 1.0
            sigma(i) = sigma(i - 1.0);
            continue
        end
        
        stressRange = interp1(trueStrainCurve, trueStressCurve, currentStrainRange, method, 'extrap');
        
        if currentDirection == -1.0
            sigma(i) = sigma(i - 1.0) - stressRange;
        else
            sigma(i) = sigma(i - 1.0) + stressRange;
        end
    end
end

%% Rainflow cycle count the inelastic histories

% Rainflow cycle count the inelastic stress/strain signals
rfData_e = analysis.rainFlow_2(epsilon);
rfData_s = analysis.rainFlow_2(sigma);

% Get the number of cycle
[nCycles_e, ~] = size(rfData_e);
[nCycles_s, ~] = size(rfData_s);

% Make sure matrices are same size
if nCycles_e > nCycles_s
    diff = nCycles_e - nCycles_s;
    rfData_s(end + 1.0: end + diff, 1:4) = zeros(diff, 4.0);
elseif nCycles_e < nCycles_s
    diff = nCycles_s - nCycles_e;
    rfData_e(end + 1.0: end + diff, 1:4) = zeros(diff, 4.0);
end

% Concatenate cycles into single buffer
%{
    1: Min. stress
    2: Max. stress
    3: Min. strain
    4: Max. strain
    5: Min. index
    6: Max. index
%}
rfData = [rfData_s(:, 1:2), rfData_e(:, 1:2), rfData_s(:, 3:4)];

% Remove the leading zero if applicable
if removeZero == 1.0
    sigma(1.0) = [];
    epsilon(1.0) = [];
end

%% Save the last state of the ALLOWCLOSURE flag
setappdata(0, 'css_allowClosure', allowClosure)
end