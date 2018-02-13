classdef highFrequency < handle
%HIGHFREQUENCY    QFT class for high frequency dataset processing.
%   This class contains methods for high frequency dataset processing
%   tasks.
%   
%   HIGHFREQUENCY is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%   
%   Quick Fatigue Tool 6.11-12 Copyright Louis Vallance 2018
%   Last modified 13-Feb-2018 11:42:05 GMT
    
    %%
    
    methods(Static = true)
        %% Add high frequency stress data to the loading
        function [Sxx, Syy, Szz, Txy, Tyz, Txz, error] = main(Sxx, Syy, Szz, Txy, Tyz, Txz, hfDataset, hfHistory, time, algorithm, items, hfScales)
            % Verify scale factors
            if isempty(hfScales) == 1.0
                hfScales = 1.0;
            end
            
            %{
                If load history gating is active, inform the user that this
                type of gating may affect the resulting high frequency
                dataset
            %}
            if getappdata(0, 'gateHistories') == 1.0
                messenger.writeMessage(182.0)
            end
            
            % Scale and combine the high frequency data
            if (algorithm == 3.0) || (algorithm == 10.0)
                [Sxx_hf, Syy_hf, Szz_hf, Txy_hf, Tyz_hf, Txz_hf, error] = highFrequency.uniaxialReadHF(hfHistory, hfScales);
            else
                [Sxx_hf, Syy_hf, Szz_hf, Txy_hf, Tyz_hf, Txz_hf, error] = highFrequency.scalecombineHF(hfDataset, hfHistory, items, hfScales);
            end
            
            if error == 1.0
                return
            end
            
            % Check that the number of items in the high frequency data
            % match the number of items in the low frequency data
            [numberOfItemsLow, ~] = size(Sxx);
            [numberOfItemsHigh, ~] = size(Sxx_hf);
            
            if numberOfItemsLow ~= numberOfItemsHigh
                error = 1.0;
                setappdata(0, 'E040', 1.0)
                return
            end
            
            if (algorithm == 3.0) || (algorithm == 10.0)
                [Sxx, Syy, Szz, Txy, Tyz, Txz, error] = highFrequency.superimposeUniaxial(Sxx, Sxx_hf, time{1}, time{2});
            else
                [Sxx, Syy, Szz, Txy, Tyz, Txz, error] = highFrequency.superimpose(Sxx_hf, Syy_hf, Szz_hf, Txy_hf, Tyz_hf, Txz_hf,...
                    Sxx, Syy, Szz, Txy, Tyz, Txz, time{1}, time{2});
            end
            
            if error == 1.0
                return
            end
        end
        
        %% Read a high frequency stress history for Uniaxial Stress-Life
        function [Sxx, Syy, Szz, Txy, Tyz, Txz, error] = uniaxialReadHF(scales, hfScales)
            error = 0.0;
            
            % Check that the stress history is defined
            if ischar(scales)
                if isempty(scales) == 1.0
                    error = 1.0;
                    setappdata(0, 'E047', 1.0)
                elseif exist(scales, 'file') == 0.0
                    error = 1.0;
                    setappdata(0, 'E036', 1.0)
                    setappdata(0, 'errorMissingScale', scales)
                end
            elseif isnumeric(scales) == 1.0
                if isempty(scales) == 1.0
                    error = 1.0;
                    setappdata(0, 'E047', 1.0)
                end
            elseif length(scales) > 1.0
                error = 1.0;
                setappdata(0, 'E037', 1.0)
                setappdata(0, 'errMultipleLoadHistories', scales)
            elseif isempty(scales) == 1.0 || length(scales) == 0.0
                error = 1.0;
                setappdata(0, 'E046', 1.0)
            end
            
            % Verify the loading scale factors
            nScaleFactors = length(hfScales);
            
            if nScaleFactors == 1.0
                % Dataset/history pairs equal to number of gate values
            elseif nScaleFactors > 1.0
                setappdata(0, 'message_282_hf', 1.0)
                messenger.writeMessage(282.0);
                
                % Only one scale factor is permitted
                hfScales = hfScales(1.0);
            elseif isempty(nScaleFactors) == 1.0
                setappdata(0, 'message_282_hf', 1.0)
                messenger.writeMessage(282.0);
                
                % No scale factors specified
                hfScales = 1.0;
            end
            
            % Load the history file
            if isnumeric(scales) == 0.0
                try
                    scale = dlmread(scales);
                catch unhandledException
                    error = true;
                    setappdata(0, 'E016', 1.0)
                    setappdata(0, 'error_log_016_exceptionMessage', unhandledException.message)
                    setappdata(0, 'loadHistoryUnableOpen', scales)
                    
                    if exist(scales, 'file') == 0.0
                        setappdata(0, 'scaleNotFound', 1.0)
                    end
                    
                    Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                    return
                end
            else
                % Load history is specified directly in the job file
                scale = scales;
            end
            
            % Remove INF/NaN values from load history data
            scale(scale == inf) = [];
            scale(scale == -inf) = [];
            scale(isnan(scale)) = [];
            
            % Check the length of the history data
            if length(scale) < 2.0
                if getappdata(0, 'compositeCriteria') == 1.0
                    %{
                    	For composite failure criteria analysis, a load
                        history 1 point is permitted. Prepend a zero to the
                        load history
                    %}
                    scale = [0.0, scale];
                else
                    error = true;
                    setappdata(0, 'E017', 1.0)
                    
                    Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                    return
                end
            end
            
            % Check the dimensionality of the history data
            [r, c] = size(scale);
            if r ~= 1.0 && c ~= 1.0
                setappdata(0, 'E020', 1.0)
                setappdata(0, 'loadHistoryUnableOpen', scale)
                
                error = true;

                Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                return
            elseif c == 1.0
                scale = scale';
            end
            
            if length(scale) > 2.0
                % Remove leading zeros
                leadingZeros = 1.0;
                while leadingZeros == 1.0
                    if scale(1.0) == 0.0
                        scale(1.0) = [];
                    else
                        leadingZeros = 0.0;
                    end
                end
            end
            
            % Scale the current load history
            scale = scale.*hfScales;
            
            % Return the stress tensor
            L = length(scale);
            Sxx = scale;
            Syy = zeros(1.0, L);
            Szz = zeros(1.0, L);
            Txy = zeros(1.0, L);
            Tyz = zeros(1.0, L);
            Txz = zeros(1.0, L);
        end
        
        %% Scale and combine high frequency load/channel dataset pairs:
        function [Sxx, Syy, Szz, Txy, Tyz, Txz, error] = scalecombineHF(channels, scales, items, hfScales)
            error = 0.0;
            
            % Make sure the loading and history files exist
            if ischar(channels)
                if exist(channels, 'file') == 0.0
                    error = 1.0;
                    setappdata(0, 'E035', 1.0)
                    setappdata(0, 'errorMissingChannel', channels)
                end
            else
                for i = 1:length(channels)
                    if exist(channels{i}, 'file') == 0.0
                        error = 1.0;
                        setappdata(0, 'E035', 1.0)
                        setappdata(0, 'errorMissingChannel', channels{i})
                        break
                    end
                end
            end
            
            if ischar(scales)
                % Single load history defined from file
                if isempty(scales) == 1.0
                    error = 1.0;
                    setappdata(0, 'E047', 1.0)
                elseif exist(scales, 'file') == 0.0
                    error = 1.0;
                    setappdata(0, 'E036', 1.0)
                    setappdata(0, 'errorMissingScale', scales)
                end
            elseif isnumeric(scales) == 1.0 && isempty(scales) == 0.0
                % Single load history defined directly
                if isempty(scales) == 1.0
                    error = 1.0;
                    setappdata(0, 'E047', 1.0)
                end
            else
                % There is more than one load history defined
                for i = 1:length(scales)
                    if isempty(scales{i}) == 1.0
                        error = 1.0;
                        setappdata(0, 'E047', 1.0)
                    elseif (ischar(scales{i}) == 1.0) && (exist(scales{i}, 'file') == 0.0)
                        % The current load history is defined from a file
                        error = 1.0;
                        setappdata(0, 'E036', 1.0)
                        setappdata(0, 'errorMissingScale', scales{i})
                        break
                    elseif (isnumeric(scales{i}) == 1.0) && (isempty(scales{i}) == 1.0)
                        % The current load history is defined directly
                        error = 1.0;
                        setappdata(0, 'E036', 1.0)
                        setappdata(0, 'errorMissingScale', scales{i})
                        break
                    end
                end
            end
            
            if error == 1.0
                Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                
                return
            end
            
            %% If the user specified a dataset sequence, a scale and combine loading is not required
            if isempty(scales) == 1.0
                [error, Sxx, Syy, Szz, Txy, Tyz, Txz] = highFrequency.datasetSequenceHF(channels, items, hfScales);
                return
            end
            
            %% Make sure there are the same number of channels as scales:
            
            error = false;
            if (ischar(scales) == 0.0) && (ischar(channels) == 0.0)
                % Multiple channels and loads appear to be defined
                if (length(channels) ~= length(scales))
                    Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                    
                    error = true;
                    setappdata(0, 'E012', 1.0)
                    return
                end
                multiple = 1.0;
            elseif (ischar(scales) == 0.0) && (ischar(channels) == 1.0)
                % A single channel is defined, but the scales appear to have
                % multiple definitions
                if isnumeric(scales) == 1.0
                    % The scales appeared to have multiple definitions because
                    % they're numeric
                    multiple = 0.0;
                elseif length(scales) == 1.0
                    messenger.writeMessage(29.0)
                    
                    multiple = 2.0;
                else
                    Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                    
                    error = true;
                    setappdata(0, 'E013', 1.0)
                    setappdata(0, 'history', scales)
                    return
                end
            elseif (ischar(scales) == 1.0) && (ischar(channels) == 0.0)
                % A single scale is defined, but the channels appear to have
                % multiple definitions
                if length(channels) == 1.0
                    messenger.writeMessage(29.0)
                else
                    Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                    
                    error = true;
                    setappdata(0, 'E014', 1.0)
                    return
                end
                
                multiple = 3.0;
            else
                multiple = 0.0;
            end
            
            try
                %% Load files:
                
                j1 = 1.0; first_time = 1.0;
                
                if multiple == 1.0
                    L = length(channels);
                else
                    L = 1.0;
                end
                
                % Verify the loading scale factors
                nScaleFactors = length(hfScales);
                
                if L == nScaleFactors
                    % Dataset/history pairs equal to number of scale factors
                elseif L > nScaleFactors
                    messenger.writeMessage(6.0);
                    
                    % Dataset/history pairs greater than number of scale factors
                    extraScaleFactors = linspace(hfScales(end), hfScales(end), (L - nScaleFactors));
                    hfScales = [hfScales extraScaleFactors];
                elseif L < nScaleFactors
                    messenger.writeMessage(6.0);
                    
                    % Dataset/history pairs less than number of scale factors
                    scaleFactorsToDelete = nScaleFactors - L;
                    hfScales(end - (scaleFactorsToDelete - 1.0) : end) = [];
                end
                
                % Load each loading definition file before combining
                scaleBuffer = cell(1.0, L);
                historyLengths = zeros(1.0, L);
                
                for i = 1.0:L
                    if multiple == 1.0 || multiple == 2.0
                        if ischar(scales{i}) == 1.0
                            try
                                scale = dlmread(scales{i});
                            catch unhandledException
                                error = true;
                                setappdata(0, 'E016', 1.0)
                                setappdata(0, 'error_log_016_exceptionMessage', unhandledException.message)
                                setappdata(0, 'loadHistoryUnableOpen', scales{i})
                                
                                if exist(scales{i}, 'file') == 0.0
                                    setappdata(0, 'scaleNotFound', 1.0)
                                end
                                
                                Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                                return
                            end
                        else
                            % The scale is defined directly in the job file
                            scale = scales{i};
                        end
                    else
                        if ischar(scales) == 1.0
                            try
                                scale = dlmread(scales);
                            catch unhandledException
                                error = true;
                                setappdata(0, 'E016', 1.0)
                                setappdata(0, 'error_log_016_exceptionMessage', unhandledException.message)
                                setappdata(0, 'loadHistoryUnableOpen', scales)
                                
                                if exist(scales, 'file') == 0.0
                                    setappdata(0, 'scaleNotFound', 1.0)
                                end
                                
                                Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                                return
                            end
                        else
                            % The scale is defined directly in the job file
                            scale = scales;
                        end
                    end
                    
                    % Remove INF/NaN values from load history data
                    scale(scale == inf) = [];
                    scale(scale == -inf) = [];
                    scale(isnan(scale)) = [];
                    
                    % Check the length of the history data
                    if length(scale) < 2.0
                        if getappdata(0, 'compositeCriteria') == 1.0
                            %{
                                For composite failure criteria analysis, a
                                load history 1 point is permitted. Prepend
                                a zero to the load history
                            %}
                            scale = [0.0, scale]; %#ok<AGROW>
                        else
                            error = true;
                            setappdata(0, 'E017', 1.0)
                            
                            Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                            return
                        end
                    end
                    
                    % Check the dimensionality of the history data
                    [r, c] = size(scale);
                    if r ~= 1.0 && c ~= 1.0
                        setappdata(0, 'E020', 1.0)
                        setappdata(0, 'loadHistoryUnableOpen', scales{i})
                        
                        error = true;
                        
                        Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                        return
                    elseif c == 1.0
                        scale = scale';
                    end
                    
                    % Scale the current load history
                    scale = scale.*hfScales(i);
                    
                    % Store the current loading into the buffer
                    scaleBuffer{i} = scale;
                    historyLengths(i) = length(scale);
                end
                
                % Make sure each loading is the same length
                if (max(historyLengths) - min(historyLengths)) ~= 0.0
                    % Get the length of the largest load history
                    maxLength = max(historyLengths);
                    
                    % Corect the length of each load history
                    for i = 1:L
                        if (maxLength - length(scaleBuffer{i})) ~= 0.0
                            difference = zeros(1, maxLength - length(scaleBuffer{i}));
                            scaleBuffer{i} = [scaleBuffer{i}, difference];
                        end
                    end
                end
                
                % Combine the load histories with the stress definitions
                
                for i = 1:L
                    if multiple == 1.0 || multiple == 3.0
                        % Simple loading
                        [channel, error] = highFrequency.readRPTHF(channels{i}, items);
                    else
                        % Multiple load history
                        [channel, error] = highFrequency.readRPTHF(channels, items);
                    end
                    
                    if isempty(channel)
                        Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                        
                        error = true;
                        setappdata(0, 'E015', 1.0)
                        return
                    end
                    
                    %% Make sure channel/loading files are correctly defined:
                    
                    [row, col] = size(channel);
                    skip = col - 6.0;
                    if col < 6.0
                        error = true;
                        setappdata(0, 'E019', 1.0)
                        
                        Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                        return
                    end
                    
                    if error
                        Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                        return
                    end
                    
                    %% Scale channel:
                    if first_time == 1.0
                        [Lc, ~] = size(channel);
                        Ls = length(scaleBuffer{i});
                        
                        % It's possible to encounter memory problems here, if
                        % the load history is very large
                        try
                            scaled_channels = zeros(Ls, 6, Lc*length(channels));
                        catch unhandledException
                            error = true;
                            setappdata(0, 'E045', 1.0)
                            setappdata(0, 'error_log_045_exceptionMessage', unhandledException.message)
                            Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                            return
                        end
                        
                        itemsInPreviousRow = row;
                        first_time = 0.0;
                    else
                        %% Make sure the current channel has the same number of items as the previous channel
                        if row ~= itemsInPreviousRow
                            error = true;
                            setappdata(0, 'E043', 1.0)
                            Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                            return
                        end
                    end
                    
                    for j = 1:Lc % Loop over each node
                        for k = 1:6 % Loop over tensor components
                            scaled_channels(:, k, j1) = channel(j, k+skip)*scaleBuffer{i};
                        end
                        
                        j1 = j1 + 1.0;
                    end
                end
                
                %% Combine the scaled channels:
                
                a = 1.0;  b = Lc - 1.0;
                combined_channel = zeros(Ls, 6.0, Lc);
                
                for i = 1:Lc
                    for j = a:Lc:(length(channels)*Lc) - b
                        combined_channel(:,:,i) = combined_channel(:,:,i)+...
                            scaled_channels(:,:,j);
                    end
                    
                    a = a + 1.0;
                    b = b - 1.0;
                end
                
            catch unhandledException
                error = true;
                setappdata(0, 'E022', 1.0)
                setappdata(0, 'error_log_022_exceptionMessage', unhandledException.message)
                
                Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                return
            end
            
            %% Assign the combined stresses to their individual components:
            
            Sxx(:,:) = combined_channel(:, 1.0, :);
            Syy(:,:) = combined_channel(:, 2.0, :);
            Szz(:,:) = combined_channel(:, 3.0, :);
            Txy(:,:) = combined_channel(:, 4.0, :);
            Txz(:,:) = combined_channel(:, 5.0, :);
            Tyz(:,:) = combined_channel(:, 6.0, :);
            
            Sxx = Sxx';
            Syy = Syy';
            Szz = Szz';
            Txy = Txy';
            Txz = Txz';
            Tyz = Tyz';
        end
        
        %% Combine a sequence of stress datasets
        function [error, Sxx, Syy, Szz, Txy, Tyz, Txz] = datasetSequenceHF(channels, items, hfScales)
            %% Assume that a dataset sequence has been defined
            error = 0.0;
            L = length(channels);
            first_time = 1.0;
            
            % Get the composite criteria flag
            compositeCriteria = getappdata(0, 'compositeCriteria');
            
            % Begin reading datasets
            if compositeCriteria == 1.0
                if ischar(channels) == 1.0
                    channels = {channels, channels};
                elseif length(channels) == 1.0
                    channels = [channels(1.0), channels(1.0)];
                end
            else
                if ischar(channels) == 1.0
                    if isempty(channels) == 1.0
                        setappdata(0, 'E023', 1.0)
                    else
                        setappdata(0, 'E024', 1.0)
                    end
                    
                    error = true;
                    Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                    return
                elseif length(channels) == 1.0
                    setappdata(0, 'E024', 1.0)
                    
                    error = true;
                    Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                    return
                end
            end
            
            % Verify the loading scale factors
            nScaleFactors = length(hfScales);
            
            if L == nScaleFactors
                % Dataset/history pairs equal to number of gate values
            elseif L > nScaleFactors
                setappdata(0, 'message_281_hf', 1.0)
                messenger.writeMessage(281.0);
                
                % Dataset/history pairs greater than number of gate values
                extraScaleFactors = linspace(hfScales(end), hfScales(end), (L - nScaleFactors));
                hfScales = [hfScales extraScaleFactors];
            elseif L < nScaleFactors
                setappdata(0, 'message_281_hf', 1.0)
                messenger.writeMessage(281.0);
                
                % Dataset/history pairs less than number of gate values
                scaleFactorsToDelete = nScaleFactors - L;
                hfScales(end - (scaleFactorsToDelete - 1) : end) = [];
            end
            
            try 
                for i = 1:L
                    [channel, error] = highFrequency.readRPTHF(channels{i}, items);
                    
                    % Scale the channel
                    channel = channel.*hfScales(i);
                    
                    if isempty(channel) == 1.0
                        error = true;
                        setappdata(0, 'E015', 1.0)
                        
                        Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                        return
                    end
                    
                    [~, col] = size(channel);
                    if col < 6.0
                        error = true;
                        setappdata(0, 'E019', 1.0)
                        
                        Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                        return
                    end
                    
                    %% Concatenate the datasets into a sequence
                    if first_time == 1.0
                        [Lc, ~] = size(channel);
                        channelSequence = zeros(Lc, 6, L);
                        first_time = 0.0;
                    end
                    
                    channelSequence(:, :, i) = channel;
                end
            catch
                error = true;
                setappdata(0, 'E022', 1.0)
                
                Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
                return
            end
            
            %% Get tensor components
            Sxx(:,:) = channelSequence(:, 1.0, :);
            Syy(:,:) = channelSequence(:, 2.0, :);
            Szz(:,:) = channelSequence(:, 3.0, :);
            Txy(:,:) = channelSequence(:, 4.0, :);
            Txz(:,:) = channelSequence(:, 5.0, :);
            Tyz(:,:) = channelSequence(:, 6.0, :);
            
            if Lc == 1.0
                Sxx = Sxx';
                Syy = Syy';
                Szz = Szz';
                Txy = Txy';
                Txz = Txz';
                Tyz = Tyz';
            end
            
            return
        end
        
        %% Read stresses from RPT file:
        function [TENSOR, error] = readRPTHF(FILENAME, items)
            
            error = 0.0;
            TENSOR = [];
            
            %% Open the .rpt file:
            
            fid = fopen(FILENAME, 'r');
            setappdata(0, 'FOPEN_error_file', FILENAME)
            
            if fid == -1.0
                error = 1.0;
                setappdata(0, 'E026', 1.0)
                
                return
            end
            
            %% Check if there is a header:
            
            try
                cellData = textscan(fid, '%f %f %f %f %f %f %f %f %f %f');
            catch
                error = 1.0;
                setappdata(0, 'E027', 1.0)
                
                return
            end
            
            if isempty(cellData{1.0})
                hasHeader = true; % There is a header in the file
            else
                hasHeader = false; % There might be no header in the file
            end
            
            if hasHeader == 0.0
                for i = 1.0:length(cellData)
                    if isempty(cellData{i})
                        hasHeader = true;
                        break
                    end
                end
            end
            
            %% Scan the file:
            
            if hasHeader
                cellData_region = cell(1.0);
                region = 0.0;
                
                while feof(fid) == 0.0
                    % Begin searching the file for the first set of data
                    fgetl(fid);
                    cellData = textscan(fid, '%f %f %f %f %f %f %f %f %f %f');
                    
                    if isempty(cellData{1.0}) == 0.0
                        %{
                            A region of data has been found. Add the current
                            region to the nested cell
                        %}
                        region = region + 1.0;
                        cellData_region{region} = cellData;
                    end
                end
                
                %{
                    Concatenate individual regions into single cell if
                    necessary
                %}
                if region > 1.0
                    for region_ID = 1:10
                        %{
                            For each region in the model, concatenate
                            each nested cell
                        %}
                        region_index = 2.0;
                        
                        a = cellData_region{1.0};
                        c = a{region_ID};
                        while region_index <= region
                            a = cellData_region{region_index};
                            c = [c; a{region_ID}]; %#ok<AGROW>
                            
                            region_index = region_index + 1.0;
                        end
                        
                        %{
                            The current column of data has been concatenated
                            for every region. Move on to the next column
                        %}
                        cellData{region_ID} = c;
                    end
                end
            end
            
            %{
                If the REGION variable is undefined, it could be because
                multiple data blocks were specified in the RPT file without
                text headers. Assume a single region in the model
            %}
            if exist('region', 'var') == 0.0
                region = 1.0;
            end
            
            %% Remove unused columns if necessary:
            
            % Initialize the dataset buffers
            fieldDataBuffer = cell(1.0, region);
            mainIDBuffer = cell(1.0, region);
            
            if region < 2.0
                region = 1.0;
                cellData_region_i = cellData;
            end
            
            % Buffer for total number of analysis items in the model
            R = 0.0;
            
            for i = 1:region
                remove = 0.0;
                
                % Get the cell data for the current region
                if region > 1.0
                    cellData_region_i = cellData_region{i};
                end
                
                % Plane stress, shell section data, one position label columns
                if length(cellData_region_i{10.0}) ~= length(cellData_region_i{1.0})
                    cellData_region_i{10.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 1.0;
                elseif isnan(cellData_region_i{10.0})
                    cellData_region_i{10.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 1.0;
                end
                
                % 3D stress, two position label columns
                if length(cellData_region_i{9.0}) ~= length(cellData_region_i{1.0})
                    cellData_region_i{9.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 2.0;
                elseif isnan(cellData_region_i{9.0})
                    cellData_region_i{9.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 2.0;
                end
                
                % 3D stress, one position label column
                if length(cellData_region_i{8.0}) ~= length(cellData_region_i{1.0})
                    cellData_region_i{8.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 3.0;
                elseif isnan(cellData_region_i{8.0})
                    cellData_region_i{8.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 3.0;
                end
                
                % 3D stress, no position label columns
                % OR
                % Plane stress, two position label columns
                if length(cellData_region_i{7.0}) ~= length(cellData_region_i{1.0})
                    cellData_region_i{7.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 4.0;
                elseif isnan(cellData_region_i{7.0})
                    cellData_region_i{7.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 4.0;
                end
                
                % Plane stress, one position label column
                if length(cellData_region_i{6.0}) ~= length(cellData_region_i{1.0})
                    cellData_region_i{6.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 5.0;
                elseif isnan(cellData_region_i{6.0})
                    cellData_region_i{6.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 5.0;
                end
                
                % Plane stress, no position label columns
                if length(cellData_region_i{5.0}) ~= length(cellData_region_i{1.0})
                    cellData_region_i{5.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 6.0;
                elseif isnan(cellData_region_i{5.0})
                    cellData_region_i{5.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 6.0;
                end
                
                % 1D stress, two position label columns
                if length(cellData_region_i{4.0}) ~= length(cellData_region_i{1.0})
                    cellData_region_i{4.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 7.0;
                elseif isnan(cellData_region_i{4.0}) == 1.0
                    cellData_region_i{4.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 7.0;
                end
                
                % 1D stress, one position label column
                if length(cellData_region_i{3.0}) ~= length(cellData_region_i{1.0})
                    cellData_region_i{3.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 8.0;
                elseif isnan(cellData_region_i{3.0}) == 1.0
                    cellData_region_i{3.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 8.0;
                end
                
                % 1D stress, no position label columns
                if length(cellData_region_i{2.0}) ~= length(cellData_region_i{1.0})
                    cellData_region_i{2.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 9.0;
                elseif isnan(cellData_region_i{2.0}) == 1.0
                    cellData_region_i{2.0} = zeros(length(cellData_region_i{1.0}), 1.0, 'double');
                    remove = 9.0;
                end
                
                %% Check for concatenation errors:
                
                try
                    fieldData_i = cell2mat(cellData_region_i);
                catch
                    error = 1.0;
                    setappdata(0, 'E028', 1.0)
                    
                    return
                end
                
                if isempty(fieldData_i)
                    error = 1.0;
                    setappdata(0, 'E029', 1.0)
                    
                    return
                elseif any(any(isnan(fieldData_i))) || any(any(isinf(fieldData_i)))
                    error = 1.0;
                    setappdata(0, 'E030', 1.0)
                    
                    return
                end
                
                if remove == 9.0
                    fieldData_i(:, 2:10) = [];
                elseif remove == 8.0
                    fieldData_i(:, 3:10) = [];
                elseif remove == 7.0
                    fieldData_i(:, 4:10) = [];
                elseif remove == 6.0
                    fieldData_i(:, 5:10) = [];
                elseif remove == 5.0
                    fieldData_i(:, 6:10) = [];
                elseif remove == 4.0
                    fieldData_i(:, 7:10) = [];
                elseif remove == 3.0
                    fieldData_i(:, 8:10) = [];
                elseif remove == 2.0
                    fieldData_i(:, 9:10) = [];
                elseif remove == 1.0
                    fieldData_i(:, 10) = [];
                end
                
                %% Interpret columns:
                
                %{
                    NODETYPE: Format of nodal information
                    0: No listing. Take item label from row number
                    1: Centroidal
                    2: Element-nodal or integration point
                    -1: Error
                %}
                
                % Get the element type
                elementType = getappdata(0, 'elementType');
                elementError = 0.0;
                if isempty(elementType)
                    elementType = 0.0;
                elseif isnumeric(elementType) == 0.0
                    elementType = 0.0;
                elseif isnan(elementType) || isreal(elementType) == 0.0 || ...
                        isinf(elementType) || isreal(elementType) == 0.0
                    elementType = 0.0;
                end
                
                [Ri, C] = size(fieldData_i);
                switch C
                    case 10.0
                        mainIDs_i = fieldData_i(:, 1.0);
                        
                        if getappdata(0, 'shellLocation') == 1.0
                            fieldData_i(:, 4:2:10) = [];
                        elseif getappdata(0, 'shellLocation') == 2.0
                            fieldData_i(:, 3:2:9) = [];
                        end
                        
                        X = 3.0;
                        
                        fieldData_i(:, 7:8) = 0.0;
                    case 9.0
                        mainIDs_i = fieldData_i(:, 1.0);
                        
                        if getappdata(0, 'shellLocation') == 1.0
                            fieldData_i(:, 3:2:9) = [];
                        elseif getappdata(0, 'shellLocation') == 2.0
                            fieldData_i(:, 2:2:8) = [];
                        end
                        
                        X = 2.0;
                        
                        fieldData_i(:, 6:7) = 0.0;
                    case 8.0
                        mainIDs_i = fieldData_i(:, 1.0);
                        
                        X = 3.0;
                    case 7.0
                        mainIDs_i = fieldData_i(:, 1.0);
                        
                        X = 2.0;
                    case 6.0
                        if elementType == 0.0
                            mainIDs_i = linspace(1.0, Ri, Ri)';
                            X = 1.0;
                        else
                            mainIDs_i = fieldData_i(:, 1.0);
                            X = 3.0;
                            
                            fieldData_i(:, 7:8) = 0.0;
                        end
                    case 5.0
                        mainIDs_i = fieldData_i(:, 1.0);
                        X = 2.0;
                        
                        fieldData_i(:, 6:7) = 0.0;
                    case 4.0
                        if elementType == 0.0
                            mainIDs_i = linspace(1.0, Ri, Ri)';
                            X = 1.0;
                            
                            fieldData_i(:, 5:6) = 0.0;
                        else
                            mainIDs_i = fieldData_i(:, 1.0);
                            X = 3.0;
                            
                            fieldData_i(:, 5:8) = 0.0;
                        end
                    case 3.0
                        if elementType == 0.0
                            mainIDs_i = fieldData_i(:, 1.0);
                            X = 3.0;
                            
                            fieldData_i(:, 4:8) = 0.0;
                        else
                            mainIDs_i = fieldData_i(:, 1.0);
                            X = 2.0;
                            
                            fieldData_i(:, 4:7) = 0.0;
                        end
                    case 2.0
                        if elementType == 0.0
                            mainIDs_i = fieldData_i(:, 1.0);
                            X = 2.0;
                            
                            fieldData_i(:, 3:7) = 0.0;
                        else
                            mainIDs_i = linspace(1.0, 1.0, Ri)';
                            X = 1.0;
                            
                            fieldData_i(:, 3:6) = 0.0;
                        end
                    case 1.0
                        mainIDs_i = linspace(1.0, 1.0, Ri)';
                        X = 1.0;
                        
                        fieldData_i(:, 2:6) = 0.0;
                    otherwise
                        error = 1.0;
                        setappdata(0, 'E031', 1.0)
                        
                        return
                end
                
                % Append the data from the current group to the buffers
                fieldDataBuffer{i} = fieldData_i;
                mainIDBuffer{i} = mainIDs_i;
                
                % Add the number of items in the region to the total
                R = R + Ri;
            end
            
            %% Concatenate data buffers
            fieldData = cell2mat(fieldDataBuffer');
            
            if elementError == 1.0
                error = 1.0;
                setappdata(0, 'E032', 1.0)
                
                return
            end
            
            %% Filter IDs if user specified individual analysis items 
            if (strcmpi(items, 'all') == 1.0) || (strcmpi(items, 'maxps') == 1.0) || (strcmpi(items, 'surface') == 1.0)
                items = [];
            elseif isnumeric(items) == 0.0
                if exist(items, 'file') == 2.0
                    setappdata(0, 'hotspotFile', items)
                    
                    % If ITEMS is defined as a file, verify its contents
                    items_file = importdata(items, '\t');
                    if iscell(items_file) == 1.0
                        items_file = cell2mat(items_file);
                        [~, itemCols] = size(items_file);
                    elseif isstruct(items_file) == 1.0
                        [~, itemCols] = size(items_file.data);
                    elseif isnumeric(items_file) == 1.0
                        [~, itemCols] = size(items_file);
                    else
                        itemCols = 0.0;
                    end
                    
                    if itemCols == 1.0
                        items_header = {'NONE'};
                        items_data = items_file;
                    else
                        try
                            items_data = items_file.data;
                            items_header = items_file.textdata;
                        catch
                            items_data = 'error';
                        end
                    end
                    
                    if strcmpi(items_data, 'error') == 1.0
                        items = [];
                        setappdata(0, 'items', 'ALL')
                        messenger.writeMessage(144.0)
                    elseif isempty(items_data) == 1.0
                        items = [];
                        setappdata(0, 'items', 'ALL')
                        messenger.writeMessage(143.0)
                    elseif (strcmpi(items_header{1.0}, 'hotspots') == 0.0 && strcmpi(items_header{1.0}, 'surface items') == 0.0...
                            && strcmpi(items_header{1.0}, 'warn_lcf_items') == 0.0&& strcmpi(items_header{1.0}, 'warn_yielding_items') == 0.0...
                            && strcmpi(items_header{1.0}, 'warn_overflow_items') == 0.0) && (itemCols ~= 1.0 && itemCols ~= 4.0)
                        items = [];
                        setappdata(0, 'items', 'ALL')
                        messenger.writeMessage(144.0)
                    else
                        items = items_data(:, 1.0);
                        messenger.writeMessage(266.0)
                    end
                elseif exist('items', 'file') == 0.0
                    % The file does not exist, so warn the user
                    setappdata(0, 'hotspotFile', items)
                    items = [];
                    setappdata(0, 'items', 'ALL')
                    messenger.writeMessage(145.0)
                end
            end
            
            if isempty(items) == 0.0
                % Remove duplicate items
                items = unique(items);
                
                if isempty(find(items > R, 1.0)) == 0.0
                    error = 1.0;
                    setappdata(0, 'E033', 1.0)
                    return
                end
                
                itemError = 0.0;
            else
                itemError = 1.0;
            end
            
            %% Get tensor components:
            if (isempty(items) == 0.0) && (itemError == 0.0)
                Sxx = fieldData(items, X)';
                Syy = fieldData(items, X + 1.0)';
                Szz = fieldData(items, X + 2.0)';
                Txy = fieldData(items, X + 3.0)';
                Txz = fieldData(items, X + 4.0)';
                Tyz = fieldData(items, X + 5.0)';
            else
                Sxx = fieldData(:, X)';
                Syy = fieldData(:, (X + 1.0))';
                Szz = fieldData(:, (X + 2.0))';
                Txy = fieldData(:, (X + 3.0))';
                Txz = fieldData(:, (X + 4.0))';
                Tyz = fieldData(:, (X + 5.0))';
            end
            
            TENSOR = [Sxx; Syy; Szz; Txy; Txz; Tyz]';
            
            % Warn the user if the tensor is empty
            if all(all(TENSOR == 0.0)) == 1.0
                messenger.writeMessage(121.0)
            end
            
            fclose(fid);
        end
        
        %% Superimpose the high frequency data onto the loading for a uniaxial signal
        function [Sxx, Syy, Szz, Txy, Tyz, Txz, error] = superimposeUniaxial(lowF, highF, timeLo, timeHi)
            error = 0.0;
            Sxx = 0.0; Syy = 0.0; Szz = 0.0; Txy = 0.0; Tyz = 0.0; Txz = 0.0;
            
            % High frequency dataset must have a shorter time period
            if timeLo < timeHi
                error = 1.0;
                
                setappdata(0, 'E041', 1.0)
                setappdata(0, 'errTimeLo', timeLo)
                setappdata(0, 'errTimeHi', timeHi)
                return
            end
            
            lengthLowF = length(lowF);
            lengthHighF = length(highF);
            
            % Get the sample rate for the low frequency block
            sampleRate = (timeLo/timeHi)*(lengthHighF/lengthLowF);
            
            if lengthLowF < 3.0
                % LF signal must have length of at least 3.0
                lowF(end + 1.0) = 0.0;
                lengthLowF = lengthLowF + 1.0;
                
                messenger.writeMessage(123.0)
            end

            %% Re-sample the thermal signal
            if sampleRate < 1.0
                %{
                    The LF data contains more samples than necessary by
                    interpolation. Downsample the LF data.
                %}
                lowF_interp = downsample(lowF, floor(1.0/sampleRate));
            elseif sampleRate > 1.0
                %{
                    The LF data has less samples than required to
                    superimpose the HF data. Interpolate the LF data.
                %}
                
                % Get the half-number parameter L
                if lengthLowF < 9.0
                    L = floor((lengthLowF - 1.0)/2.0);
                else
                    L = 4.0;
                end
                
                % Set the normalized cut-off frequency
                R = 0.5;
                
                % Interpolate the low frequency block
                lowF_interp = interp(lowF, ceil(sampleRate), L, R);
                
                %{
                    After inteprolation, the last value of the signal is
                    often too large. Adjust the last point so that it is
                    the average of all previous points:
                
                    1. Get the mean of the last two points
                    2. Adjust the last point to the penultimate point
                    3. Adjust the penultimate point to the mean
                %}
                lowF_interp = highFrequency.adjustEndpoint(lowF, lowF_interp);
            end
            
            lengthLowF_interp = length(lowF_interp);
            
            % Remove extra data points generated by the re-sampling process
            resampledLength = floor((lengthHighF*(timeLo/timeHi)));
            if lengthLowF_interp > resampledLength
                diff = lengthLowF_interp - resampledLength;
                lowF_interp(end - (diff - 1.0):end) = [];
            end
            
            % Create the repeating high frequency data
            numberOfRepeats = (timeLo/timeHi);
            highF_final = zeros(1.0, resampledLength);
            j = 1.0;
            for i = 1:numberOfRepeats
                highF_final(j:j+lengthHighF-1) = highF;
                j = j + lengthHighF;
            end
            
            Sxx = lowF_interp + highF_final;
            Syy = zeros(1.0, resampledLength);
            Szz = Syy;
            Txy = Syy;
            Tyz = Syy;
            Txz = Syy;
        end
        
        %% Superimpose the high frequency data onto the loading for scale and combine signal
        function [Sxx, Syy, Szz, Txy, Tyz, Txz, error] = superimpose(highF_xx, highF_yy, highF_zz, highF_xy, highF_yz, highF_xz,...
                Sxx, Syy, Szz, Txy, Tyz, Txz, timeLo, timeHi)
            error = 0.0;
            
            % Get signal lengths and the number of analysis items
            [N, lengthLowF] = size(Sxx);
            [~, lengthHighF] = size(highF_xx);
            
            % Signal must be at least 3 datapoints
            if lengthLowF < 3.0
                Sxx(:, end + 1.0) = 0.0;
                Syy(:, end + 1.0) = 0.0;
                Szz(:, end + 1.0) = 0.0;
                Txy(:, end + 1.0) = 0.0;
                Tyz(:, end + 1.0) = 0.0;
                Txz(:, end + 1.0) = 0.0;
                
                lengthLowF = lengthLowF + 1.0;
                
                messenger.writeMessage(123.0)
            end
            
            % High frequency dataset must have a shorter time period
            if timeLo < timeHi
                error = 1.0;
                setappdata(0, 'E041', 1.0)
                setappdata(0, 'errTimeLo', timeLo)
                setappdata(0, 'errTimeHi', timeHi)
                return
            elseif isempty(timeLo) == 1.0 || isempty(timeHi) == 1.0
                error = 1.0;
                setappdata(0, 'E044', 1.0)
                return
            end
            
            % Get the sample rate for the low frequency block
            sampleRate = (timeLo/timeHi)*(lengthHighF/lengthLowF);
            
            resampledLength = floor((lengthHighF*(timeLo/timeHi)));
            
            downSample = 0.0;
            if sampleRate < 1.0
                %{
                    The LF data contains more samples than necessary by
                    interpolation. Downsample the LF data.
                %}
                sampleRate = floor(1.0/sampleRate);
                downSample = 1.0;
            elseif sampleRate > 1.0
                %{
                    The LF data has less samples than required to superimpose
                    the HF data. Interpolate the LF data.
                %}
                sampleRate = ceil(sampleRate);
                
                % Get the half-number parameter L
                if lengthLowF < 9.0
                    L = floor((lengthLowF - 1.0)/2.0);
                else
                    L = 4.0;
                end
                
                % Set the normalized cut-off frequency
                R = 0.5;
            end
            
            % Create containers for new datasets
            final_xx = zeros(N, resampledLength);
            final_yy = final_xx;
            final_zz = final_xx;
            final_xy = final_xx;
            final_yz = final_xx;
            final_xz = final_xx;
            
            %{
                Superimpose the high frequency dataset onto the loading
                block for each analysis item
            %}
            for i = 1:N
                % Get the low frequency block at the current item
                lowF_xx = Sxx(i, :);
                lowF_yy = Syy(i, :);
                lowF_zz = Szz(i, :);
                lowF_xy = Txy(i, :);
                lowF_yz = Tyz(i, :);
                lowF_xz = Txz(i, :);
                
                if downSample == 1.0
                    % Downsample the low frequency block
                    lowF_interp_xx = downsample(lowF_xx, sampleRate);
                    lowF_interp_yy = downsample(lowF_yy, sampleRate);
                    lowF_interp_zz = downsample(lowF_zz, sampleRate);
                    lowF_interp_xy = downsample(lowF_xy, sampleRate);
                    lowF_interp_yz = downsample(lowF_yz, sampleRate);
                    lowF_interp_xz = downsample(lowF_xz, sampleRate);
                else
                    % Interpolate the low frequency block
                    lowF_interp_xx = interp(lowF_xx, sampleRate, L, R);
                    lowF_interp_yy = interp(lowF_yy, sampleRate, L, R);
                    lowF_interp_zz = interp(lowF_zz, sampleRate, L, R);
                    lowF_interp_xy = interp(lowF_xy, sampleRate, L, R);
                    lowF_interp_yz = interp(lowF_yz, sampleRate, L, R);
                    lowF_interp_xz = interp(lowF_xz, sampleRate, L, R);
                end
                
                %{
                    After inteprolation, the last value of the signal is
                    often too large. Adjust the last point so that it is
                    the average of all previous points:
                
                    1. Get the mean of the last two points
                    2. Adjust the last point to the penultimate point
                    3. Adjust the penultimate point to the mean
                %}
                lowF_interp_xx = highFrequency.adjustEndpoint(lowF_xx, lowF_interp_xx);
                lowF_interp_yy = highFrequency.adjustEndpoint(lowF_yy, lowF_interp_yy);
                lowF_interp_zz = highFrequency.adjustEndpoint(lowF_zz, lowF_interp_zz);
                lowF_interp_xy = highFrequency.adjustEndpoint(lowF_xy, lowF_interp_xy);
                lowF_interp_yz = highFrequency.adjustEndpoint(lowF_yz, lowF_interp_yz);
                lowF_interp_xz = highFrequency.adjustEndpoint(lowF_xz, lowF_interp_xz);
                
                % Get the length of the interpolated signal
                lengthLowF_interp = length(lowF_interp_xx);
                
                % Remove extraneous data points introduced by the re-sampling process
                if lengthLowF_interp > resampledLength
                    diff = lengthLowF_interp - resampledLength;
                    
                    lowF_interp_xx(end - (diff - 1.0):end) = [];
                    lowF_interp_yy(end - (diff - 1.0):end) = [];
                    lowF_interp_zz(end - (diff - 1.0):end) = [];
                    lowF_interp_xy(end - (diff - 1.0):end) = [];
                    lowF_interp_yz(end - (diff - 1.0):end) = [];
                    lowF_interp_xz(end - (diff - 1.0):end) = [];
                end
                
                % Create the repeating high frequency data
                numberOfRepeats = (timeLo/timeHi);
                highF_final_xx = zeros(1.0, resampledLength);
                highF_final_yy = highF_final_xx;
                highF_final_zz = highF_final_xx;
                highF_final_xy = highF_final_xx;
                highF_final_yz = highF_final_xx;
                highF_final_xz = highF_final_xx;
                
                k = 1.0;
                
                for j = 1:numberOfRepeats
                    highF_final_xx(k : k + lengthHighF - 1.0) = highF_xx(i, :);
                    highF_final_yy(k : k + lengthHighF - 1.0) = highF_yy(i, :);
                    highF_final_zz(k : k + lengthHighF - 1.0) = highF_zz(i, :);
                    highF_final_xy(k : k + lengthHighF - 1.0) = highF_xy(i, :);
                    highF_final_yz(k : k + lengthHighF - 1.0) = highF_yz(i, :);
                    highF_final_xz(k : k + lengthHighF - 1.0) = highF_xz(i, :);
                    
                    k = k + lengthHighF;
                end
                
                final_xx(i, :) = lowF_interp_xx + highF_final_xx;
                final_yy(i, :) = lowF_interp_yy + highF_final_yy;
                final_zz(i, :) = lowF_interp_zz + highF_final_zz;
                final_xy(i, :) = lowF_interp_xy + highF_final_xy;
                final_yz(i, :) = lowF_interp_yz + highF_final_yz;
                final_xz(i, :) = lowF_interp_xz + highF_final_xz;
            end
            
            % Copy new datasets to the old datasets
            Sxx = final_xx;
            Syy = final_yy;
            Szz = final_zz;
            Txy = final_xy;
            Tyz = final_yz;
            Txz = final_xz;
        end
        
        %% Correct the end point of the interpolated signal
        function [lowF_interp] = adjustEndpoint(lowF, lowF_interp)
            %{
                Get the ratio between the last point of the interpolated
                and the original history
            %}
            if abs(lowF_interp(end)) > abs(lowF(end))
                ratio = lowF_interp(end)/lowF(end);
            else
                ratio = lowF(end)/lowF_interp(end);
            end
            
            %{
                If the difference is greater than 5%, adjust the tail of
                the interpolated data
            %}
            if ratio > 1.05
                L = length(lowF_interp);
                
                % Get the sign of the gradient of the tail
                signG = sign(lowF_interp(end) - lowF_interp(end - 1.0));
                signGi = signG;
                
                % Find the number of points making up the tail
                index = L + 1.0;
                if all(diff(lowF_interp) < 0.0) == 1.0
                    %{
                        The entirety of the interpolated load history is a
                        single tail (sign does not change). The number of
                        points in the tail is equal to the number of points
                        in the interpolated load history
                    %}
                    signGi = 1.0;
                    index = 1.0;
                elseif all(diff(lowF_interp) > 0.0) == 1.0
                    signGi = -1.0;
                    index = 1.0;
                else
                    while signGi == signG
                        index = index - 1.0;
                        
                        if (index - 1.0) == 0.0
                            % This condition should already have been caught!
                            index = 1.0;
                        else
                            signGi = sign(lowF_interp(index) - lowF_interp(index - 1.0));
                        end
                    end
                end
                
                %{
                    do not perform the adjustment if the length of the tail
                    is more that 5% of the total length of the load history
                %}
                if (L - (index - 1.0))/L > 0.05
                    return
                end
                
                % Get the adjustment increment
                delta = (lowF_interp(index) - lowF(end))/(L - index);
                
                % If the tail is pointing downward, flip the sign of DELTA
                if signGi == 1.0
                    delta = -delta;
                end
                
                %{
                    Adjust the tail so that the last point of the
                    interpolated and the uninterpolated history are equal
                %}
                for i = index:(L - 1.0)
                    lowF_interp(i + 1.0) = lowF_interp(i) + delta;
                end
            end
        end
    end
end