% NEITZINFERIORMONKEY XYREGISTRATION
%
% The current setup for XY alignment does not support an update to 
% existing registration. So for now, to change the registration 

viewMode = true;
saveMode = false;

[~, S] = xyRegigistration('i', [1284 1305], viewMode);
updateRegistration('i', S);

branchRegistration('i', [914 936], viewMode, saveMode);
branchRegistration('i', [1121 1122], viewMode, saveMode);
branchRegistration('i', [1454 1455], viewMode, saveMode);
branchRegistration('i', [1553 1554], viewMode, saveMode);
branchRegistration('i', [1517 1518], viewMode, saveMode);
branchRegistration('i', [1613 1614], viewMode, saveMode);