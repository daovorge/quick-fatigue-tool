function [] = job(varargin)
%JOB    QFT function to submit analysis job from text file.
%   This function contains code to submit an analysis job from a text file
%   using the MATLAB command line.
%   
%   JOB(JOBNAME) submits an analysis job from a text file 'JOBNAME.*'
%   containing valid job file option and material definitions.
%
%   JOB(JOBNAME, OPTION) submits the analyis job JOBNAME with additional
%   options. Available options are:
%
%     'interactive' - print an echo of the message (.msg) file to the
%     MATLAB command window
%     'datacheck'   - submit the analysis job as a data check analysis
%     'library' - use the fatigue definition from JOBNAME (same as *DATA CHECK=2)
%
%   If the extention of the job file is '.inp', then the JOBNAME parameter
%   can be speficied without the extention.
%
%   See also importMaterial, keywords, fetchMaterial.
%
%   Reference section in Quick Fatigue Tool User Guide
%      2.4.2 Configuring a data check analysis
%      2.4.3 Configuring an analysis from a text file
%   
%   Reference section in Quick Fatigue Tool User Settings Reference Guide
%      1 Job file options
%   
%   Quick Fatigue Tool 6.11-11 Copyright Louis Vallance 2018
%   Last modified 30-Jan-2018 13:52:26 GMT
    
    %%
    
%% GET INPUT ARGUMENTS
% Initialize data check flag
datacheck = 0.0;    clc

switch nargin
    % User called JOB with no arguments
    case 0.0
        varargin = cellstr(input('Input file: ', 's'));
    % User called JOB with one argument
    case 1.0
        if strcmpi(varargin, 'interactive') == 1.0
            setappdata(0, 'force_echoMessagesToCWIN', 1.0)
            varargin = cellstr(input('Input file: ', 's'));
        elseif strcmpi(varargin, 'datacheck') == 1.0
            datacheck = 1.0;
            varargin = cellstr(input('Input file: ', 's'));
        elseif strcmpi(varargin, 'library') == 1.0
            datacheck = 2.0;
            varargin = cellstr(input('Input file: ', 's'));
        else
            % Assume that VARARGIN is JOBNAME
        end
    % User called JOB with more than one argument
    otherwise
        if nargin > 3.0
            fprintf('ERROR: JOB was called with too many input arguments\n');
            return
        elseif (strcmpi(varargin{1.0}, 'interactive') == 1.0) || (strcmpi(varargin{1.0}, 'datacheck') == 1.0) || (strcmpi(varargin{1.0}, 'library') == 1.0)
            fprintf('ERROR: The command line option ''%s'' is misplaced\n       Whenever JOB is called with OPTION, the first argument must be the name of the job file\n', varargin{1.0});
            return
        else
            datacheckAndContinue = 0.0;
            
            for i = 2:nargin
                if strcmpi(varargin{i}, 'interactive') == 1.0
                    setappdata(0, 'force_echoMessagesToCWIN', 1.0)
                elseif strcmpi(varargin{i}, 'datacheck') == 1.0
                    datacheckAndContinue = datacheckAndContinue + 1.0;
                    datacheck = 1.0;
                elseif strcmpi(varargin{i}, 'library') == 1.0
                    datacheckAndContinue = datacheckAndContinue + 1.0;
                    datacheck = 2.0;
                else
                    fprintf('ERROR: Invalid command line option ''%s''\n       Valid options are:\n[<jobName> | interactive | {datacheck | library}]\n', varargin{i});
                    return
                end
                
                if datacheckAndContinue > 1.0
                    fprintf('ERROR: The command line options ''datacheck'' and ''library'' are mutually-exclusive\n       Valid options are:\n[<jobName> | interactive | {datacheck | library}]\n');
                    return
                end
            end
        end
end

% The input file is the first argument
inputFile = varargin{1.0};

% Set default flag for analysis dialogues
if isempty(getappdata(0, 'analysisDialogues')) == 1.0
    setappdata(0, 'analysisDialogues', 1.0)
