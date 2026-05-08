function [ ] = savePoly( fileName, points, segments, holes )
%savePoly - saves point, segment and hole data for pogoMesh to a .poly file
%
%   savePoly( fileName, points, segments, holes )
%
%fileName - file name
%points - coords in 2D of the points - 1st dim coordinate, 2nd loops
%         through all the points
%segments - segments linking the points, 1 indexed - 1st dim indicates start
%        and end points for each, 2nd dim loops through different segments
%holes - coords in 2D of any holes which should be made in the mesh
%        (optional), same defn as points
%Written by P. Huthwaite, 2017.
%
%Not to be distributed.

if nargin < 4
    holes = [];
end

addExt = 0;
if verLessThan('matlab','9.1')
    if isempty(strfind(fileName,'.')) %#ok<STREMP>
        addExt = 1;
    end
else
    if ~contains(fileName,'.')
        addExt = 1;
    end
end
if addExt
    fileName = [fileName '.poly'];
end

nPoints = size(points,2);
nSegs = size(segments,2);

if size(points,1) ~= 2
    error('points is wrong size: dim 1 should have size 2')
end

if size(segments,1) ~= 2
    error('segments is wrong size: dim 1 should have size 2')
end

fid = fopen(fileName,'w');
fprintf(fid,'%d 2 0 0\n',nPoints);

cnt = 1:nPoints;
fprintf(fid,'%d %g %g\n',[cnt(:) points(:,:).'].');

fprintf(fid,'%d 0\n',nSegs);
cnt = 1:nSegs;
fprintf(fid,'%d %d %d\n',[cnt(:) segments(:,:).'].');

if nargin > 3 && ~isempty(holes)
    if size(holes,1) ~= 2
        error('holes is wrong size: dim 1 should have size 2')
    end

    nHoles = size(holes,2);
    fprintf(fid,'%d\n',nHoles);
    cnt = 1:nHoles;
    fprintf(fid,'%d %g %g\n',[cnt(:) holes(:,:).'].');
else
    fprintf(fid,'0\n');
end
fclose(fid);

end
