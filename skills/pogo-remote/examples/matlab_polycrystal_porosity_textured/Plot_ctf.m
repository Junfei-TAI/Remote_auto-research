clear;
close all;
clc;

%% Import Script for EBSD Data
% Cleaned relative-path version.

%% Specify Crystal and Specimen Symmetries
CS = { ...
  'notIndexed',...
  crystalSymmetry('m-3m', [2.9 2.9 2.9], 'mineral', 'Iron bcc (old)', 'color', [0.53 0.81 0.98]),...
  crystalSymmetry('m-3m', [3.7 3.7 3.7], 'mineral', 'Iron fcc', 'color', [0.56 0.74 0.56])};

setMTEXpref('xAxisDirection','east');
setMTEXpref('zAxisDirection','outOfPlane');

%% Specify File Names
script_dir = fileparts(mfilename('fullpath'));
input_dir = fullfile(script_dir, 'input_texture_data');
output_dir = fullfile(script_dir, 'output_texture_figures');
name = 'example_texture';

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

fname = fullfile(input_dir, [name '.ctf']);
sname_pf = fullfile(output_dir, [name '_pf.png']);
sname_pf_contourf = fullfile(output_dir, [name '_pf_contourf.png']);
sname_ipf = fullfile(output_dir, [name '_ipf.png']);

%% Import the Data
ebsd = EBSD.load(fname,CS,'interface','ctf', ...
  'convertEuler2SpatialReferenceFrame');

%% Plot ipf key
figure
ipfKey = ipfHSVKey(ebsd('Iron fcc'));
ipfKey.colorPostRotation = reflection(yvector);
plot(ipfKey)
ipfKey.inversePoleFigureDirection = vector3d.Y;
saveas(gcf, fullfile(output_dir, 'IPF_y_key.png'))

%% Plot pole figure
h = Miller({1,0,0},{1,1,0},{1,1,1},ebsd('Iron fcc').CS);
plotPDF(ebsd('Iron fcc').orientations,h,'figSize','small')
saveas(gcf,sname_pf)

figure
plotPDF(ebsd('Iron fcc').orientations,h,'figSize','small','contourf')
mtexColorbar;
saveas(gcf,sname_pf_contourf)

%% Plot ipf
figure
colors = ipfKey.orientation2color(ebsd('Iron fcc').orientations);
plot(ebsd('Iron fcc'),colors,'micronbar','on')
[grains,ebsd.grainId,ebsd.mis2mean] = calcGrains(ebsd('indexed'),'theshold',10*degree); %#ok<ASGLU>
grains = smooth(grains,5);
cS = crystalShape.cube(ebsd('Iron fcc').CS);
saveas(gcf,sname_ipf)

figure
grains = calcGrains(ebsd);
grains = smooth(grains,5);
plot(grains,grains.meanOrientation)
isBig = grains.grainSize>200;
cSGrains = grains(isBig).meanOrientation * cS * 0.7 * sqrt(grains(isBig).area);
hold on
plot(grains(isBig).centroid + cSGrains)
hold off
