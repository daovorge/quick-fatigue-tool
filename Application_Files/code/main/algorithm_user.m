classdef algorithm_user < handle
%ALGORITHM_USER    QFT class for user-defined algorithm.
%   This class contains methods for a user-defined fatigue analysis
%   algorithm.
%
%   Variables to be defined:
%   DPARAMI
%      Maximum damage parameter at the current analysis item. DPARAMI is a
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
%      Cycle pairs for the loading at the current analysis item. PAIRI is a
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
%      Stress tensor history in the normal Cartesian 1-direction for
%      analysis item N.
%
%   S22
%      Stress tensor history in the normal Cartesian 2-direction for
%      analysis item N.
%
%   S33
%      Stress tensor history in the normal Cartesian 3-direction for
%      analysis item N.
%
%   S12
%      Stress tensor history in the shear Cartesian 12-direction for
%      analysis item N.
%
%   S23
%      Stress tensor history in the shear Cartesian 23-direction for
%      analysis item N.
%
%   S13
%      Stress tensor history in the shear Cartesian 13-direction for
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
%   See also algorithm_bs7608, algorithm_findley, algorithm_nasa,
%   algorithm_ns, algorithm_sbbm, algorithm_sip, algorithm_uel,
%   algorithm_usl.
%   
%   Reference section in Quick Fatigue Tool User Guide
%      6.10 User-defined algorithms
%   
%   Quick Fatigue Tool 6.11-12 Copyright Louis Vallance 2018
%   Last modified 24-Nov-2017 09:30:36 GMT
    
    %%
        
    methods(Static = true)
        %% ENTRY FUNCTION
        function [DPARAMI, AMPI, PAIRI, DAMI] = main(varargin)
            %{
                This function is written by the user. The variables
                DPARAMI, AMPI, PAIRI and DAMI must be defined.
            
                Various Quick Fatigue Tool utilities such as rainflow cycle
                counting and mean stress correction can be called from this
                function. Consult Section 6.9 of the Quick Fatigue Tool
                User Guide for more details.
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
            
            % Get stress tensor components
            S11 = varargin{1.0};
            
            % DEFINE OUTPUT (DUMMY VALUES)
            N = varargin{7.0};
            DPARAMI = 400.0;
            AMPI{N} = 200.0;
            PAIRI{N} = [400.0, -400.0];
            DAMI(N) = 1e-6;
            
            %{
                Additional APPDATA variables for history output. It is not
                compulsory to define these variables, but they will be
                required if the user specifies field or history output.
            %}
            setappdata(0, 'CS', zeros(1.0, length(S11)))
            setappdata(0, 'CN', zeros(1.0, length(S11)))
            setappdata(0, 'cyclesOnCP', PAIRI{N})
            setappdata(0, 'amplitudesOnCP', AMPI{N})
        end
    end
end