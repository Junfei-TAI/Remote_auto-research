# TAI Junfei
# NTU
# 07 Nov 2024

# The code is for processing the signals from textured EG models.

import numpy as np
import matplotlib.pyplot as plt
import os
from scipy.io import loadmat
import seaborn as sns

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
folder_path = os.path.join(SCRIPT_DIR, "output_postprocess_mat")
output_dir = os.path.join(SCRIPT_DIR, "output_postprocess_figures")
os.makedirs(output_dir, exist_ok=True)

# def demo_1dft(s_0, dt, up_f):
#     # dt: time step, unit: s
#     # upper frequency limit, unit: Hz
#     s_0 = s_0 - np.mean(s_0)
#     # n = s_0.shape[0]
#     n = len(s_0)
#     freq = np.fft.fftfreq(n, d=dt)
#     mask = (freq <= up_f)
#     s_FD = np.fft.fft(s_0)
#     s_FD = s_FD * mask  # Apply the frequency mask
#     magnitudes = np.abs(s_FD)
#     angle = np.angle(s_FD)
#     normalized_y = magnitudes/n
#     x = np.arange(n)
#     half_x = x[range(int(n/2))]
#     normalized_half_y = normalized_y[range(int(n/2))]
#
#     return half_x, normalized_half_y
def demo_1dft(s_0, dt):
    # Subtract the mean to center the signal
    s_0 = s_0 - np.mean(s_0)

    # Define FFT length based on the MATLAB code's specification
    n_fft = round(1e-3 / dt)

    # Perform FFT with zero-padding to n_fft length
    s_FD = np.fft.fft(s_0, n=n_fft)

    # Compute the magnitude spectrum
    magnitudes = np.abs(s_FD)

    # Generate frequency array
    freq = np.fft.fftfreq(n_fft, d=dt) * 1e-6 # to MhZ

    # Only return the positive frequencies (similar to MATLAB behavior)
    half_n = n_fft // 2
    freq = freq[:half_n]
    magnitudes = magnitudes[:half_n]

    return freq, magnitudes