end

% Set default flag for overwrite dialogues
if isempty(getappdata(0, 'checkOverwrite')) == 1.0
    setappdata(0, 'checkOverwrite', 1.0)
end

%% INITIALIZE BUFFERS
[kwStr, kwStrSp, kwData] = keywords.initialize();

kwData{37.0} = datacheck;

% Flag indicating that text file processor was used
setappdata(0, 'jobFromTextFile', 1.0)

% Check the file extension
[~, NAME, EXT] = fileparts(inputFile);
if isempty(EXT) == 1.0
    inputFile = [inputFile, '.inp'];
elseif strcmp(EXT, '.') == 1.0
    inputFile = [inputFile, 'inp'];
elseif strcmp(EXT, '.m') == 1.0
    clc
    fprintf('ERROR: Input file ''%s'' is an M-file and cannot be submitted using JOB. Type the name of the M-file and hit RETURN, or right-click the file and select "Run"\n', inputFile);
    return
end

% Check that the file exists
if exist(inputFile, 'file') == 0.0
    clc
    fprintf('ERROR: Input file ''%s'' could not be located\n', inputFile);
    return
end

% Open the input file for reading
fid = fopen(inputFile, 'r+');

% Index to store incomplete keyword definitions
partialKw = cell(1.0, 1.0);
ambiguousKw = cell(1.0, 1.0);
undefinedKw = cell(1.0, 1.0);
incompleteKw = cell(1.0, 1.0);
assumedKw = cell(1.0, 1.0);
badKw = cell(1.0, 1.0);
processedKeywords = cell(1.0, 1.0);

index_pkw = 1.0;
index_ikw = 1.0;
index_ukw = 1.0;
index_akw = 1.0;
index_bkw = 1.0;
index_ckw = 1.0;

% Buffer to count the number of keywords successfully parsed
numberOfKeywords = 0.0;
emptyKeywords = 0.0;

% Buffer to store number of lines parsed by the material file processor
nTLINE_total = 0.0;

