function [] = plotPoly(points, segments, holes, doLabels )
%plotPoly - plot the data written to a poly file
%
%plotPoly(points, segments, holes, doLabels )
%
%Segments are red, holes are blue and points are green
%
%Written by P. Huthwaite, March 2019
    if nargin < 4 || isempty(doLabels)
        doLabels = 1;
    end
    if nargin < 3
        holes = [];
    end
    segs = segments;
    nSegs = size(segments,2);
    nPoints = size(points,2);
    coords = points;
    if max(segs(:)) > nPoints
        error('Maximum point specified in segments (%d) is greater than the number of points (%d),',max(segs(:)), nPoints)
    end

    hold on
    for sCnt = 1:nSegs
        %sCnt
        plot(coords(1,segs(:,sCnt)), coords(2,segs(:,sCnt)),'r--')
        if doLabels
            cx = mean(coords(1,segs(:,sCnt)));
            cy = mean(coords(2,segs(:,sCnt)));
            t =text(cx,cy,sprintf('%d',sCnt),'HorizontalAlignment','center','Color',[1. 0 0]);
        end
    end

    if doLabels
        for pCnt = 1:nPoints
            cx = coords(1,pCnt);
            cy = coords(2,pCnt);
            t =text(cx,cy,sprintf('%d',pCnt),'HorizontalAlignment','center','Color',[0 1. 0]);
        end
    else
        plot(coords(1,:), coords(2,:), 'gx')
    end
    if ~isempty(holes)
        if doLabels
            for pCnt = 1:size(holes,2)
                cx = holes(1,pCnt);
                cy = holes(2,pCnt);
                t =text(cx,cy,sprintf('%d',pCnt),'HorizontalAlignment','center','Color',[0 0 1.]);
            end
        else
            plot(holes(1,:), holes(2,:), 'bx')
        end

%         plot(holes(1,:), holes(2,:), 'gx')
%         for hCnt = 1:size(holes,2)
%             t =text(cx,cy,sprintf('%d',pCnt),'HorizontalAlignment','center','Color',[0 0 1.]);
%         end
    end

end