# def freq_shift(Filename, time_file, SamplingPoints, SamplingRate, cycles, frequency, thickness, wavespeed):
#     waveform = read_waveform(Filename)
#     waveform = waveform.reshape((SamplingPoints, round(waveform.size / SamplingPoints)))
#     # t = np.linspace(0, waveform.shape[1] / SamplingRate, waveform.shape[1])
#     t = read_waveform(time_file)
#     dt = waveform.shape[1] / SamplingRate
#
#     element_size = 6e-3  # 6 mm in meters
#     transducer_radius = element_size / 2  # a = element_size / 2
#     v_water = 1480  # Speed of sound in water (m/s)
#     v_metal = wavespeed  # Speed of sound in metal (m/s)
#     wavelength_water = v_water / frequency
#     wavelength_metal = v_metal / frequency
#     rho_water = 1000  # Density of water (kg/m^3)
#     rho_metal = 8000
#     Z_water = rho_water * v_water  # Acoustic impedance of water
#     Z_metal = rho_metal * v_metal  # Acoustic impedance of metal
#     # Wavenumbers for water and metal
#     k_water = 2 * np.pi / wavelength_water  # Wavenumber in water
#     k_metal = 2 * np.pi / wavelength_metal  # Wavenumber in metal
#
#     # Transmission and reflection coefficients
#     T_w_to_m = (2 * Z_water) / (Z_water + Z_metal)  # Transmission from water to metal
#     T_m_to_w = (2 * Z_metal) / (Z_water + Z_metal)  # Transmission from metal to water
#     R_w_to_m = (Z_metal - Z_water) / (Z_water + Z_metal)  # Reflection from water to metal
#     R_m_to_w = -(Z_water - Z_metal) / (Z_water + Z_metal)  # Reflection from metal to water
#
#     freq_shifts = np.zeros((SamplingPoints,))
#     bs_freq = np.zeros((SamplingPoints,))
#     group_vel = np.zeros((SamplingPoints,))
#     central_frequencies = np.zeros((SamplingPoints, 2))
#     backscattering_params = np.zeros((SamplingPoints,))
#
#     for row in range(0, waveform.shape[0] - 1):
#         # Find the first maximum point
#         first_max_index = np.argmax(waveform[row, :])
#         t1 = t[first_max_index]
#
#         z1 = (t[first_max_index] - 0.75 / frequency) * 1e-6 * v_water  # Distance from the probe to the metal surface through water
#         s1 = (2 * np.pi * z1) / (k_water * transducer_radius ** 2)
#         D_i1 = 1 - np.exp(-1j * (2 * np.pi / s1)) * (j0(2 * np.pi / s1) + 1j * j1(2 * np.pi / s1))
#
#         D_1st_peak = np.abs(D_i1 * D_i1)
#
#         # z2 = thickness  # Thickness of the metal (distance within the metal)
#         # s2 = (2 * np.pi * z2) / (k_metal * transducer_radius ** 2)
#         # D_i2 = 1 - np.exp(-1j * (2 * np.pi / s2)) * (j0(2 * np.pi / s2) + 1j * j1(2 * np.pi / s2))
#         #
#         # D_2nd_peak = np.abs(D_i1 * D_i2 * D_i2 * D_i1)
#         # Define the window sizes for analysis
#         window_size = round((cycles / frequency) * SamplingRate)
#         window_size1 = round((cycles / frequency) * SamplingRate * 1.0)
#         window_size2 = round((cycles / frequency) * SamplingRate * 1.0)
#
#         # First window around the first peak
#         window1 = waveform[row, first_max_index - window_size1:first_max_index + window_size2]
#         freq1, signal_FD_1 = demo_1dft(window1, dt, 30e6)
#
#         # Find the peak frequency for the first window
#         peak_index_1 = np.argmax(signal_FD_1)
#         peak_frequency_1 = freq1[peak_index_1]
#
#         # # Calculate the Full Width at Half Maximum (FWHM) for the first window
#         # half_max_1 = signal_FD_1[peak_index_1] / 2
#         # fwhm_start_1 = np.where(signal_FD_1[:peak_index_1] <= half_max_1)[0][-1]  # Left side of FWHM
#         # fwhm_end_1 = np.where(signal_FD_1[peak_index_1:] <= half_max_1)[0][0] + peak_index_1  # Right side of FWHM
#         # central_frequency_1 = (freq1[fwhm_start_1] + freq1[fwhm_end_1]) / 2
#
#         # Calculate the delay for the second window (based on material thickness and wave speed)
#         delay = round(thickness * 2 / wavespeed * SamplingRate)
#         start_index = max(0, first_max_index - window_size) + delay
#         end_index = min(len(waveform[row, :]), first_max_index + window_size) + delay
#
#         # Second window around the second peak
#         window2 = waveform[row, start_index:end_index]
#         freq2, signal_FD_2 = demo_1dft(window2, dt, 30e6)
#         second_max_index = np.argmax(window2) + start_index
#         t2 = t[second_max_index]
#
#         # Find the peak frequency for the second window
#         peak_index_2 = np.argmax(signal_FD_2)
#         peak_frequency_2 = freq2[peak_index_2]
#
#         # # Calculate the Full Width at Half Maximum (FWHM) for the second window
#         # half_max_2 = signal_FD_2[peak_index_2] / 2
#         # fwhm_start_2 = np.where(signal_FD_2[:peak_index_2] <= half_max_2)[0][-1]  # Left side of FWHM
#         # fwhm_end_2 = np.where(signal_FD_2[peak_index_2:] <= half_max_2)[0][0] + peak_index_2  # Right side of FWHM
#         # central_frequency_2 = (freq2[fwhm_start_2] + freq2[fwhm_end_2]) / 2
#
#         # # Store the central frequencies for both windows
#         # central_frequencies[row, 0] = central_frequency_1
#         # central_frequencies[row, 1] = central_frequency_2
#
#         # Calculate the frequency shift between the first and second window
#         freq_shifts[row] = peak_frequency_1 - peak_frequency_2
#         group_vel[row] = thickness * 2 / ((t2 - t1) * 1e-6)
#         # freq_shifts[row] = central_frequency_1 - central_frequency_2
#
#         # backscattering
#         first_window_end = first_max_index + window_size2
#         second_window_start = start_index
#         normalized_coef = waveform[row, first_max_index] / (np.abs(D_i1) * R_w_to_m) * T_w_to_m
#         backscatter_region = waveform[row, first_window_end:second_window_start]
#         freq3, signal_FD_3 = demo_1dft(backscatter_region, dt, 30e6)
#         freq_filter = (freq3 >= 0) & (freq3 <= 40e6)
#         if row == 0:
#
#             num_frequencies_within_range = np.sum(freq_filter)
#             bs_freq = np.zeros((SamplingPoints, num_frequencies_within_range))
#             signal_FD_3_normalized = signal_FD_3 / np.max(signal_FD_3)
#             bs_freq[row, :] = signal_FD_3_normalized[freq_filter]
#         else:
#             signal_FD_3_normalized = signal_FD_3 / np.max(signal_FD_3)
#             bs_freq[row, :] = signal_FD_3_normalized[freq_filter]
#         # backscattering_params[row] = np.sum(backscatter_region ** 2) # energy of backscattering
#         backscatter_region = backscatter_region / normalized_coef
#         backscattering_params[row] = np.sqrt(np.mean(backscatter_region ** 2)) # rms
#
#         # Return the frequency shifts for all rows
#     return freq_shifts, group_vel, backscattering_params, np.mean(bs_freq, axis=0)

