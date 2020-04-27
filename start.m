
clc, clear all, close all

numNodes = 100; % number of nodes
p = 0.1;

netArch  = newNetwork(100, 100, 50, 175); %Length, Width, sinkX, sinkY, initEnergy..., transEnergy, recEnergy, fsEnergy, mpEnergy, aggrEnergy
nodeArch = newNodes(netArch, numNodes); %netArch, numNode
roundArch = newRound(10);

plot1
netArch2  = netArch;
nodeArch2 = nodeArch;
roundArch2 = roundArch;

netArch3  = netArch;
nodeArch3 = nodeArch;
roundArch3 = roundArch;

par = struct;
par2=struct;
par3=struct;

%%%%%%multitype은 'dissEnergyNonCHbynoT', notype, leach는 'dissEnergyNonCH'
tic
for r = 1:roundArch.numRound
    
    clusterModel = newCluster(netArch, nodeArch, 'leach', r, p);
    clusterModel = dissEnergyCH(clusterModel, roundArch);
    clusterModel = group_period(clusterModel, 'notype'); %센싱 주기 결정
    %clusterModel = dissEnergyNonCHbynoT(clusterModel, roundArch);   
    clusterModel = dissEnergyNonCH(clusterModel, roundArch);
    nodeArch     = clusterModel.nodeArch; % new node architecture after select CHs
    
    par = plotResults(clusterModel, r, par);
    if nodeArch.numDead == nodeArch.numNode
        break
    end
end
a=char.empty();
createfigure(1:roundArch.numRound, par.energy, par.packetToBS, par.numDead,a,a,a,a,a,a);

for r = 1:roundArch2.numRound
   
    clusterModel2 = newCluster(netArch2, nodeArch2, 'leach', r, p);
    clusterModel2 = dissEnergyCH(clusterModel2, roundArch2);
    clusterModel2 = group_period(clusterModel2, 'multitype'); %센싱 주기 결정
    clusterModel2 = dissEnergyNonCHbynoT(clusterModel2, roundArch2);   
    %clusterModel2 = dissEnergyNonCH(clusterModel2, roundArch2);
    nodeArch2     = clusterModel2.nodeArch; % new node architecture after select CHs
    
    par2 = plotResults(clusterModel2, r, par2);
   
    if nodeArch2.numDead == nodeArch2.numNode
        break
    end
end

createfigure(1:roundArch.numRound, par.energy, par.packetToBS, par.numDead, par2.energy, par2.packetToBS, par2.numDead,a,a,a);

for r = 1:roundArch3.numRound
   
    clusterModel3 = newCluster(netArch3, nodeArch3, 'leach', r, p);
    clusterModel3 = dissEnergyCH(clusterModel3, roundArch3);
    clusterModel3 = group_period(clusterModel3, 'leach'); %센싱 주기 결정
    %clusterModel = dissEnergyNonCHbynoT(clusterModel, roundArch);   
    clusterModel3 = dissEnergyNonCH(clusterModel3, roundArch3);
    nodeArch3     = clusterModel3.nodeArch; % new node architecture after select CHs
    
    par3 = plotResults(clusterModel3, r, par2);
   
    if nodeArch3.numDead == nodeArch3.numNode
        break
    end
end

createfigure(1:roundArch.numRound, par.energy, par.packetToBS, par.numDead, par2.energy, par2.packetToBS, par2.numDead,par3.energy, par3.packetToBS, par3.numDead);
toc
