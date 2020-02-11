classdef ScaleBar2 < handle
    % SCALEBAR2
    %
    % Description:
    %   A 2D scale bar with user interface
    %
    % Constructor:
    %   obj = ScaleBar2(parentHandle);
    %
    % Input:
    %   parentHandle        axis target for scale bar
    %
    % History:
    %   3Feb2020 - SSP
    % -------------------------------------------------------------------------

    properties (SetAccess = private)
        parentHandle
        lineHandle
    end

    methods
        function obj = ScaleBar2(ax)
            
            obj.parentHandle = ax;
            pts = obj.getPtsUI();
            obj.lineHandle = plot3(pts(:,1), pts(:, 2), pts(:, 3),...
                'Parent', obj.parentHandle,...
                'Color', 'k', 'LineWidth', 1.5);
        end

        function delete(obj)
            delete(obj.lineHandle);
        end
    end

    methods (Access = private)
        function pts = getPtsUI(obj)
            pts = [];
            opt = {'XY', 'XZ', 'YZ'};
            [ind, tf] = listdlg(...
                'PromptString', 'Select dimensions:',...
                'SelectionMode', 'single',...
                'ListString', opt);
            if ~tf
                return;
            end
            dim = opt{ind};
            S = inputdlg(...
                {[dim(1), 'Min'], [dim(1), 'Max'], [dim(2), 'Min'], [dim(2), 'Max']},...
                'Set Scalebar coordinates',...
                [1 20; 1 20; 1 20; 1 20]);
            
            if isempty(S)
                return;
            end
            
            try
                S = cellfun(@str2double, S);
            catch
                errordlg('Invalid Input!');
                return;
            end

            switch dim
                case 'XY'
                    pts = [S(1), S(3), mean(zlim(obj.parentHandle));...
                        S(2), S(4), mean(zlim(obj.parentHandle))];
                case 'XZ'
                    pts = [S(1), mean(ylim(obj.parentHandle)), S(3); ...
                        S(2), mean(ylim(obj.parentHandle)), S(4)];
                case 'YZ'
                    pts = [mean(xlim(obj.parentHandle), S(1), S(3)); ...
                           mean(xlim(obj.parentHandle)), S(2), S(4)];
            end
            disp(pts)
        end
    end
end