def dft_analysis(input_signal, output_signal, t, dt, cycles, frequency, thickness, snames):
    font_size = 14
    SamplingRate = 1 / dt
    window_size = round((cycles / frequency) * SamplingRate)
    window_size1 = round((cycles / frequency) * SamplingRate * 0.6)
    window_size2 = round((cycles / frequency) * SamplingRate * 0.6)

    first_max_index = np.argmax(input_signal)
    first_min_index = np.argmin(input_signal)
    peak2peak1 = input_signal[first_max_index] - input_signal[first_min_index]
    window1 = input_signal[max(0, first_max_index - window_size1):first_max_index + window_size2]

    freq1, signal_FD_1 = demo_1dft(window1, dt)
    peak_index = np.argmax(signal_FD_1)
    peak_amplitude = signal_FD_1[peak_index]

    second_max_index = np.argmax(output_signal)
    second_min_index = np.argmin(output_signal)
    peak2peak2 = output_signal[second_max_index] - output_signal[second_max_index]
    window2 = output_signal[second_max_index - window_size1:min(len(output_signal), second_max_index + window_size2)]
    freq2, signal_FD_2 = demo_1dft(window2, dt)

    # backscattering
    first_window_end = first_max_index + window_size2
    backscatter_region = input_signal[first_window_end:]
    freq3, signal_FD_3 = demo_1dft(backscatter_region, dt)
    # Create subplots for time domain and frequency domain
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(10, 5))

    # Time domain plot
    ax1.plot(t*1e6, input_signal / np.max(np.abs(input_signal)), color='black', linestyle='-', linewidth=1.0, label='Input')
    ax1.plot(t*1e6, output_signal / np.max(np.abs(input_signal)), color='red', linestyle='--', linewidth=1.0, label='Output')
    ax1.set_xlabel('Time (μs)', fontsize=font_size)
    ax1.set_ylabel('Amplitude', fontsize=font_size)

    ax1.set_ylim(-1.2, 1.2)
    ax1.legend()
    # Frequency domain plot
    ax2.plot(freq1, signal_FD_1 / np.max(signal_FD_1), color='black', linestyle='-', label='Input')
    ax2.plot(freq2, signal_FD_2 / np.max(signal_FD_2), color='red', linestyle='--', label='Output')
    ax2.set_xlabel('Frequency (MHz)', fontsize=font_size)
    ax2.set_ylabel('Amplitude', fontsize=font_size)
    # ax2.set_title('Frequency Domain', fontsize=font_size)
    ax2.set_xlim(0, 40)
    ax2.set_ylim(0, 1.2)
    ax2.legend()

    fig.set_size_inches(9, 2.5)
    # cx7.xaxis.set_major_locator(MaxNLocator(5))
    ax1.spines['top'].set_linewidth(1.5)  # Effectively hiding the top spine
    ax1.spines['right'].set_linewidth(1.5)  # Effectively hiding the right spine
    ax1.spines['left'].set_linewidth(1.5)
    ax1.spines['bottom'].set_linewidth(1.5)

    ax2.spines['top'].set_linewidth(1.5)  # Effectively hiding the top spine
    ax2.spines['right'].set_linewidth(1.5)  # Effectively hiding the right spine
    ax2.spines['left'].set_linewidth(1.5)
    ax2.spines['bottom'].set_linewidth(1.5)

    plt.subplots_adjust(top=0.95, right=0.95, bottom=0.2, left=0.10)
    # fitting_eq = f"Spearman's ρ: {spearman_corr:.2f}, p-value: {p_value:.2e}"
    # cx7.set_title(fitting_eq)
    fig.savefig(snames[0], dpi=300)
    plt.close(fig)

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(10, 5))

    # Time domain plot
    ax1.plot(t*1e6, input_signal / np.max(np.abs(input_signal)), color='black', linestyle='-', linewidth=1.0)
    ax1.set_xlabel('Time (μs)', fontsize=font_size)
    ax1.set_ylabel('Amplitude', fontsize=font_size)

    window1_end_time = (first_max_index + window_size2) / SamplingRate * 1e6  # Convert to μs
    # ax1.axvline(x=window1_end_time, color='red', linestyle='--', linewidth=1.5, label='Backscatter region')
    # # Highlight the second window in the time domain with a blue dashed frame
    # window2_start_time = start_index / SamplingRate * 1e6  # Convert to μs
    # # window2_end_time = end_index / SamplingRate * 1e6  # Convert to μs
    # ax1.axvline(x=window2_start_time, color='red', linestyle='--', linewidth=1.5)
    # ax1.axvline(x=window2_end_time, color='blue', linestyle='--', linewidth=1.5)
    # ax1.set_xlim(window1_start_time, window2_end_time)
    ax1.set_ylim(-0.5, 0.5)
    # ax1.legend()
    # Frequency domain plot
    ax2.plot(freq3, signal_FD_3 / np.max(signal_FD_3), color='black', linestyle='-')
    # ax2.plot(freq2, signal_FD_2 / np.max(signal_FD_2), color='red', linestyle='--', label='2nd echo')
    ax2.set_xlabel('Frequency (MHz)', fontsize=font_size)
    ax2.set_ylabel('Amplitude', fontsize=font_size)
    # ax2.set_title('Frequency Domain', fontsize=font_size)
    ax2.set_xlim(0, 40)
    ax2.set_ylim(0, 1.2)
    # ax2.legend()

    fig.set_size_inches(9, 2.5)
    # cx7.xaxis.set_major_locator(MaxNLocator(5))
    ax1.spines['top'].set_linewidth(1.5)  # Effectively hiding the top spine
    ax1.spines['right'].set_linewidth(1.5)  # Effectively hiding the right spine
    ax1.spines['left'].set_linewidth(1.5)
    ax1.spines['bottom'].set_linewidth(1.5)

    ax2.spines['top'].set_linewidth(1.5)  # Effectively hiding the top spine
    ax2.spines['right'].set_linewidth(1.5)  # Effectively hiding the right spine
    ax2.spines['left'].set_linewidth(1.5)
    ax2.spines['bottom'].set_linewidth(1.5)

    plt.subplots_adjust(top=0.95, right=0.95, bottom=0.2, left=0.10)
    fig.savefig(snames[1], dpi=300)
    plt.close(fig)
    # Show the plot
    # plt.show()

    return