%% READ THE CURRENT LINE
% While the end of the file has not been reached
while feof(fid) == 0.0
    % Get the current line in the file
    TLINE = fgetl(fid);
    
    % If the current line is emtpy, skip to the next line
    if isempty(TLINE) == 1.0
        continue
    end
    
    % Check if the current line is a comment
    if (length(TLINE) > 1.0) && (strcmp(TLINE(1.0:2.0), '**') == 1.0)
        continue
    % Check that the current line is a keyword
    elseif strcmp(TLINE(1.0), '*') == 1.0
        % The current line is a keyword definition
        
        % Isolate the keyword
        TOKEN = strtok(TLINE, '=');
        
        %%
        %{
            If the current token is *USER MATERIAL, process this material
            and add it to the local database
        %}
        % Remove spaces and asterisk from the keyword
        TOKEN_umat = TOKEN;
        TOKEN_umat(ismember(TOKEN_umat,' *')) = [];
        
        % Isolate the keyword
        TOKEN_umat = strtok(lower(TOKEN_umat), ',');
        
        % Check if the keyword matches the library
        matchingKw = find(strncmpi({TOKEN_umat}, {'USERMATERIAL'}, length(TOKEN_umat)) == 1.0);
        
        if matchingKw == 1.0
            [error, material_properties, materialName, nTLINE_material, nTLINE_total] = importMaterial.processFile(inputFile, nTLINE_total); %#ok<ASGLU>
            
            %{
                Check to see if there is already a material by that name in
                the local database
            %}
            if exist(['Data/material/local/', materialName, '.mat'], 'file') == 2.0
                
                if (getappdata(0, 'analysisDialogues') > 0.0) && (getappdata(0, 'checkOverwrite') > 0.0)
                    response = questdlg(sprintf('The material ''%s'' already exists in the local database. Do you wish to overwrite the material?', materialName), 'Quick Fatigue Tool', 'Overwrite', 'Keep file', 'Abort', 'Overwrite');
                elseif getappdata(0, 'checkOverwrite') > 0.0
                    response = input(sprintf('The material ''%s'' already exists in the local database. Do you wish to overwrite the material? [<O>verwrite/<K>eep/<A>bort]: ', materialName), 's');
                    
                    if strcmpi(response, 'o') == 1.0
                        response = 'Overwrite';
                    elseif strcmpi(response, 'k') == 1.0
                        response = 'Keep';
                    elseif strcmpi(response, 'a') == 1.0
                        response = 'Abort';
                    else
                        response = 'Abort';
                    end
                else
                    response = 'Overwrite';
                end
                
                if (strcmpi(response, 'Abort') == 1.0) || (isempty(response) == 1.0)
                    fprintf('[NOTICE] Input file processing was aborted by the user\n');
                    return
                elseif strcmpi(response, 'Keep file') == 1.0
                    % Change the name of the new results output database
                    oldMaterial = materialName;
                    while exist([oldMaterial, '.mat'], 'file') == 2.0
                        oldMaterial = [oldMaterial , '-old']; %#ok<AGROW>
                    end
                    
                    % Rename the original material
                    movefile(['Data/material/local/', materialName, '.mat'], ['Data/material/local/', oldMaterial, '.mat'])
                end
            end
            
            % Save the material in the local database
            if error == 0.0
                try
                    save(['Data/material/local/', materialName], 'material_properties')
                catch
                    fprintf('ERROR: The material ''%s'' could not be saved to the local database. Make sure the material save location has read/write access\n', materialName);
                    return
                end
            end
            
            % Advance the file by nTLINE to get past the material definition
            for i = 1:nTLINE_material - 1.0
                TLINE = fgetl(fid);
            end
            TOKEN = strtok(TLINE, '=');
        end
        
        %%
        
        % Check if the current line is a comment
        if (length(TLINE) > 1.0) && (strcmp(TLINE(1.0:2.0), '**') == 1.0)
            continue
        end
        
        % Get the length of the token
        tokenLength = length(TOKEN);
        
        % Remove spaces and usolate the keyword
        TOKEN(ismember(TOKEN,' *')) = [];
        TOKEN = strtok(lower(TOKEN), ',');
        
        % Check if the keyword matches the library
        matchingKw = find(strncmpi({TOKEN}, kwStr, length(TOKEN)) == 1.0);
        
        if tokenLength == length(TLINE)
            %{
                There is no '=' sign in the keyword declaration or there is
                no data after the asterisk
            %}
            if tokenLength == 1.0
                emptyKeywords = emptyKeywords + 1.0;
            elseif strcmpi(TOKEN, 'endmaterial') == 0.0
                partialKw{index_pkw} = TOKEN;
                
                index_pkw = index_pkw + 1.0;
            end
            continue
        elseif length(matchingKw) > 1.0
            % The keyword definition is ambiguous
            ambiguousKw{index_akw} = TOKEN;
            
            index_akw = index_akw + 1.0;
            continue
        elseif isempty(matchingKw) == 1.0
            % The keyword could not be found in the library
            undefinedKw{index_ukw} = TOKEN;
            
            index_ukw = index_ukw + 1.0;
            continue
        elseif length(kwStr{matchingKw}) ~= length(TOKEN)
            % The keyword is unambiguous, but incomplete
            incompleteKw{index_ikw} = TOKEN;
            assumedKw{index_ikw} = kwStrSp{matchingKw};
            
            index_ikw = index_ikw + 1.0;
        end
    else
        continue
    end
    
    %% READ DATA FROM THE CURRENT KEYWORD
    for i = 2:length(TLINE)
        % If the parser reached the end of the line, discard the line
        if tokenLength + i > length(TLINE)
            badKw{index_bkw} = TOKEN;
            
            index_bkw = index_bkw + 1.0;
            break
        end
        
        % Get the current character from TLINE
        currentChar = TLINE(tokenLength + i);
        currentLine = TLINE(tokenLength + i:end);
        
        if strcmp(currentChar, ' ') == 1.0
            % Continue until a character is found
            continue
        end
        
        % If the current line ends with a semicolon, remove it
        if strcmp(currentLine(end), ';') == 1.0
            currentLine(end) = [];
        end
        
        % Count the keyword
        numberOfKeywords = numberOfKeywords + 1.0;
        processedKeywords{index_ckw} = kwStrSp{matchingKw};
        index_ckw = index_ckw + 1.0;
        
        if strcmpi(currentChar, sprintf('''')) == 1.0
            %{
                The keyword definition begins as an apostrophe. Treat the
                input as a string
            %}
            currentLine(ismember(currentLine, sprintf(''''))) = [];
            
            kwData{matchingKw} = currentLine;
            
            break
        elseif strcmpi(currentChar, '[') == 1.0
            % The keyword definition appears to be a numeric array
            if isnumeric(str2num(currentLine)) == 1.0 %#ok<ST2NM>
                kwData{matchingKw} = str2num(currentLine); %#ok<ST2NM>
                
                break
            end
        elseif (isnumeric(str2double(currentChar)) == 1.0 && isnan(str2double(currentChar)) == 0.0 && isreal(str2double(currentChar)) == 1.0) ||...
                (isnumeric(str2double(currentLine)) == 1.0 && isnan(str2double(currentLine)) == 0.0 && isreal(str2double(currentLine)) == 1.0)
            % The keyword definition appears to be a numeric value
            kwData{matchingKw} = str2double(currentLine);
            
            % If the value is NaN, evaluate it as a mathematical expression instead
            if isnan(kwData{matchingKw}) == 1.0
                kwData{matchingKw} = eval(currentLine);
            end
            
            break
        elseif strcmpi(currentChar, '{') == 1.0
            % The keyword definition appears to be a cell
            
            %{
                The cell is represented as a single character array from
                FGETL. In order to convert this array into a cell, use
                regular expressions to match metacharacters to the FGETL
                string
            %}
            C = keywords.interpretCell(currentLine, matchingKw);
            
            kwData{matchingKw} = C;
            
            break
        else
            %{
                The keyword definition does not start with a square or
                curly bracket or an apostrophe, and is not numeric by
                itself.
 
                If the definition evaluates to a numeric value, assume that
                the definition was entered as a mathematical expression
                using MATLAB built-in functions.
            
                Otherwise, the definition might be invalid, but it may also
                be intended as a string which isn't enclosed by apostrophes.
                In this case, assume that the definition is a string; QFT
                will throw an error or crash later if the definition is
                invalid
            %}
            
            %{
                Do not attempt to evaluate any expression that matches a
                file name on the MATLAB path
            %}
            if exist(currentLine, 'file') ~= 2.0
                try eval(currentLine)
                    kwData{matchingKw} = eval(currentLine);
                catch
                    kwData{matchingKw} = currentLine;
                end
            else
                kwData{matchingKw} = currentLine;
            end
            
            break
        end
    end
end

%% SAVE THE BUFFERS
setappdata(0, 'kw_partial', partialKw)
setappdata(0, 'kw_processed', processedKeywords)
setappdata(0, 'kw_undefined', undefinedKw)
setappdata(0, 'kw_bad', badKw)
setappdata(0, 'kw_ambiguous', ambiguousKw)

%% CHECK THE JOB NAME
if any(ismember(processedKeywords, 'JOB NAME')) == 0.0
    %{
        The job name was not defined in the input file, so use the file
        name instead
    %}
    kwData{42.0} = NAME;
end

%% CLOSE THE FILE AND SUBMIT THE JOB
% Close the input file
fclose(fid);

%% IF THERE WERE NO PROCESSED KEYWORDS, EXIT WITH AN ERROR
if length(processedKeywords) == 1.0 && isempty(processedKeywords{1.0}) == 1.0
    fprintf('ERROR: There are no keywords defined in the input file\n');
    return
end

% Submit the job for analysis
main(kwData)
end