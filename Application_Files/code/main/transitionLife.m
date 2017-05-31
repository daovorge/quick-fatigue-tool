function [] = transitionLife(worstGroup)
% Get the group ID buffer
groupIDBuffer = getappdata(0, 'groupIDBuffer');

% Get the material properties for the worst life group
[~, ~] = group.switchProperties(worstGroup, groupIDBuffer);

Sf = getappdata(0, 'Sf');
b = getappdata(0, 'b');
Ef = getappdata(0, 'Ef');
c = getappdata(0, 'c');
E = getappdata(0, 'E');

if (isempty(Sf) == 0.0) && (isempty(b) == 0.0) && (isempty(Ef) == 0.0) && (isempty(c) == 0.0) && (isempty(E) == 0.0)
    tLife = 0.5*((Ef*E)/(Sf))^(1.0/(b - c));
    
    % Save the transition life
    setappdata(0, 'transitionLife', tLife)
    
    % Save the transiton life ratio
    setappdata(0, 'transitionLifeRatio', groupIDBuffer(worstGroup).worstLife/tLife)
    
    % Report the ratio in the message file
    messenger.writeMessage(258.0)
else
    return
end
end