def dft_analysis2(input_signal, output_signal, t, dt, cycles, frequency, thickness):
    font_size = 14
    SamplingRate = 1 / dt

    window_size1 = round((cycles / frequency) * SamplingRate * 0.6)
    window_size2 = round((cycles / frequency) * SamplingRate * 0.6)

    first_max_index = np.argmax(input_signal)
    first_min_index = np.argmin(input_signal)
    peak2peak1 = input_signal[first_max_index] - input_signal[first_min_index]
    window1 = input_signal[max(0, first_max_index - window_size1):first_max_index + window_size2]

    freq1, signal_FD_1 = demo_1dft(window1, dt)
    peak_index = np.argmax(signal_FD_1)
    peak_amplitude = signal_FD_1[peak_index]

    second_max_index = np.argmax(output_signal)
    second_min_index = np.argmin(output_signal)
    peak2peak2 = output_signal[second_max_index] - output_signal[second_max_index]
    window2 = output_signal[second_max_index - window_size1:min(len(output_signal), second_max_index + window_size2)]
    freq2, signal_FD_2 = demo_1dft(window2, dt)

    signal_FD_2_normalized = signal_FD_2 / np.max(signal_FD_1)
    return  freq2, signal_FD_2_normalized

######################################### Pore sizes part #########################################
# Get a list of all .mat files in the folder
mat_files = [f for f in os.listdir(folder_path) if f.endswith('.mat')]

