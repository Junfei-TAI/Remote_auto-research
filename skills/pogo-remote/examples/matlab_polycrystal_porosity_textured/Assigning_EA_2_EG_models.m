% Assigning_EA_2_EG_models.m
% Cleaned helper for assigning textured Euler angles to element-group labels.

clear;
close all;
clc;

rng(1234);
script_dir = fileparts(mfilename('fullpath'));
input_dir = fullfile(script_dir, 'input_euler_angle_mats');
grain_label_file = fullfile(script_dir, 'input_texture_data', 'grainId_target.txt');
output_dir = fullfile(script_dir, 'output_assigned_euler_angles');

if ~exist(output_dir, 'dir')
    mkdir(output_dir);
end

files = dir(fullfile(input_dir, '*.mat'));
if isempty(files)
    error('No .mat files found in input_euler_angle_mats/.');
end
if ~exist(grain_label_file, 'file')
    error('Missing grain label file: %s', grain_label_file);
end

target_grain_ebsd = readmatrix(grain_label_file);
grains = unique(target_grain_ebsd);

for k = 1:length(files)
    matFileName = fullfile(input_dir, files(k).name);
    [~, name, ~] = fileparts(matFileName);
    newFilename = fullfile(output_dir, [name '_texturedEA_assigned.txt']);

    matData = load(matFileName);
    if ~isfield(matData, 'euler_angles_final_deg')
        error('File %s does not contain euler_angles_final_deg.', files(k).name);
    end
    EulerAngles = matData.euler_angles_final_deg;
    unique_rows = unique(EulerAngles, 'rows');
    num_unique_rows = size(unique_rows, 1);
    target_grain_ebsd_new = zeros(size(target_grain_ebsd,1), 3);

    for i = 1:length(grains)
        randomRowIndex = randi(num_unique_rows);
        mask = target_grain_ebsd == grains(i);
        target_grain_ebsd_new(mask, :) = repmat(unique_rows(randomRowIndex, :), sum(mask), 1);
    end

    dlmwrite(newFilename, target_grain_ebsd_new, 'delimiter', '\t');
end
