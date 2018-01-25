% NEITZINFERIORMONKEY XYREGISTRATION
%
% The current setup for XY alignment does not support an update to 
% existing registration. So for now, to change the registration 

[~, S] = xyRegigistration('i', [1284 1305], viewMode);
updateRegistration('i', S);

branchRegistration('i', [914 936], viewMode, saveMode);
branchRegistration('i', [1121 1122], viewMode, saveMode);
