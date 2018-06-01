function T = recursionSWC(G, T, baseNode)
    % RECURSIONSWC
    %
    % Description:
    %   Designed to be called recursively to assign SWC type and parents
    %
    % Inputs:
    %   G           Digraph representation of neuron
    %   T           Table
    %   baseNode    Node to label and identify children
    %
    % Outputs:
    %   T           Table
    %
    % History:
    %   13May2018 - SSP
    % ---------------------------------------------------------------------
    
    childNodes = G.successors(baseNode);
    if numel(childNodes) == 0
        fprintf('No child nodes found for node %u\n', baseNode);
        return
    end
    
    for i = 1:numel(childNodes)
        iNode = childNodes(i);
        T(iNode, :).Parent = baseNode;
        switch numel(G.successors(iNode))
            case 0 % endpoint
                T(iNode, :).SWC = 6;
            case 1 % dendrite
                T(iNode, :).SWC = 3;
                T = recursionSWC(G, T, iNode);
            otherwise % fork point
                T(iNode, :).SWC = 5;
                T = recursionSWC(G, T, iNode);
        end
    end
