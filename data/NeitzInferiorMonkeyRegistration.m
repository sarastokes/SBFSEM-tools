% NEITZINFERIORMONKEY XYREGISTRATION
%
% The current setup for XY alignment does not support an update to 
% existing registration. So for now, to change the registration 

viewMode = true;
saveMode = false;
overwriteMode = false;

[~, S] = xyRegigistration('i', [1284 1305], viewMode);
updateRegistration('i', S, overwriteMode);

branchRegistration('i', [914 936], saveMode, viewMode);
branchRegistration('i', [1121 1122], saveMode, viewMode);
branchRegistration('i', [1454 1455], saveMode, viewMode);
branchRegistration('i', [1553 1554], saveMode, viewMode);
branchRegistration('i', [1517 1518], saveMode, viewMode);
branchRegistration('i', [1613 1614], saveMode, viewMode);