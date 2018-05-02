classdef algorithm_bm < handle
%ALGORITHM_BM    QFT class for Stress-based Brown-Miller algorithm.
%   This class contains methods for the Stress-based Brown-Miller fatigue
%   analysis algorithm.
%   
%   ALGORITHM_BM is used internally by Quick Fatigue Tool. The user is
%   not required to run this file.
%   
%   See also algorithm_bs7608, algorithm_findley, algorithm_nasa,
%   algorithm_ns, algorithm_sip, algorithm_uel, algorithm_usl,
%   algorithm_user.
%   
%   Reference section in Quick Fatigue Tool User Guide
%      6.2 Brown-Miller
%   
%   Quick Fatigue Tool 6.12-00 Copyright Louis Vallance 2018
%   Last modified 02-May-2018 14:40:50 GMT
    
    %%
    
    methods(Static = true)
        %% ENTRY FUNCTION
        function [] = main()
            
            %{
                1: Convert stress tensor history into principal stress
                history
            %}
            
            %{
                2: Convert elastic principal stress history to
                elasto-plastic principal stress history
            %}
            
            %{
                3: Perform critical plane search on elasto-plastic
                principal stress history to get the normal/shear
                stress/strain on the critical plane
            %}
            
            %{
                4: Rainflow count the stress/strain to get the normal/shear
                stress/strain cycles
            %}
            
            %{
                5: Perform mean stress correction and damage calculation on
                the rainflow counted parameters
            %}
        end
        
        %% CRITICAL PLANE SEARCH ALGORITHM
        function [] = criticalPlaneAnalysis()
        end
        
        %% CYCLE COUNT IF NO CP
        function [] = reducedAnalysis()
        end
        
        %% DAMAGE CALCULATION
        function [] = damageCalculation()
        end
        
        %% POST ANALYSIS AT WORST ITEM
        function [] = worstItemAnalysis()
        end
    end
end