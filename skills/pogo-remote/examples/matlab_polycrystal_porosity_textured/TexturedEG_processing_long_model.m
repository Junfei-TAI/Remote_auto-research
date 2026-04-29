clc
clear all
close all

X_mesh = 10e-6; 
Y_mesh = 10e-6;
% nodes
X_sample = 5e-3;%unit: m.
Y_sample = 10e-3;
X_cubic = X_sample*1;
Y_cubic = Y_sample*1;
dim = 2;
D = 10; %unit:mm
ele_size_x = 10e-6; % m
ele_size_y = ele_size_x; % m
Att = [];
freq_shift = [];
cycles = 5;
frequency = 10e6;
SamplingRate = 1 / 2e-10;
window_size = round((cycles / frequency) * SamplingRate * 1.5);
%%
fnamelist={...
    '0Sig5texturedEA_EG75_5by10mm_10um_10MHz.pogo-hist',...
    '0Sig10texturedEA_EG75_5by10mm_10um_10MHz.pogo-hist',...
    '0Sig15texturedEA_EG75_5by10mm_10um_10MHz.pogo-hist',...
    '0Sig20texturedEA_EG75_5by10mm_10um_10MHz.pogo-hist',...
    '0Sig25texturedEA_EG75_5by10mm_10um_10MHz.pogo-hist',...
    '0Sig30texturedEA_EG75_5by10mm_10um_10MHz.pogo-hist',...
    '0Sig35texturedEA_EG75_5by10mm_10um_10MHz.pogo-hist',...
    '0Sig40texturedEA_EG75_5by10mm_10um_10MHz.pogo-hist',...
    '0Sig45texturedEA_EG75_5by10mm_10um_10MHz.pogo-hist',...
    '0Sig50texturedEA_EG75_5by10mm_10um_10MHz.pogo-hist',...
    '0SigXtexturedEA_EG75_5by10mm_10um_10MHz.pogo-hist',...
    };
fsavelist = {...
    '0Sig5texturedEA_EG75_5by10mm_10um_10MHz.mat',...
    '0Sig10texturedEA_EG75_5by10mm_10um_10MHz.mat',...
    '0Sig15texturedEA_EG75_5by10mm_10um_10MHz.mat',...
    '0Sig20texturedEA_EG75_5by10mm_10um_10MHz.mat',...
    '0Sig25texturedEA_EG75_5by10mm_10um_10MHz.mat',...
    '0Sig30texturedEA_EG75_5by10mm_10um_10MHz.mat',...
    '0Sig35texturedEA_EG75_5by10mm_10um_10MHz.mat',...
    '0Sig40texturedEA_EG75_5by10mm_10um_10MHz.mat',...
    '0Sig45texturedEA_EG75_5by10mm_10um_10MHz.mat',...
    '0Sig50texturedEA_EG75_5by10mm_10um_10MHz.mat',...
    '0SigXtexturedEA_EG75_5by10mm_10um_10MHz.mat',...
    };
%% Import the Data
for i = 1:length(fnamelist)
    disp(fnamelist{i})
    [ hist, fileVer, prec, header ] = loadPogoHist(fnamelist{i});
    time = [1:hist.nt]'*hist.dt;
    num_nodes = length(hist.sets.main.nodeNums )/dim
    num_cols = round(sum(hist.sets.main.nodePos(2, :) == hist.sets.main.nodePos(2,1))/dim)
    num_rows = round(length(hist.sets.main.nodeNums)*0.5/num_cols)
    element_index = RemeshReceivers(ele_size_x, ele_size_y, num_cols, num_rows);
    transducer_num = length(hist.sets.main.nodeDofs)/2;
    center_index = 2*floor(transducer_num/2);