spectra_list = []
# Loop through each .mat file and load its contents
for i, mat_file in enumerate(mat_files):
    # Full path to the .mat file
    file_path = os.path.join(folder_path, mat_file)
    base_name = os.path.splitext(mat_file)[0]
    # substring = base_name[16:-12]
    # position = float(substring) if '.' in substring else int(substring)
    # Create snames based on the mat_file name
    snames = [
        os.path.join(output_dir, f"Through_trans_{base_name}.png"),
        os.path.join(output_dir, f"Backscattering_{base_name}.png")
    ]
    # Load the .mat file
    data = loadmat(file_path)
    input_signal = data["input_signal_avg"].squeeze()
    output_signal = data["output_signal_avg"].squeeze()
    t = data["time"].squeeze()
    dft_analysis(input_signal, output_signal / 2, t, dt=2e-10, cycles=5, frequency=10e6, thickness=10, snames=snames)
    freq, spectrum = dft_analysis2(input_signal, output_signal / 2, t, dt=2e-10, cycles=5, frequency=10e6, thickness=10)
    freq_limit = 15
    mask = freq <= freq_limit
    limited_spectrum = spectrum[mask]
    spectra_list.append(limited_spectrum)

max_length = max(len(s) for s in spectra_list)
spectra_matrix = np.full((len(spectra_list), max_length), np.nan)
for i, limited_spectrum in enumerate(spectra_list):
    spectra_matrix[i, :len(limited_spectrum)] = limited_spectrum

########################################### Plot ###########################################
num_segments = 15

# Determine the length of each segment
segment_size = spectra_matrix.shape[1] // num_segments

# Initialize matrix to store the summed amplitudes for each segment
summarized_matrix = np.zeros((spectra_matrix.shape[0], num_segments))

# Loop over each row in spectra_matrix
for i in range(spectra_matrix.shape[0]):
    for j in range(num_segments):
        # Calculate start and end indices for the current segment
        start_idx = j * segment_size
        end_idx = start_idx + segment_size

        # Sum the amplitudes within the current segment
        summarized_matrix[i, j] = np.sum(spectra_matrix[i, start_idx:end_idx])

font_size = 14
fig, ax = plt.subplots()
# heatmap = sns.heatmap(summarized_matrix2/np.max(summarized_matrix2), annot=False, ax=ax, cmap='viridis',
heatmap = sns.heatmap(summarized_matrix, annot=False, ax=ax, cmap='viridis',
            xticklabels=[f"{i+1}" for i in range(num_segments)],
            yticklabels=[f"{10-i}" for i in range(summarized_matrix.shape[0])],
            # cbar_kws={'label': r'Normalized $\Delta_A$'})
            cbar_kws={'label': r'Normalized $\Delta_A \cdot \overline{L}_P$'})
# ax.set_title("Stiffness inhomogeneity across Different Grain Sizes and Texture Intensity Levels")
ax.invert_yaxis()
ax.set_xlabel("Frequency (MHz)", fontsize=font_size)
ax.set_ylabel("Texture levels", fontsize=font_size)
ax.tick_params(axis='both', which='major', labelsize=font_size)
# Set the color bar label size
cbar = heatmap.collections[0].colorbar
# cbar.set_label(r'Normalized $\Delta_A$', size=font_size)
cbar.set_label(r'Spectrum Amplitude', size=font_size)
fig.set_size_inches(5, 4)
plt.subplots_adjust(top=0.95, right=0.975, bottom=0.15, left=0.115)
fig.savefig(os.path.join(output_dir, "TexturedEG_heatmap.png"), dpi=300)
frequency = freq[mask]
texture_levels = np.array([10, 9, 8, 7, 6, 5, 4, 3, 2, 1])
X, Y = np.meshgrid(frequency, texture_levels)
Z = spectra_matrix
fig = plt.figure()
ax = fig.add_subplot(111, projection='3d')
surface = ax.plot_surface(X, Y, Z, cmap='viridis', edgecolor='none')

# Customize labels and color bar
ax.set_xlabel("Frequency (MHz)", fontsize=14)
ax.set_ylabel("Texture levels", fontsize=14)
ax.set_zlabel("Amplitude", fontsize=14)
ax.tick_params(axis='both', which='major', labelsize=14)

# Color bar for spectrum density
cbar = fig.colorbar(surface, ax=ax, shrink=0.5, aspect=10)
cbar.set_label('Spectrum Amplitude', size=14)

# Adjust figure display
fig.set_size_inches(6, 4)
plt.show()

######################################### Porosity part ####################################################

