function  [ ] = viewPogoField( f, npix, tImages, plotDir, plane, offset, wm )
%function  [ ] = viewPogoField( f, npix, tImages, plotDir, plane, offset, wm )
%viewField - view field output from Pogo in 2D or 3D
%NB - in 3D particular, the speed is often low due to the interpolation
%routine
%
%f - field structure, as loaded from loadPogoField()
%all other inputs optional (set to [] if unused, or just omit if at end of list)
%npix - number of pixels along longest axis (default 100)
%tImages - which time images to plot (default all in f)
%plotDir - which direction of displacement to plot, x = 1, y = 2, z = 3,
%           0 = magnitude (default)
%plane - (3D only) which plane to plot - x-y = 1, x-z = 2, y-z = 3,
%        auto = 0 (default). Auto plots the two dimensions with the largest range.
%offset - (3D only) position along the other axis (default = 0)
%wm - wave map to use - passed directly to colormap so see help colormap for
%           details. Defaults to wave 'red-white-blue' map.
%
%Example usage:
%f = loadPogoField('example.pogo-field');
%viewPogoField(f);
%
%Written Dec 2016, Peter Huthwaite
%Fixed to give full support to v1.08 onwards of the file format - July 2025

nDims = size(f.nodeLocs,1);
if nargin < 7 || isempty(wm)
    %generate wave colourmap (i.e. blue-white-red)
    N = 64;
    map1 = [(0:1:N-1).'/(N-1) (0:1:N-1).'/(N-1) ones(N,1)];
    map2 = [ones(N,1) (N-1:-1:0).'/(N-1) (N-1:-1:0).'/(N-1)];
    wm = [map1;map2];
end

if nargin < 2 || isempty(npix)
    npix = 100;
end
if npix < 1 || npix ~= round(npix)
    error('npix must be an integer and greater than 0')
end

if nargin < 3 || isempty(tImages)
    tImages = 1:length(f.times);
end
if max(tImages) > length(f.times) || min(tImages) < 1
    error('tFrames contains values outside range')
end

if nargin < 4 || isempty(plotDir)
    plotDir = 0;
end
if plotDir < -1  || plotDir ~= round(plotDir)
    error('plotDir not in range.')
end

if nargin < 5 || isempty(plane)
    plane = 0;
    %1 is x-y
    %2 is x-z
    %3 is y-z
    %0 is auto (biggest dims)
end
if nDims == 2
    plane = 0;
end
if plane < 0 || plane ~= round(plane)
    error('plotDir not in range.')
end

if nargin < 6 || isempty(offset)
    offset = 0;
    %position of plane along other axis
end

px = f.nodeLocs(1,:);
py = f.nodeLocs(2,:);
if nDims == 3
    pz = f.nodeLocs(3,:);
end

% figure
% plot(px,pz,'k.')

xMax = max(px);
xMin = min(px);
xRange = xMax - xMin;

yMax = max(py);
yMin = min(py);
yRange = yMax - yMin;

if nDims == 3
    zMax = max(pz);
    zMin = min(pz);
    zRange = zMax - zMin;


    if plane == 0
        if zRange < xRange && zRange < yRange
           plane = 1;
        elseif yRange < xRange && yRange < zRange
           plane = 2;
        elseif xRange < yRange && xRange < zRange
           plane = 3;
        end
    end
else
    zRange = 0;
end

maxRange = max([xRange yRange zRange]);

dpx = maxRange/npix; %so npix pixels in maximum direction

npx = round((xMax-xMin)/dpx);
npy = round((yMax-yMin)/dpx);
cpx = (xMax+xMin)/2;
cpy = (yMax+yMin)/2;
gpx = ((1:npx)-(npx+1)/2)*dpx+cpx;
gpy = ((1:npy)-(npy+1)/2)*dpx+cpy;

if nDims == 3
    npz = round((zMax-zMin)/dpx);
    cpz = (zMax+zMin)/2;
    gpz = ((1:npz)-(npz+1)/2)*dpx+cpz;
end


if plane == 1 || nDims == 2
    %x-y plane
    [GPX, GPY] = ndgrid(gpx,gpy);
