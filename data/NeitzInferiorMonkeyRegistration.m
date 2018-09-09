% NEITZINFERIORMONKEY XYREGISTRATION
%
% The current setup for XY alignment does not support an update to 
% existing registration. So for now, to change the registration 

viewMode = true;
saveMode = false;

[~, S] = xyRegigistration('i', [1284 1305], viewMode);
updateRegistration('i', S, saveMode);

branchRegistration('i', [914 936], 'Save', saveMode, 'View', viewMode);
branchRegistration('i', [1121 1122], 'Save', saveMode, 'View', viewMode);
branchRegistration('i', [1454 1455], 'Save', saveMode, 'View', viewMode);
branchRegistration('i', [1553 1554], 'Save', saveMode, 'View', viewMode);
branchRegistration('i', [1517 1518], 'Save', saveMode, 'View', viewMode);
branchRegistration('i', [1613 1614], 'Save', saveMode, 'View', viewMode);

% 7Sept2018
% branchRegistration('i', [420 421],...
%     'Save', saveMode, 'View', viewMode, 'ShiftVitread', true);
% branchRegistration('i', [421 422],...
%     'Save', saveMode, 'View', viewMode, 'ShiftVitread', true);