%     figure;
%     subplot(2,1,1);
%     plot(time,hist.sets.main.histTraces(:,center_index))
%     title('Longitudinal wave in the center');
%     ylim([-1.5*max(hist.sets.main.histTraces(:,center_index)) 1.5*max(hist.sets.main.histTraces(:,center_index))])
%     subplot(2,1,2);
%     plot(time,hist.sets.main.histTraces(:,center_index+1))
%     title('Shear wave in the center');
%     ylim([-1.5*max(hist.sets.main.histTraces(:,center_index+1)) 1.5*max(hist.sets.main.histTraces(:,center_index+1))])
    X_lim_low = (X_cubic-X_sample)/2-X_mesh/2;
    X_lim_up = X_lim_low+X_sample+X_mesh/2;
    Y_lim_low = (Y_cubic-Y_sample)/2;
    Y_lim_up = Y_lim_low+Y_sample;
    node_bottom = find(...
                (hist.sets.main.nodePos(1,:)>=X_lim_low)&...
                (hist.sets.main.nodePos(1,:)<=X_lim_up)&...
                (hist.sets.main.nodePos(2,:)>=Y_lim_low-Y_mesh/2)&...
                (hist.sets.main.nodePos(2,:)<=Y_lim_low+Y_mesh/2)...
                );

    node_top = find(...
                (hist.sets.main.nodePos(1,:)>=X_lim_low)&...
                (hist.sets.main.nodePos(1,:)<=X_lim_up)&...
                (hist.sets.main.nodePos(2,:)>=Y_lim_up-Y_mesh/2)&...
                (hist.sets.main.nodePos(2,:)<=Y_lim_up+Y_mesh/2)...
                );
%     Vpp1 = 0;
%     Vpp2 = 0;
%     for j = 2:2:length(node_bottom)
%         Vpp1 = Vpp1 + max(hist.sets.main.histTraces(:,node_top(j)))-min(hist.sets.main.histTraces(:,node_top(j)));
%         Vpp2 = Vpp2 + max(hist.sets.main.histTraces(:,node_bottom(j)))-min(hist.sets.main.histTraces(:,node_bottom(j)));
%     end
%     Vpp1 = Vpp1/(length(node_top)/2);
%     Vpp2 = Vpp2/(length(node_bottom)/2);
%     Att_10 = 20*log10(Vpp1/Vpp2)/D
%     Att = [Att Att_10]
    input_signal_avg = mean(hist.sets.main.histTraces(:, node_top), 2);
    output_signal_avg = mean(hist.sets.main.histTraces(:, node_bottom), 2);

    figure;
    subplot(2,1,1);
    hold on;
    plot(time, input_signal_avg, 'k-', 'LineWidth', 1.5);
    plot(time, output_signal_avg, 'r--', 'LineWidth', 1.5);
    xlabel('Time');
    ylabel('Amplitude');
    legend('Input', 'Output');
    hold off;
    
    [Vpp1, input_peak_index] = max(input_signal_avg);  % Index of max peak in input signal
    [Vpp2, output_peak_index] = max(output_signal_avg);
    
    Att_10 = 20*log10(Vpp1/Vpp2)/D;
    Att = [Att Att_10];
    half_window_size = floor(window_size / 2);
    window1_start = max(input_peak_index - half_window_size, 1);  % Ensure start index is not less than 1
    window1_end = min(input_peak_index + half_window_size, length(input_signal_avg));  % Ensure end index is within bounds
    window1 = input_signal_avg(window1_start:window1_end);
    
    % Define window2 around the output signal peak
    window2_start = max(output_peak_index - half_window_size, 1);  % Ensure start index is not less than 1
    window2_end = min(output_peak_index + half_window_size, length(output_signal_avg));  % Ensure end index is within bounds
    window2 = output_signal_avg(window2_start:window2_end);
    
%     desired_length = 100000;
%     window1_padded = [window1; zeros(desired_length-length(window1), 1)];
%     window2_padded = [window2; zeros(desired_length-length(window1), 1)];
    
    [freq1, signal_FD_1] = demo_1dft(window1, hist.dt);
    [freq2, signal_FD_2] = demo_1dft(window2, hist.dt);
    
    freq1 = freq1*1e-3;
    freq2 = freq2*1e-3;

    [~, input_freq_peak_index] = max(signal_FD_1);  % Index of max peak in input signal
    [~, output_freq_peak_index] = max(signal_FD_2);

    peak_frequency_1 = freq1(input_freq_peak_index)
    peak_frequency_2 = freq2(output_freq_peak_index)
    freq_s = peak_frequency_1 - peak_frequency_2
    freq_shift = [freq_shift,freq_s];
    subplot(2,1,2);
    hold on;
    plot(freq1, signal_FD_1, 'k-', 'LineWidth', 1.5);
    plot(freq2, signal_FD_2, 'r--', 'LineWidth', 1.5);
    xlim([0,40])
    % Add labels and legend
    xlabel('Frequency (MHz)');
    ylabel('Amplitude');
    hold off;

    save(fsavelist{i}, 'time', 'input_signal_avg', 'output_signal_avg', ...
        'freq1', 'signal_FD_1', 'freq2', 'signal_FD_2');

end
disp(freq_shift)
disp(Att)
figure
plot(Att)
