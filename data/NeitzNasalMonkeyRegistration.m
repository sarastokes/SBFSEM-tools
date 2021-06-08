% NEITZNASALMONKEY XYREGISTRATION

saveFlag = false;
plotFlag = true;

[data, S] = xyRegistration('n', [1150 1180], plotFlag);
updateRegistration('n', data, saveFlag);

branchRegistration('n', [1139 1140], 'Save', saveFlag, 'View', plotFlag);

branchRegistration('n', [1236, 1237], 'Save', saveFlag, 'View', plotFlag);

branchRegistration('n', [1297 1298], 'Save', saveFlag, 'View', plotFlag);

branchRegistration('n', [1512 1513], 'Save', saveFlag, 'View', plotFlag);

% View file:
edit XY_OFFSET_NEITZNASALMONKEY.txt