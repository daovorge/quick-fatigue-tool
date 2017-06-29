function setInitialHelp(hEditbox,helpText)
%SETINITIALHELP adds a help text to edit boxes that disappears when the box is clicked
%
% SYNOPSIS: setInitialHelp(hEditbox,helpText)
%
% INPUT hEditbox: handle to edit box. The parent figure cannot be docked, the edit box cannot be part of a panel.
%       helpText: string that should initially appear as help. Optional. If empty, current string is considered the help.
%
% SEE ALSO uicontrol, findjobj
%
% EXAMPLE
%           fh = figure;
%           % define uicontrol. Set foregroundColor, fontAngle, before
%           % calling setInitialHelp
%           hEditbox = uicontrol('style','edit','parent',fh,...
%             'units','normalized','position',[0.3 0.45 0.4 0.15],...
%             'foregroundColor','r');
%           setInitialHelp(hEditbox,'click here to edit')
%

% check input
if nargin < 1 || ~ishandle(hEditbox) || ~strcmp(get(hEditbox,'style'),'edit')
    error('please supply a valid edit box handle to setInitialHelp')
end

if nargin < 2 || isempty(helpText)
    helpText = get(hEditbox,'string');
end

% try to get java handle
jEditbox = findjobj(hEditbox,'nomenu');
if isempty(jEditbox)
    error('unable to find java handle. Figure may be docked or edit box may part of panel')
end

% get current settings for everything we'll change
% color = get(hEditbox,'foregroundColor');
color = 'black';
fontAngle = 'normal';
% fontAngle = get(hEditbox,'fontangle');

% define new settings (can be made optional input in the future)
newColor = [0.5 0.5 0.5];
newAngle = 'italic';

% set the help text in the new style
set(hEditbox,'string',helpText,'foregroundColor',newColor,'fontAngle',newAngle)

% add the mouse-click callback
set(jEditbox,'MouseClickedCallback',@(u,v)clearBox());

% define the callback "clearBox" as nested function for convenience
    function clearBox
        %CLEARBOX clears the current edit box if it contains help text
        
        currentText = get(hEditbox,'string');
        currentColor = get(hEditbox,'foregroundColor');
        
        if strcmp(currentText,helpText) && all(currentColor == newColor)
            % delete text, reset color/angle
            set(hEditbox,'string','','foregroundColor',color,'fontAngle',fontAngle)
        else
            % this is not help text anymore - don't do anything
        end
        
    end % nested function

end % main fcn