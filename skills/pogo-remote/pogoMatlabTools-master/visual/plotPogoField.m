function [  ] = plotPogoField( fileName, plotType, randSel, myScale, nodesPlotFact )
%plotPogoField - load and plot field data from Pogo FE
%
% plotPogoField( fileName, plotType, randSel, myScale, myDensFact )
%
%Algorithm is designed to work with most models well with the default
%settings. Some tweaking values are included if these are not suitable.
%
% Likely to work better with larger models, with more than 50k nodes.
%
%fileName - the file name
%plotType - an integer 1-3 specifying which plot type to do
%   1. Just offset the nodes in space
%   2. As 1, but keep a 'shadow' in the background
%   3. Plot displacement of each node as a line (default)
%   4. Plot displacement of each node as a line, with colour of point being
%   used to indicate amplitude of displacement
%randSel (optional, 1 default) - set to 0 to use a regular selection of
%nodes to plot (e.g. 1:6:nNodes) rather than a random selection of
%nodes (set to 1)
%myScale (optional) - how much to scale the displacement by
%myDensFact (optional) - scaling of how many nodes to plot
%
% Written by P. Huthwaite, April 2014

    if nargin < 2 || isempty(plotType)
        plotType = 3;
    end
    if nargin < 3 || isempty(randSel)
        randSel = 1;
    end
    if nargin < 4 || isempty(myScale)
        myScale = 1;
    end
    if nargin < 5 || isempty(nodesPlotFact)
        nodesPlotFact = 1;
    end

    fprintf('Loading file %s\n',fileName);
    f = loadPogoField(fileName);
    nodeLocs = f.nodeLocs;
    t = f.times;
    ux = f.ux;
    uy = f.uy;
    fprintf('Done.\n');

    nNodes = size(nodeLocs,2);


    mnx = min(nodeLocs(1,:));
    mxx = max(nodeLocs(1,:));
    mny = min(nodeLocs(2,:));
    mxy = max(nodeLocs(2,:));

    dRange = max(nodeLocs(1,:))-min(nodeLocs(1,:));
    factScale = dRange/max([ux(:).' uy(:).']);

    if plotType == 1 || plotType == 2
        nNodesPlot = 200000*nodesPlotFact;

        %densFact = ceil(nNodes/200000/myDensFact); %try to keep this good for an arbitrary number of nodes
        plotScale = 0.2;
    elseif plotType == 3
        %densFact = ceil(nNodes*3/100000/myDensFact);
        nNodesPlot = 33000*nodesPlotFact;
        plotScale = 0.2;
    end

    myFig = figure;
    set(myFig,'units','normalized','outerposition',[0 0 1 1]);

    if nNodesPlot > nNodes
        nNodesPlot = nNodes;
    end


    %whichNodes = 1:densFact:nNodes; %change to do this randomly
    if randSel == 0
        whichNodes = round(linspace(1,nNodes,nNodesPlot));
    else
        whichNodes = randperm(nNodes,nNodesPlot);
    end

    for frame = 1:length(t)

        if ~ishandle(myFig)
            %window closed manually
            break;
        end

        figure(myFig)
        if plotType == 1
            hold off
            plot(nodeLocs(1,whichNodes)+ux(whichNodes,frame).'*plotScale*factScale*myScale,nodeLocs(2,whichNodes)+uy(whichNodes,frame).'*plotScale,'k.','MarkerSize',1)
        elseif plotType == 2
            hold off
            plot(nodeLocs(1,whichNodes),nodeLocs(2,whichNodes),'b.','MarkerSize',1)
            hold on
            plot(nodeLocs(1,whichNodes)+ux(whichNodes,frame).'*plotScale*factScale*myScale,nodeLocs(2,whichNodes)+uy(whichNodes,frame).'*plotScale,'k.','MarkerSize',1)
        elseif plotType == 3
            hold off
            plot(nodeLocs(1,whichNodes),nodeLocs(2,whichNodes),'bo','MarkerSize',3)
            plx = [nodeLocs(1,whichNodes).' nodeLocs(1,whichNodes).'+ux(whichNodes,frame)*plotScale*factScale*myScale nan(length(whichNodes),1)].';
            ply = [nodeLocs(2,whichNodes).' nodeLocs(2,whichNodes).'+uy(whichNodes,frame)*plotScale*factScale*myScale nan(length(whichNodes),1)].';
            hold on
            plot(plx(:), ply(:),'k-')
        elseif plotType == 4
            hold off
            strength = sqrt(ux(whichNodes,frame).^2+uy(whichNodes,frame).^2);
            scatter(nodeLocs(1,whichNodes),nodeLocs(2,whichNodes),3,strength)
            plx = [nodeLocs(1,whichNodes).' nodeLocs(1,whichNodes).'+ux(whichNodes,frame)*plotScale*factScale*myScale nan(length(whichNodes),1)].';
            ply = [nodeLocs(2,whichNodes).' nodeLocs(2,whichNodes).'+uy(whichNodes,frame)*plotScale*factScale*myScale nan(length(whichNodes),1)].';
            hold on
            plot(plx(:), ply(:),'k-')
        end
        axis equal
        axis([mnx mxx mny mxy])
        title(sprintf('%s at time %4.2es',fileName,t(frame)))
        drawnow
        if plotType ~= 4
            pause(0.1)
        end

    end

end
