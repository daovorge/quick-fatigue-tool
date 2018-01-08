function [reported, x] = status(fid_status, analysedNodes, node, N2, nodalDamage, mainID, subID,...
        reported, x0, x, tic_pre)
%status    QFT function for status file.
%   This function contains code to write information to the status (.sta)
%   file.
%   
%   status is used internally by Quick Fatigue Tool. The user is not
%   required to run this file.
%   
%   Quick Fatigue Tool 6.11-10 Copyright Louis Vallance 2017
%   Last modified 13-Sep-2017 16:10:56 GMT
    
    %%
    
    %% REPORT PROGRESS
    currentTime = toc(tic_pre);
    if ((analysedNodes == 1.0) || (analysedNodes == N2)) || ((currentTime - x > 0.0) && (reported == 0.0))
        hrs = floor(currentTime/3600);
        mins = floor((currentTime - (3600*hrs))/60);
        secs = currentTime - (hrs*3600) - (mins*60);
        
        percent = round(100*(analysedNodes/N2));
        
        progress = sprintf('%.0f%%', percent);
        life = sprintf('%9.3e', (1.0/nodalDamage(node)));
        item = sprintf('%.0f.%.0f', mainID(node), subID(node));
        increment = sprintf('%.0f/%.0f', analysedNodes, N2);
        if mins < 10.0
            if secs < 10.0
                time = sprintf('%.0f:0%.0f:0%.3f', hrs, mins, secs);
            else
                time = sprintf('%.0f:0%.0f:%.3f', hrs, mins, secs);
            end
        elseif secs < 10.0
            time = sprintf('%.0f:%.0f:0%.3f', hrs, mins, secs);
        else
            time = sprintf('%.0f:%.0f:%.3f', hrs, mins, secs);
        end
        
        fprintf(fid_status, '%-12s%-13s%-16s%+16s%+16s\r\n',...
            progress, life, item, increment, time);
        
        if (currentTime - x > 0.0) && (reported == 0.0)
            reported = 1.0;
            x = x + x0;
        end
    else
        reported = 0.0;
    end
end