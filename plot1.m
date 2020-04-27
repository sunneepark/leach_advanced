% Mohammad Hossein Homaei, Homaei@wsnlab.org & Homaei@wsnlab.ir
% Ver 1. 10/2014
figure(1), hold on

    for i = 1:100
    %t:온도, h:습도, g:가스
        t=nodeArch.Category(i).T
        h=nodeArch.Category(i).H
        g=nodeArch.Category(i).G
        %fprintf('[%d, %d,%d]',t,h,g);
        
        total = t + h + g;
          %fprintf('%d: %d',i,total);
    end

plot(nodeArch.nodesLoc(:, 1), nodeArch.nodesLoc(:, 2),...
   '.', 'MarkerSize',20, 'MarkerFaceColor','b');
plot(netArch.Sink.x, netArch.Sink.y,'o', ...
    'MarkerSize',8, 'MarkerFaceColor', 'g');