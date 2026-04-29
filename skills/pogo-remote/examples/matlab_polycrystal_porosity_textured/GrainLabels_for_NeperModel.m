% Label elements/pixels according to grain ID from a CTF file.
clear;
close all;
clc;

CS = { ...
  'notIndexed',...
  crystalSymmetry('m-3m', [2.9 2.9 2.9], 'mineral', 'Iron bcc (old)', 'color', [0.53 0.81 0.98]),...
  crystalSymmetry('m-3m', [3.7 3.7 3.7], 'mineral', 'Iron fcc', 'color', [0.56 0.74 0.56])};

script_dir = fileparts(mfilename('fullpath'));
input_dir = fullfile(script_dir, 'input_texture_data');
output_dir = fullfile(script_dir, 'output_grain_labels');
if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

files = dir(fullfile(input_dir, '*.ctf'));
if isempty(files)
    error('No .ctf files found in input_texture_data/.');
end

setMTEXpref('xAxisDirection','east');
setMTEXpref('zAxisDirection','outOfPlane');

for i = 1:length(files)
    [~, base, ~] = fileparts(files(i).name);
    varname = ['grainId_' base];
    ebsd = EBSD.load(fullfile(input_dir, files(i).name), CS, 'interface', 'ctf', 'convertEuler2SpatialReferenceFrame');
    [~, ebsd.grainId, ebsd.mis2mean] = calcGrains(ebsd('indexed'),'theshold',10*degree); %#ok<ASGLU>
    dlmwrite(fullfile(output_dir, [varname '.txt']), ebsd.grainId, 'delimiter', '\t', 'precision', 6);
end