# # Get a list of all .mat files in the folder
# mat_files = [f for f in os.listdir(folder_path) if f.endswith('.mat')]
#
# spectra_list2 = []
# # Loop through each .mat file and load its contents
# for i, mat_file in enumerate(mat_files):
#     # Full path to the .mat file
#     file_path = os.path.join(folder_path, mat_file)
#     base_name = os.path.splitext(mat_file)[0]
#     # substring = base_name[16:-12]
#     # position = float(substring) if '.' in substring else int(substring)
#     # Create snames based on the mat_file name
#     snames = [
#         os.path.join(folder_path, f"Through_trans_{base_name}.png"),
#         os.path.join(folder_path, f"Backscattering_{base_name}.png")
#     ]
#     # Load the .mat file
#     data = loadmat(file_path)
#     input_signal = data["input_signal_avg"].squeeze()
#     output_signal = data["output_signal_avg"].squeeze()
#     t = data["time"].squeeze()
#     # dft_analysis(input_signal, output_signal, t, dt=2e-10, cycles=5, frequency=10e6, thickness=10, snames=snames)
#     freq, spectrum = dft_analysis2(input_signal, output_signal, t, dt=2e-10, cycles=5, frequency=10e6, thickness=10)
#     freq_limit = 15
#     mask = freq <= freq_limit
#     limited_spectrum = spectrum[mask]
#     spectra_list2.append(limited_spectrum)
#
# max_length = max(len(s) for s in spectra_list2)
# spectra_matrix2 = np.full((len(spectra_list2), max_length), np.nan)
# for i, limited_spectrum in enumerate(spectra_list2):
#     spectra_matrix2[i, :len(limited_spectrum)] = limited_spectrum
#
# ########################################### Plot ###########################################
# # Number of segments
# num_segments = 15
#
# # Determine the length of each segment
# segment_size = spectra_matrix2.shape[1] // num_segments
#
# # Initialize matrix to store the summed amplitudes for each segment
# summarized_matrix2 = np.zeros((spectra_matrix2.shape[0], num_segments))
#
# # Loop over each row in spectra_matrix
# for i in range(spectra_matrix2.shape[0]):
#     for j in range(num_segments):
#         # Calculate start and end indices for the current segment
#         start_idx = j * segment_size
#         end_idx = start_idx + segment_size
#
#         # Sum the amplitudes within the current segment
#         summarized_matrix2[i, j] = np.sum(spectra_matrix2[i, start_idx:end_idx])
#
# font_size = 14
# fig, ax = plt.subplots()
# # heatmap = sns.heatmap(summarized_matrix2/np.max(summarized_matrix2), annot=False, ax=ax, cmap='viridis',
# heatmap = sns.heatmap(summarized_matrix2, annot=False, ax=ax, cmap='viridis',
#             xticklabels=[f"{i+1}" for i in range(num_segments)],
#             yticklabels=[f"{size}" for size in [0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0]],
#             # cbar_kws={'label': r'Normalized $\Delta_A$'})
#             cbar_kws={'label': r'Normalized $\Delta_A \cdot \overline{L}_P$'})
# # ax.set_title("Stiffness inhomogeneity across Different Grain Sizes and Texture Intensity Levels")
# ax.invert_yaxis()
# ax.set_xlabel("Frequency (MHz)", fontsize=font_size)
# ax.set_ylabel("Porosity (%)", fontsize=font_size)
# ax.tick_params(axis='both', which='major', labelsize=font_size)
# # Set the color bar label size
# cbar = heatmap.collections[0].colorbar
# # cbar.set_label(r'Normalized $\Delta_A$', size=font_size)
# cbar.set_label(r'Spectrum Amplitude', size=font_size)
# fig.set_size_inches(5, 4)
# plt.subplots_adjust(top=0.95, right=0.975, bottom=0.15, left=0.115)
#
# frequency = freq[mask]
# porosity = np.array([0, 0.5, 1.0, 1.5, 2.0, 2.5, 3.0, 3.5, 4.0])
# X, Y = np.meshgrid(frequency, porosity)
# Z = spectra_matrix2
# fig = plt.figure()
# ax = fig.add_subplot(111, projection='3d')
# surface = ax.plot_surface(X, Y, Z, cmap='viridis', edgecolor='none')
#
# # Customize labels and color bar
# ax.set_xlabel("Frequency (MHz)", fontsize=14)
# ax.set_ylabel("Porosity (%)", fontsize=14)
# ax.set_zlabel("Amplitude", fontsize=14)
# ax.tick_params(axis='both', which='major', labelsize=14)
#
# # Color bar for spectrum density
# cbar = fig.colorbar(surface, ax=ax, shrink=0.5, aspect=10)
# cbar.set_label('Spectrum Amplitude', size=14)
#
# # Adjust figure display
# fig.set_size_inches(6, 4)
# plt.show()
