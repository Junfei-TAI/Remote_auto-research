% PostProcess_PulseEcho_Hist_Demo.m
% Basic starter for reading one or more POGO history files and plotting averaged Z traces.

clear; clc; close all;
set(0, 'DefaultFigureVisible', 'off');
script_dir = fileparts(mfilename('fullpath'));
addpath(fullfile(script_dir, '..', 'toolbox'));

fnamelist = {
    'MultilayerComposite_PulseEcho_Demo_defect_01.pogo-hist'
};

num_files = numel(fnamelist);
avg_signals = [];
time = [];

for i = 1:num_files
    [hist1, ~, ~, ~] = loadPogoHist(fnamelist{i});
    if isempty(time)
        time = (1:hist1.nt)' * hist1.dt;
    end
    probe_cols = 3:3:size(hist1.sets.main.histTraces, 2);
    if isempty(probe_cols)
        probe_cols = 1:size(hist1.sets.main.histTraces, 2);
    end
    avg_signals(:, i) = mean(hist1.sets.main.histTraces(:, probe_cols), 2);
end

fig = figure;
plot(time, avg_signals, 'LineWidth', 1.2);
xlabel('Time (s)');
ylabel('Amplitude');
title('Average pulse-echo traces');
grid on;
print(fig, 'avg_signals_demo.png', '-dpng', '-r200');
