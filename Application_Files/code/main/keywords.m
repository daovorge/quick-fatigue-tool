classdef keywords < handle
%KEYWORDS    QFT class for material keyword processing.
%   This class contains methods for material keyword processing tasks.
%   
%   KEYWORDS is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%
%   See also importMaterial, fetchMaterial, job.
%   
%   Quick Fatigue Tool 6.11-07 Copyright Louis Vallance 2017
%   Last modified 19-Oct-2017 15:47:11 GMT
    
    %%
    
    methods(Static = true)
        %% INITIALIZE DEFAULT KEYWORDS
        function [kwStr, kwStrSp, kwData] = initialize()
            % KEYWORD STRINGS
            kwStr = {'ITEMS', 'UNITS', 'SCALE', 'REPEATS', 'USESN', 'DESIGNLIFE',...
                'ALGORITHM', 'MSCORRECTION', 'LOADEQ', 'PLANESTRESS', 'SNSCALE',...
                'OUTPUTFIELD', 'OUTPUTHISTORY', 'OUTPUTFIGURE', 'KTDEF',...
                'KTCURVE', 'RESIDUAL', 'WELDCLASS', 'DEVIATIONSBELOWMEAN',...
                'CHARACTERISTICLENGTH', 'SEAWATER', 'YIELDSTRENGTH', 'FAILUREMODE',...
                'UTS', 'CONV', 'OUTPUTDATABASE', 'PARTINSTANCE', 'OFFSET',...
                'STEPNAME', 'FACTOROFSTRENGTH', 'GROUP', 'HOTSPOT', 'SNKNOCKDOWN',...
                'EXPLICITFEA', 'RESULTPOSITION', 'CONTINUEFROM', 'DATACHECK',...
                'NOTCHCONSTANT', 'NOTCHRADIUS', 'GAUGELOCATION', 'GAUGEORIENTATION',...
                'JOBNAME', 'JOBDESCRIPTION', 'MATERIAL', 'DATASET', 'HISTORY',...
                'HFDATASET', 'HFHISTORY', 'HFTIME', 'HFSCALE',...
                'FATIGUERESERVEFACTOR', 'COMPOSITECRITERIA', 'YIELDCRITERIA'};
            
            kwStrSp = {'ITEMS', 'UNITS', 'SCALE', 'REPEATS', 'USE SN', 'DESIGN LIFE',...
                'ALGORITHM', 'MS CORRECTION', 'LOAD EQ', 'PLANE STRESS', 'SN SCALE',...
                'OUTPUT FIELD', 'OUTPUT HISTORY', 'OUTPUT FIGURE', 'KT DEF',...
                'KT CURVE', 'RESIDUAL', 'WELD CLASS', 'DEVIATIONS BELOW MEAN',...
                'CHARACTERISTIC LENGTH', 'SEA WATER', 'YIELD STRENGTH', 'FAILURE MODE',...
                'UTS', 'CONV', 'OUTPUT DATABASE', 'PART INSTANCE', 'OFFSET',...
                'STEP NAME', 'FACTOR OF STRENGTH', 'GROUP', 'HOTSPOT', 'SN KNOCKDOWN',...
                'EXPLICIT FEA', 'RESULT POSITION', 'CONTINUE FROM', 'DATA CHECK',...
                'NOTCH CONSTANT', 'NOTCH RADIUS', 'GAUGE LOCATION', 'GAUGE ORIENTATION',...
                'JOB NAME', 'JOB DESCRIPTION', 'MATERIAL', 'DATASET', 'HISTORY',...
                'HF DATASET', 'HF HISTORY', 'HF TIME', 'HF SCALE',...
                'FATIGUE RESERVE FACTOR', 'COMPOSITE CRITERIA', 'YIELD CRITERIA'};
            
            % KEYWORD DATA
            kwData = {'SURFACE', 3.0, 1.0, 1.0, 1.0, 'CAEL', 0.0, 0.0, {1.0, 'Repeats'},...
                0.0, 1.0, 0.0, 0.0, 0.0, 'default.kt', 1.0, 0.0, 'B', 0.0, [],...
                0.0, [], 'NORMAL', [], [], [], 'PART-1-1', [], [], 0.0, {'DEFAULT'}, 0.0,...
                {}, 0.0, 'ELEMENT NODAL', [], 0.0, [], [], {}, {}, 'Job-1',...
                'Template job file', [], '', [], [], [], {[], []}, [], 2.0, 0.0, 0.0};
        end
        
        %% INTERPRET CELL KEYWORD INPUT
        function [cell_buffer] = interpretCell(line, matchingKw)
            %{
                There are different ways in which the cell could be defined:
                
                {'string1', 'string2',..., 'stringn'}
                {[11, 12,..., 1n], [21, 22,..., 2n],..., [n1, n2,..., nn]]}
                {[n1, n2, n3], 'string'}
                {n1, 'string1', 'string2', n2, n3, 'string3'}
                {n1, n2}
            %}
            L = length(line);
            
            currentChar = 2.0;
            
            % Initialize the cell element buffer
            cell_buffer = cell(1.0, 1.0);
            
            % Initialize the buffer index
            index = 0.0;
            
            while currentChar < L
                % The cell is a string
                if strcmp(line(currentChar), sprintf('''')) == 1.0
                    % Get the string
                    TOKEN = strtok(line(currentChar:end), sprintf(''''));
                    
                    index = index + 1.0;
                    cell_buffer{index} = TOKEN;
                    
                    currentChar = currentChar + length(TOKEN) + 2.0;

                % The cell is an array
                elseif strcmp(line(currentChar), '[') == 1.0
                    % Get the string
                    TOKEN = strtok(line(currentChar + 1.0:end), sprintf(']'));
                    
                    index = index + 1.0;
                    cell_buffer{index} = sscanf(TOKEN, '%g,')';
                    
                    currentChar = currentChar + length(TOKEN) + 3.0;
                
                % The cell is a 1x1 numeric
                elseif isnumeric(str2double(line(currentChar))) == 1.0 && isnan(str2double(line(currentChar))) == 0.0 && isreal(str2double(line(currentChar))) == 1.0
                    %{
                        Get the string. Search up to the first occurrence
                        of a comma
                    %}
                    TOKEN = strtok(line(currentChar:end), sprintf(','));
                    
                    if currentChar + length(TOKEN) >= L
                        TOKEN = strtok(line(currentChar:end), sprintf('}'));
                    end
                    
                    index = index + 1.0;
                    if matchingKw == 43.0
                        %{
                            Exception: If the current keyword is *GAUGE
                            LOCATION, accept a lone numeric input and
                            convert it to CHAR
                        %}
                        cell_buffer{index} = char(TOKEN);
                    else
                        cell_buffer{index} = str2double(TOKEN);
                    end
                    
                    currentChar = currentChar + length(TOKEN) + 1.0;
                    
                % The cell is a string without enclosing apostrophes
                elseif isnan(str2double(line(currentChar))) == 1.0 && isspace(line(currentChar)) == 0.0 && strcmp(line(currentChar), ',') == 0.0
                    %{
                        Get the string. Search up to the first occurrence
                        of a comma
                    %}
                    TOKEN = strtok(line(currentChar:end), sprintf(','));
                    
                    if currentChar + length(TOKEN) >= L
                        TOKEN = strtok(line(currentChar:end), sprintf('}'));
                    end
                    
                    index = index + 1.0;
                    cell_buffer{index} = TOKEN;
                    
                    currentChar = currentChar + length(TOKEN) + 1.0;
                else
                    currentChar = currentChar + 1.0;
                end
            end
        end
        
        %% PRINT INPUT FILE READER SUMMARY TO MESSAGE FILE
        function [error] = printSummary()
            % Initialize the error flag
            error = 0.0;
            
            if isappdata(0, 'jobFromTextFile') == 0.0
                return
            else
                rmappdata(0, 'jobFromTextFile')
            end
            
            if isappdata(0, 'kw_processed') == 0.0
                return
            else
                fid = getappdata(0, 'messageFID');
                kw_processed = getappdata(0,'kw_processed');
                
                if isempty(fid) == 1.0
                    setappdata(0, 'E143', 1.0)
                    error = 1.0;
                    return
                end
            end
            
            fprintf(fid, '\r\n***INPUT FILE SUMMARY');
            
            % Processed keywords
            fprintf(fid, '\r\n\tThe following keywords were processed:');
            
            for i = 1:length(kw_processed)
                fprintf(fid, '\r\n\t*%s', kw_processed{i});
            end

            % Get problematic keywords
            kw_bad = getappdata(0, 'kw_bad');
            kw_undefined = getappdata(0, 'kw_undefined');
            kw_partial = getappdata(0, 'kw_partial');
            kw_ambiguous = getappdata(0, 'kw_ambiguous');

            if (isempty(kw_bad{1.0}) == 0.0) || (isempty(kw_undefined{1.0}) == 0.0) || (isempty(kw_partial{1.0}) == 0.0) || (isempty(kw_ambiguous{1.0}) == 0.0)
                fprintf(fid, '\r\n\r\n\tWarning: One or more keywords were not processed');
            else
                fprintf(fid, '\r\n\r\n\tThe input file processor completed successfully');
            end
            
            % Badly defined keywords
            if isempty(kw_bad{1.0}) == 0.0
                fprintf(fid, '\r\n\tThe following keywords contain syntax errors:');
                
                for i = 1:length(kw_bad)
                    fprintf(fid, '\r\n\t*%s', kw_bad{i});
                end
            end
            
            % Undefined keywords
            if isempty(kw_undefined{1.0}) == 0.0
                fprintf(fid, '\r\n\tThe following keywords were not recognised:');
                
                for i = 1:length(kw_undefined)
                    fprintf(fid, '\r\n\t*%s', kw_undefined{i});
                end
            end
            
            % Partial keywords
            if isempty(kw_partial{1.0}) == 0.0
                fprintf(fid, '\r\n\tThe following keywords were declared but not defined:');
                
                for i = 1:length(kw_partial)
                    fprintf(fid, '\r\n\t%s', kw_partial{i});
                end
            end
            
            % Ambiguous keywords
            if isempty(kw_ambiguous{1.0}) == 0.0
                fprintf(fid, '\r\n\tThe following keywords are ambiguous:');
                
                for i = 1:length(kw_ambiguous)
                    fprintf(fid, '\r\n\t*%s', kw_ambiguous{i});
                end
            end

            fprintf(fid, '\r\n');
        end
    end
end