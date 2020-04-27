function clusterModel = dissEnergyNonCHbynoT(clusterModel, roundArch)
% Calculation of Energy dissipated for CHs
%   Input:
%       clusterModel     architecture of nodes, network
%       roundArch        round Architecture
%   Example:
%       r = 10; % round no = 10
%       clusterModel = newCluster(netArch, nodeArch, 'def', r);
%       clusterModel = dissEnergyCH(clusterModel);
%
% Mohammad Hossein Homaei, Homaei@wsnlab.org & Homaei@wsnlab.ir
% Ver 1. 10/2014

nodeArch = clusterModel.nodeArch;
netArch  = clusterModel.netArch;
cluster  = clusterModel.clusterNode;
if cluster.countCHs == 0
    return
end
d0 = sqrt(netArch.Energy.freeSpace / ...
    netArch.Energy.multiPath);
ETX = netArch.Energy.transfer;
ERX = netArch.Energy.receive;
EDA = netArch.Energy.aggr;
Emp = netArch.Energy.multiPath;
Efs = netArch.Energy.freeSpace;
packetLength = roundArch.packetLength;
ctrPacketLength = roundArch.ctrPacketLength;

locAlive = find(~nodeArch.dead); % find the nodes that are alive

for i = locAlive % search in alive nodes
    %find Associated CH for each normal node
    if strcmp(nodeArch.node(i).type, 'N') &&  ...
            nodeArch.node(i).energy > 0 
        
        minloc=nodeArch.node(i).minloc;
        minDis = nodeArch.node(i).minDis; %클러스터 헤드의 번호 저장
        minDisCH = nodeArch.node(i).minDisCH;
        
        k = nodeArch.node(i).countS;
        
        %T가 있는 그룹(t=1)은 cluster.cycle(minloc,2) 에 저장되어있으므로
        t=nodeArch.Category(i).T;
        t=t+1;
        c = cluster.cycle(minloc,t);
        
        %%%%% 감소해야할 양 / 주기 * 센싱횟수
        if (minDis > d0)
            nodeArch.node(i).energy = nodeArch.node(i).energy - ...
                ctrPacketLength * ETX + Emp * packetLength * (minDis ^ 4)/c*k;
        else
            nodeArch.node(i).energy = nodeArch.node(i).energy - ...
                ctrPacketLength * ETX + Efs * packetLength * (minDis ^ 2)/c*k;
        end
        
        %Energy dissipated
        if(minDis > 0)
            nodeArch.node(minDisCH).energy = nodeArch.node(minDisCH).energy - ...
                ((ERX + EDA) * packetLength )/c*k;
        end
    end % if
end % for
clusterModel.nodeArch = nodeArch;
end