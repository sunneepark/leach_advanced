function clusterModel = group_period(clusterModel, clusterFun)
%센싱 주기 결정해서 센싱할 주기 결정
%   자세한 설명
nodeArch = clusterModel.nodeArch;
cluster  = clusterModel.clusterNode;
if cluster.countCHs == 0
    return
end

locAlive = find(~nodeArch.dead); % find the nodes that are alive

for i = locAlive % search in alive nodes 가까운 것들끼리 묶음
    %find Associated CH for each normal node
    if strcmp(nodeArch.node(i).type, 'N') &&  ...
            nodeArch.node(i).energy > 0
        
        locNode = [nodeArch.node(i).x, nodeArch.node(i).y];
        countCH = length(clusterModel.clusterNode.no); % Number of CHs
        
        % calculate distance to each CH and find smallest distance
        [minDis, loc] = min(sqrt(sum((repmat(locNode, countCH, 1) - cluster.loc)' .^ 2))); %cluster.loc ; 헤드노드의 위치
        
        nodeArch.node(i).minloc=loc;
        
        %CH 의 NCH에 현재 노드 정보 저장
        count=cluster.countNCH(loc);
        cluster.countNCH(loc)=count+1;
        cluster.energy(loc,cluster.countNCH(loc))=nodeArch.node(i).energy;
        cluster.noNCHs(loc,cluster.countNCH(loc))=i;
        
        nodeArch.node(i).minDisCH =  cluster.no(loc); %클러스터 헤드의 번호 저장
        nodeArch.node(i).minDis =  minDis; %클러스터 헤드와의 거리 저장
        
        %만약, T가 있다면 1그룹
        if nodeArch.Category(i).T == 1
            cluster.NONT(loc,cluster.countNCH(loc))=1;
        else
            cluster.NONT(loc,cluster.countNCH(loc))=0;
        end
    end % if
end % for


cycle=1; %공통 센싱 주기 default =1
if strcmp(clusterFun,'leach') %leach 알고리즘 일때
    %n = length(cluster.no); % Number of CHs
    l=find(cluster.countNCH);
    for i = l
        cluster.cycle(i)=1;
        for j=1:cluster.countNCH(i)
            nodeArch.node(cluster.noNCHs(i,j)).countS = cycle;
        end %for
    end %for
end % if

timeslot=5; %k=timeslot의 갯수
weighted=0.7; %제1자식노드그룹 정할때 가중치
if strcmp(clusterFun,'notype') %다기종 고려안하고 주기만 고려 알고리즘 일때
    % n = length(cluster.no); % Number of CHs
    l = find(cluster.countNCH);
    for i = l
        checksum=0;
        energysum = sum(cluster.energy(i,:));
        energycal=cluster.energy(i,:)/energysum;
        
        firstchild=find(energycal(1,:) >= (1/timeslot * weighted)); %제1 자식그룹정하기
        secondchild=find(energycal(1,:) < (1/timeslot * weighted) & energycal(1,:) > 0 ); %제 2자식그룹
        lcmarr=0;
        
        %%%%%제1자식 그룹의 갯수가 timeslot의 갯수보다 크지 않을때
        if timeslot <= length(firstchild) 
            [k_first,k_index] = maxk(energycal(firstchild),timeslot-1);
            [l_first,l_index] = mink(energycal(firstchild),length(firstchild)-(timeslot-1));
            % k_index,l_index
            
            countnon=1;
            lcmarr=zeros(length(l_index)+length(secondchild),3);
            for j = firstchild(l_index)             %제 1 자식그룹 탈락자 > 2 그룹으로
                nodeArch.node(cluster.noNCHs(i,j)).countS = round(1 / (energycal(1,j)*(timeslot-length(k_index))));
                lcmarr(countnon,1)=nodeArch.node(cluster.noNCHs(i,j)).countS;
                lcmarr(countnon,2)=cluster.noNCHs(i,j);
                lcmarr(countnon,3)=j;
                countnon=countnon+1;
            end
            
            for j = secondchild         %제2자식그룹 센싱 횟수 정하기
                nodeArch.node(cluster.noNCHs(i,j)).countS = round(1 / (energycal(1,j)*(timeslot-length(k_index))));
                lcmarr(countnon,1)=nodeArch.node(cluster.noNCHs(i,j)).countS;
                lcmarr(countnon,2)=cluster.noNCHs(i,j);
                lcmarr(countnon,3)=j;
                countnon=countnon+1;
            end
            
            numLength = length(lcmarr(:,1));
            answer = lcmarr(1,1);
            for f = 2:numLength
                number = lcmarr(f,1);
                high = max(answer,number);
                low = min(answer,number);
                answer= high*low / gcd(high,low);           %answer이 최소공배수
            end
            checksum=checksum+sum(lcmarr(:,1));
            cluster.cycle(i)=answer;
            
            for j = firstchild(k_index)             %제 1 자식그룹 센싱횟수 주기로 배정
                nodeArch.node(cluster.noNCHs(i,j)).countS = answer;
                checksum=checksum+answer;
            end
            k= answer*timeslot;
            if k < checksum % 타임슬롯에 배정되는 자식노드의 개수가 상기 공통 센싱 주기 내에서 센싱 되어야 하는 노드의 개수보다 클때
                checksum = checksum - k;
                [M,check_idx]=sort(cluster.energy(i,:)); %잔여 에너지가 적은 노드부터 센싱횟수 줄어듬
                idx=1;
                while M(idx) == 0
                    idx=idx+1;
                end
                while checksum~=0
                    if nodeArch.node(cluster.noNCHs(i,check_idx(idx))).countS == 0
                        idx=idx+1;
                    else
                        nodeArch.node(cluster.noNCHs(i,check_idx(idx))).countS=nodeArch.node(cluster.noNCHs(i,check_idx(idx))).countS-1;
                        checksum=checksum-1;
                    end
                    
                end
            end
        else
            %%%%%제1자식 그룹의 갯수가 timeslot의 갯수보다 클때
            answer=length(firstchild);
            checksum=0;
            countnon=1;
            if ~isempty(secondchild)
                lcmarr=zeros(length(secondchild),2);
               
                for j = secondchild         %제2자식그룹 센싱 횟수 정하기
                    nodeArch.node(cluster.noNCHs(i,j)).countS = round(1 / (energycal(1,j)*(timeslot-length(firstchild))));
                    lcmarr(countnon,1)=nodeArch.node(cluster.noNCHs(i,j)).countS;
                    lcmarr(countnon,2)=cluster.noNCHs(i,j);
                    countnon=countnon+1;
                end
                numLength = length(lcmarr(:,1));
                  
                answer = lcmarr(1,1);
                for f = 2:numLength
                    number = lcmarr(f,1);
                    high = max(answer,number);
                    low = min(answer,number);
                    answer= high*low / gcd(high,low);           %answer이 최소공배수
                end
                
            end
          
            checksum=checksum+sum(lcmarr(:,1));
            cluster.cycle(i)=answer;
            for j = firstchild            %제 1 자식그룹정하기
                nodeArch.node(cluster.noNCHs(i,j)).countS = answer;
                checksum=checksum+answer;
            end
            k=answer*timeslot;
            if k < checksum %센싱되어야하는 노드의 갯수보다 클때
                checksum = checksum - k;
                [M,check_idx]=sort(cluster.energy(i,:));
                idx=1;
                while M(idx) == 0
                    idx=idx+1;
                end
                while checksum~=0
                    if nodeArch.node(cluster.noNCHs(i,check_idx(idx))).countS == 0
                        idx=idx+1;
                    else
                        nodeArch.node(cluster.noNCHs(i,check_idx(idx))).countS=nodeArch.node(cluster.noNCHs(i,check_idx(idx))).countS-1;
                        checksum=checksum-1;
                    end
                    
                end
            end
        end %if
    end %for
end % if


if strcmp(clusterFun,'multitype') %다기종 고려 주기 고려 알고리즘 일때
    %n = length(cluster.no); % Number of CHs
    l=find(cluster.countNCH);
    for i = l
        %%%%%%%%%%%%%%%%%T가 있는 그룹
        yesT=find(cluster.NONT(i,:));
        checksumYesT=0;
        energysumYesT = sum(cluster.energy(i,yesT));
        energycalYesT = cluster.energy(i,yesT)/energysumYesT;
        
        firstchildYesT=find(energycalYesT(1,:) >= (1/timeslot * weighted)); %제1 자식그룹정하기
        secondchildYesT=find(energycalYesT(1,:) < (1/timeslot * weighted) & energycalYesT(1,:) > 0 );
     
        lcmarrYesT=0;
        
        %%%%%%%%%%%%%%%%%T가 없는 그룹
        noT=find(~cluster.NONT(i,:));
        
        checksumNoT=0;
        energysumNoT = sum(cluster.energy(i,noT));
        energycalNoT = cluster.energy(i,noT)/energysumNoT;
        
        firstchildNoT=find(energycalNoT(1,:) >= (1/timeslot * weighted)); %제1 자식그룹정하기
        secondchildNoT=find(energycalNoT(1,:) < (1/timeslot * weighted) & energycalNoT(1,:) > 0 );
        
        lcmarrNoT=0;
        
        %기종을 나눈 그룹으로 noType과 동일하게 
        
        if timeslot <= length(firstchildYesT)
            [k_first,maxkYesT] = maxk(energycalYesT(firstchildYesT),timeslot-1);            
            [l_first,minkYesT] = mink(energycalYesT(firstchildYesT),length(firstchildYesT)-(timeslot-1));   
         
            countYesT=1; 
            
            lcmarrYesT=zeros(length(minkYesT)+length(secondchildYesT),3);
            for j = firstchildYesT(minkYesT)           %제 1 자식그룹 탈락자 > 2 그룹으로
                nodeArch.node(cluster.noNCHs(i,yesT(j))).countS = round(1 / (energycalYesT(1,j)*(timeslot-length(maxkYesT))));
                lcmarrYesT(countYesT,1)=nodeArch.node(cluster.noNCHs(i,yesT(j))).countS;
                lcmarrYesT(countYesT,2)=cluster.noNCHs(i,yesT(j));
                lcmarrYesT(countYesT,3)=j;
                countYesT=countYesT+1;
            end            
            for j = secondchildYesT        %제2자식그룹 센싱 횟수 정하기
                nodeArch.node(cluster.noNCHs(i,yesT(j))).countS = round(1 / (energycalYesT(1,j)*(timeslot-length(maxkYesT))));
                lcmarrYesT(countYesT,1)=nodeArch.node(cluster.noNCHs(i,yesT(j))).countS;
                lcmarrYesT(countYesT,2)=cluster.noNCHs(i,yesT(j));
                lcmarrYesT(countYesT,3)=j;
                countYesT=countYesT+1;
            end
            
            numLength = length(lcmarrYesT(:,1));
            answer = lcmarrYesT(1,1); 
            for f = 2:numLength
                number = lcmarrYesT(f,1);
                high = max(answer,number);
                low = min(answer,number);
                answer= high*low / gcd(high,low);           %answer이 최소공배수
            end
            checksumYesT=checksumYesT+sum(lcmarrYesT(:,1));
            cluster.cycle(i,2)=answer;
            
             for j = yesT(firstchildYesT(maxkYesT))             %제 1 자식그룹정하기
                nodeArch.node(cluster.noNCHs(i,j)).countS = answer;
                checksumYesT=checksumYesT+answer;
             end
            k= answer*timeslot;
            if k < checksumYesT %센싱되어야하는 노드의 갯수보다 클때
                checksumYesT = checksumYesT - k;
                
                [M,check_idx]=sort(cluster.energy(i,yesT));
                
                idx=1;
                while M(idx) == 0
                     idx=idx+1;
                end
               while checksumYesT~=0
                    if nodeArch.node(cluster.noNCHs(i,yesT(check_idx(idx)))).countS == 0
                        idx=idx+1;
                    else
                        nodeArch.node(cluster.noNCHs(i,yesT(check_idx(idx)))).countS=nodeArch.node(cluster.noNCHs(i,yesT(check_idx(idx)))).countS-1;
                        checksumYesT=checksumYesT-1;
                    end
                 
                end
            end
        else  
            answer=length(firstchildYesT);
            checksumYesT=0;
            countYesT=1;
            if ~isempty(secondchildYesT)
                lcmarrYesT=zeros(length(secondchildYesT),2);
                for j = secondchildYesT         %제2자식그룹 센싱 횟수 정하기
                    nodeArch.node(cluster.noNCHs(i,yesT(j))).countS = round(1 / (energycalYesT(1,j)*(timeslot-length(firstchildYesT))));
                    lcmarrYesT(countYesT,1)=nodeArch.node(cluster.noNCHs(i,yesT(j))).countS;
                    lcmarrYesT(countYesT,2)=cluster.noNCHs(i,yesT(j));
                    countYesT=countYesT+1;
                end
                numLength = length(lcmarrYesT(:,1));
                answer = lcmarrYesT(1,1);            
                for f = 2:numLength
                    number = lcmarrYesT(f,1);
                    high = max(answer,number);
                    low = min(answer,number);
                    answer= high*low / gcd(high,low);           %answer이 최소공배수
                end
                 
            end
           
            checksumYesT=checksumYesT+sum(lcmarrYesT(:,1));
            cluster.cycle(i,2)=answer; %T가 있는 그룹은 cluster.cycle(minloc,2) 에 저장
           for j = yesT(firstchildYesT)          %제 1 자식그룹정하기
                nodeArch.node(cluster.noNCHs(i,j)).countS = answer; 
                checksumYesT=checksumYesT+answer;
           end 
           k=answer*timeslot;
            if k < checksumYesT %센싱되어야하는 노드의 갯수보다 클때
                 checksumYesT = checksumYesT - k;
                
                [M,check_idx]=sort(cluster.energy(i,yesT));
                
                idx=1;
                while M(idx) == 0
                     idx=idx+1;
                end
               while checksumYesT~=0
                    if nodeArch.node(cluster.noNCHs(i,yesT(check_idx(idx)))).countS == 0
                        idx=idx+1;
                    else
                        nodeArch.node(cluster.noNCHs(i,yesT(check_idx(idx)))).countS=nodeArch.node(cluster.noNCHs(i,yesT(check_idx(idx)))).countS-1;
                        checksumYesT=checksumYesT-1;
                    end
                 
                 
                end
            end
        end %if
        if timeslot <= length(firstchildNoT)
            [k_first,maxkNoT] = maxk(energycalNoT(firstchildNoT),timeslot-1);
            [l_first,minkNoT] = mink(energycalNoT(firstchildNoT),length(firstchildNoT)-(timeslot-1));
            % maxkNoT,minkNoT
            
            countNoT=1;
            %noT(firstchildNoT(minkNoT))
            lcmarrNoT=zeros(length(minkNoT)+length(secondchildNoT),3);
           
            for j = firstchildNoT(minkNoT)           %제 1 자식그룹 탈락자 > 2 그룹으로
                nodeArch.node(cluster.noNCHs(i,noT(j))).countS = round(1 / (energycalNoT(1,j)*(timeslot-length(maxkNoT))));
                lcmarrNoT(countNoT,1)=nodeArch.node(cluster.noNCHs(i,noT(j))).countS;
                lcmarrNoT(countNoT,2)=cluster.noNCHs(i,noT(j));
                lcmarrNoT(countNoT,3)=j;
                countNoT=countNoT+1;
            end
            
            %noT(secondchildNoT)
            for j = secondchildNoT        %제2자식그룹 센싱 횟수 정하기
                nodeArch.node(cluster.noNCHs(i,noT(j))).countS = round(1 / (energycalNoT(1,j)*(timeslot-length(maxkNoT))));
                lcmarrNoT(countNoT,1)=nodeArch.node(cluster.noNCHs(i,noT(j))).countS;
                lcmarrNoT(countNoT,2)=cluster.noNCHs(i,noT(j));
                lcmarrNoT(countNoT,3)=j;
                countNoT=countNoT+1;
            end
            
            numLength = length(lcmarrNoT(:,1));
            answer = lcmarrNoT(1,1);
            for f = 2:numLength
                number = lcmarrNoT(f,1);
                high = max(answer,number);
                low = min(answer,number);
                answer= high*low / gcd(high,low);           %answer이 최소공배수
            end
            checksumNoT=checksumNoT+sum(lcmarrNoT(:,1));
            cluster.cycle(i,1)=answer;
            for j = noT(firstchildNoT(maxkNoT))             %제 1 자식그룹정하기
                nodeArch.node(cluster.noNCHs(i,j)).countS = answer;
                checksumNoT=checksumNoT+answer;
            end
            
            k= answer*timeslot;
           
            if k < checksumNoT %센싱되어야하는 노드의 갯수보다 클때
               checksumNoT = checksumNoT - k;
                [M,check_idx]=sort(cluster.energy(i,noT));
                
                idx=1;
                while M(idx) == 0
                    idx=idx+1;
                end
                while checksumNoT~=0
                    if nodeArch.node(cluster.noNCHs(i,noT(check_idx(idx)))).countS == 0
                        idx=idx+1;
                    else
                        nodeArch.node(cluster.noNCHs(i,noT(check_idx(idx)))).countS=nodeArch.node(cluster.noNCHs(i,noT(check_idx(idx)))).countS-1;
                        checksumNoT=checksumNoT-1;
                    end
                end
            end
        else
            answer=length(firstchildNoT);
            checksumNoT=0;
            countNoT=1;
            if ~isempty(secondchildNoT)
                
                lcmarrNoT=zeros(length(secondchildNoT),2);
                for j = secondchildNoT         %제2자식그룹 센싱 횟수 정하기
                    nodeArch.node(cluster.noNCHs(i,noT(j))).countS = round(1 / (energycalNoT(1,j)*(timeslot-length(firstchildNoT))));
                    lcmarrNoT(countNoT,1)=nodeArch.node(cluster.noNCHs(i,noT(j))).countS;
                    lcmarrNoT(countNoT,2)=cluster.noNCHs(i,noT(j));
                    countNoT=countNoT+1;
                end
                numLength = length(lcmarrNoT(:,1));
                answer = lcmarrNoT(1,1);
                for f = 2:numLength
                    number = lcmarrNoT(f,1);
                    high = max(answer,number);
                    low = min(answer,number);
                    answer= high*low / gcd(high,low);           %answer이 최소공배수
                end
            end
            
            checksumNoT=checksumNoT+sum(lcmarrNoT(:,1));
            cluster.cycle(i,1)=answer; %T가 없는 그룹은 cluster.cycle(minloc,1) 에 저장
            for j = noT(firstchildNoT)          %제 1 자식그룹정하기
                nodeArch.node(cluster.noNCHs(i,j)).countS = answer;
                checksumNoT=checksumNoT+answer;
            end
            k=answer*timeslot;
            if k < checksumNoT %센싱되어야하는 노드의 갯수보다 클때
                checksumNoT = checksumNoT - k;
                [M,check_idx]=sort(cluster.energy(i,noT));
                
                idx=1;
                while M(idx) == 0
                    idx=idx+1;
                end
                while checksumNoT~=0
                    if nodeArch.node(cluster.noNCHs(i,noT(check_idx(idx)))).countS == 0
                        idx=idx+1;
                    else
                        nodeArch.node(cluster.noNCHs(i,noT(check_idx(idx)))).countS=nodeArch.node(cluster.noNCHs(i,noT(check_idx(idx)))).countS-1;
                        checksumNoT=checksumNoT-1;
                    end
                end
            end
        end %if
    end %for    
end % if

clusterModel.nodeArch = nodeArch;
clusterModel.clusterNode=cluster;
end
