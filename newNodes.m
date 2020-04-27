function nodeArch = newNodes(netArch, numNode)
% Create the node model randomly
%   
%   Input:
%       netArch     Network architecture
%       numNode    Number of Nodes in the field
%   Output:
%       nodeArch    Nodes architecture
%       nodesLoc    Location of Nodes in the field
%   Example:
%       netArch  = createNetwork();
%       nodeArch = createNodes(netArch, 100)
%
    
    if ~exist('netArch','var')
        netArch = newNetwork();
    end
    
    if ~exist('numNode','var')
        numNode = 100;
    end
    for i = 1:numNode
        % x coordination of node
        nodeArch.node(i).x      =   rand * netArch.Yard.Length;
        nodeArch.nodesLoc(i, 1) =   nodeArch.node(i).x;
        % y coordination of node
        nodeArch.node(i).y      =   rand * netArch.Yard.Width;
        nodeArch.nodesLoc(i, 2) =   nodeArch.node(i).y;
        % the flag which determines the value of the indicator function? Ci(t)
        nodeArch.node(i).G      =   0; 
        % initially there are no cluster heads, only nodes
        nodeArch.node(i).type   =   'N'; % 'N' = node (nun-CH)
        nodeArch.node(i).energy =   netArch.Energy.init;
        nodeArch.node(i).countS=1;
        
        nodeArch.node(i).CH     = -1; % number of its CH ?
        nodeArch.dead(i)        = 0; % the node is alive

        %T:온도, H:습도, G:가스
        % 1 ~ 2 사이에 1개의 정수형 난수를 생성
        t=0,g=0,h=0;
        while (t+g+h) ==0
            t=randi([0,1],1,1);
            g=randi([0,1],1,1);
            h=randi([0,1],1,1);
        end
       
        nodeArch.Category(i).T  = t;
        nodeArch.Category(i).H  = g;
        nodeArch.Category(i).G  = h;
        %nodeArch.Category(i).type = t;
    end
    nodeArch.numNode = numNode; % Number of Nodes in the field
    nodeArch.numDead = 0; % number of dead nodes
end