elseif plane == 2
    %x-z plane
    [GPX, GPZ] = ndgrid(gpx,gpz);
else
    %y-z plane
    [GPY, GPZ] = ndgrid(gpy,gpz);
end

runFig = figure;
if f.fileVerFull >= 1008
    dofs = unique(f.dofNums);
    nNodesTot = length(f.nodeLocs);
    v = zeros(nNodesTot,1);
end
for tCnt = tImages
    if f.fileVerFull >= 1008
        if plotDir == -1
            if length(f.dofScales) < max(dofs)
                error('dofScales is insufficient length %d. It must cover all the dofs present: %s. ',length(dofScales), strjoin(string(dofs), ', '))
            end
            v = zeros(nNodesTot,1);
            for dCnt = 1:length(dofs)
                dof = dofs(dCnt);
                v(f.nodeNums(f.dofNums == dof)) = v(f.nodeNums(f.dofNums == dof)) + ...
                    f.u(f.dofNums == dof,tCnt) * f.dofScales(dof);
            end
        elseif plotDir == 0
            if isscalar(dofs)
                %just take the one DOF available:
                v(f.nodeNums(f.dofNums == dofs)) = f.u(f.dofNums == dofs,tCnt);
            else % do root sum of the squares
                v = zeros(nNodesTot,1);
                for dCnt = 1:length(dofs)
                    dof = dofs(dCnt);
                    v(f.nodeNums(f.dofNums == dof)) = v(f.nodeNums(f.dofNums == dof)) + ...
                        f.u(f.dofNums == dof,tCnt).^2;
                end
                v = sqrt(v);
            end
        else
            if ~ismember(plotDir,dofs)
                error('Unable to plot dof "%d". Valid options are %s. ',plotDir, strjoin(string(dofs), ', '))
            end
            v(f.nodeNums(f.dofNums == plotDir)) = f.u(f.dofNums == plotDir,tCnt);
        end
    else
        if plotDir == 0
            if f.nDofPerNode == 1
                v = f.ux(:,tCnt);
            elseif f.nDofPerNode == 2
                v = sqrt(f.ux(:,tCnt).^2+f.uy(:,tCnt).^2); %plot magnitude
            else
                v = sqrt(f.ux(:,tCnt).^2+f.uy(:,tCnt).^2+f.uz(:,tCnt).^2); %plot magnitude
            end
        elseif plotDir == 1
            v = f.ux(:,tCnt); %plot x direction
        elseif plotDir == 2
            v = f.uy(:,tCnt); %plot y direction
        else
            v = f.uz(:,tCnt); %plot z direction
        end
    end

    %do the interpolation onto a uniform grid:
    if nDims == 2
        vq = griddata(px,py,v,GPX,GPY);
    else
        if plane == 1
            %x-y plane
            vq = griddata(px,py,pz,v,GPX,GPY,zeros(npx,npy)+offset);
        elseif plane == 2
            %x-z plane
            vq = griddata(px,py,pz,v,GPX,zeros(npx,npz),GPZ+offset);
        else
            %y-z plane
            vq = griddata(px,py,pz,v,zeros(npy,npz),GPY,GPZ+offset);
        end
    end

    m = max(vq(:)); %get range
    if m == 0
        m = 1;
    end

    if ~ishandle(runFig)
        return
    end
    figure(runFig)
    %plot the result in cartesian coords
    if plane == 1 || nDims == 2
        %x-y plane
        %cartimagesc(gpx,gpy,vq)
        imagesc(gpx,gpy,vq.')
        xlabel('x')
        ylabel('y')
    elseif plane == 2
        %x-z plane
        %cartimagesc(gpx,gpz,vq)
        imagesc(gpx,gpz,vq.')
        xlabel('x')
        ylabel('z')
    else
        %y-z plane
        %cartimagesc(gpy,gpz,vq)
        imagesc(gpy,gpz,vq.')
        xlabel('y')
        ylabel('z')
    end
    axis xy
%     axis image
    colorbar

    colormap(wm) %choose the colourmap
    title(sprintf('Frame %d, time %4.2gs',tCnt,f.times(tCnt))) %set title
    caxis([-1 1]*m/2) %set colour range
    drawnow %draw the image now rather than waiting
end
end
