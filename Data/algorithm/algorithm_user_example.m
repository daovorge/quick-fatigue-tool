classdef algorithm_user_example < handle
%ALGORITHM_USER    QFT class for user-defined algorithm.
%   This class contains methods for a user-defined fatigue analysis
%   algorithm.
%
%   Variables to be defined:
%   DPARAMI
%      Maximum damage parameter for the current analysis item. DPARAMI is a
%      1xL numeric array where L is the number of analysis items. DPARAMI
%      is defined as follows:
%
%      DPARAMI(N) = X;
%
%      X is the maximum damage parameter for the analysis item N.
%
%   AMPI
%      Stress amplitude of each cycle for the loading at the current
%      analysis item. AMPI is a 1xL cell array where L is the number of
%      analysis items. AMPI is defined as follows:
%
%      AMPI{N} = [A1, A2,..., AN];
%
%      A1 to An are the amplitudes over the load history for the analysis
%      item N.
%
%   PAIRI
%      Cycle pairs for the loading at the current analyis item. PAIRI is a
%      Cx2 cell array where C is the number of cycles in the load history.
%      PAIRI is defined as follows:
%
%      PAIRI{N} = [Pmin_1, Pmax_1; Pmin_2, Pmax_2;...; Pmin_C, Pmax_C];
%
%      Pmin and Pmax are the minimum and maximum values for each cycle pair
%      in the loading, up to the number of cycles C, for the analysis item
%      N.
%
%   DAMI
%      Total damage for the loading at the current analysis item. DAMI is a
%      1xL numeric array where L is the number of analysis items. DAMI is
%      defined as follows:
%
%      DAMI(N) = D;
%
%      D is the total damage over the load history for the analysis item N.
%
%   Variables passed in for information:
%   S11
%      Stress tensor history in the normal Certesian 1-direction for
%      analysis item N.
%
%   S22
%      Stress tensor history in the normal Certesian 2-direction for
%      analysis item N.
%
%   S33
%      Stress tensor history in the normal Certesian 3-direction for
%      analysis item N.
%
%   S12
%      Stress tensor history in the shear Certesian 12-direction for
%      analysis item N.
%
%   S23
%      Stress tensor history in the shear Certesian 23-direction for
%      analysis item N.
%
%   S13
%      Stress tensor history in the shear Certesian 13-direction for
%      analysis item N.
%
%   N
%      Current analysis item number.
%
%   MSC
%      Identifier defining the selected mean stress correction
%   
%   ALGORITHM_USER is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%   
%   Reference section in Quick Fatigue Tool User Guide
%      6.9 User-defined
%   
%   Quick Fatigue Tool 6.10-09 Copyright Louis Vallance 2017
%   Last modified 24-Nov-2017 09:30:36 GMT
    
    %%
        
    methods(Static = true)
        %% ENTRY FUNCTION
        function [DPARAMI, AMPI, PAIRI, DAMI] = main(varargin)
            %{
                The code below is an example of a user-defined analysis
                algorithm. The code is for illustrative purposes to show
                typical usage of the input and output variables and does
                not represent a realisitc or usable damage criterion.
            %}
            
            % FUNCTION ARGUMENTS (VARARGIN)
            %{
                1: S11
                2: S22
                3: S33
                4: S12
                5: S23
                6: S13
                7: N
                8: MSC
            %}
            
            % STEP 1: Get material properties for the current analysis item
            %{
                Material properties are called using the method GETAPPDATA.
                An index of material properties and their respective
                identifiers is provided in Section 6.9 of the Quick Fatigue
                Tool User Guide.
            %}
            Sf = getappdata(0, 'Sf');   % Fatigue strength coefficient
            b = getappdata(0, 'b');   % Fatigue strength exponent
            
            % STEP 2a: Define an effective stress history from the first
            % principal stress
            %{
                Use the stress components to calculate the maximum damage
                parameter, DPARAMI, for the current analysis item.
            %}
            % e.g. Principal stress
            history = getappdata(0, 'S1');
            damageParameter = max(history);
            
            % STEP 2b: Define a uniaxial stress history from the stress
            % components
            %{
                Use the stress components to calculate the maximum damage
                parameter, DPARAMI, for the current analysis item.
            %}
            % e.g. S11
            %history = varargin{1.0};
            %damageParameter = max(history);
            
            % STEP 3: Rainflow cycle count the stress history
            if length(history) > 2.0
                rfData = analysis.rainFlow(history);
                pairs = rfData(:, 1:2);
                amplitudes = analysis.getAmps(pairs);
            else
                pairs = [min(history), max(history)];
                amplitudes = 0.5*(max(history) - min(history));
            end
            
            % STEP 4: Perform mean stress correction
            [amplitudes, ~, ~] = analysis.msc(amplitudes, pairs, MSC);
            
            % STEP 5: Auxilliary tasks
            %{
                At any point during the analysis, the user may perform
                their own processing on the loading (critical plane
                searching, damage calculations, etc.). These function can
                be defined inside ALGORITHM_USRE and valled from MAIN.
            %}
            % Dummy auxilliary function call
            % [OUT_1, OUT_2,..., OUT_N] = algorithm_user.auxilliaryFunction(IN_1, IN_2,..., IN_N);
            
            % STEP 6: Define output variables
            % DPARAMI
            DPARAMI(N) = damageParameter;
            
            % DAMI
            DAMI(N) = (0.5*((damageParameter/Sf).^(1.0/b)))^-1.0;
            
            % AMPI and PAIRI
            AMPI{N} = amplitudes;
            PAIRI{N} = pairs;
            
            %{
                Additional APPDATA variables for history output. It is not
                compulsory to define these variables, but they will be
                required if the user specifies field or history output.
            %}
            setappdata(0, 'CS', zeros(1.0, length(history)))
            setappdata(0, 'CN', zeros(1.0, length(history)))
            setappdata(0, 'cyclesOnCP', PAIRI{N})
            setappdata(0, 'amplitudesOnCP', amplitudes)
        end
    end
end