clc; clear; close all;

%% Step 1: Generate Huffman-Coded Binary Data
% Simulate a Huffman-coded bitstream (random binary sequence for demonstration)
data_length = 10000;  % Number of bits to transmit
transmitted_bits = randi([0 1], 1, data_length);  % Random binary sequence

%% Step 2: BPSK Modulation
bpsk_signal = 2*transmitted_bits - 1;  % Convert 0 → -1, 1 → 1

%% Step 3: Define Channel Parameters
SNR_dB = 7;  % Given Signal-to-Noise Ratio in dB
SNR_linear = 10^(SNR_dB/10);  % Convert dB to linear scale
noise_variance = 1/SNR_linear;  % Noise variance calculation
noise = sqrt(noise_variance) * randn(1, data_length);  % AWGN noise

%% Step 4: Transmit Through Noisy Channel
received_signal = bpsk_signal + noise;  % Add noise to BPSK signal

%% Step 5: Hard Decision Detection at Receiver
received_bits = received_signal > 0;  % Decision rule: If > 0 → 1, else → 0

%% Step 6: Error Analysis
bit_errors = sum(transmitted_bits ~= received_bits);  % Count errors
bit_error_rate = bit_errors / data_length;  % Compute BER

%% Step 7: Display Results
fprintf('Total transmitted bits: %d\n', data_length);
fprintf('Total bit errors: %d\n', bit_errors);
fprintf('Bit Error Rate (BER): %.6f\n', bit_error_rate);

%% Step 8: Plot Received Signal Histogram
figure;
histogram(received_signal, 50);
title('Histogram of Received BPSK Signal with AWGN');
xlabel('Received Signal Amplitude');
ylabel('Frequency');
grid on;
