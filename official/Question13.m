clc; clear; close all;

%% Step 1: Generate Binary Data
data_length = 11000;  % Number of information bits (multiples of 11)
transmitted_bits = randi([0 1], 1, data_length);  % Random binary sequence

%% Step 2: Hamming (15,11) Encoding
n = 15; % Codeword length
k = 11; % Information bit length

% Create Hamming (15,11) Generator and Parity Check Matrices
[H, G] = hammgen(n-k);  % Generate parity-check (H) and generator (G) matrices

% Reshape data into blocks of 11 bits for encoding
data_blocks = reshape(transmitted_bits, k, [])';

% Encode using Hamming (15,11)
encoded_blocks = mod(data_blocks * G, 2);  % Matrix multiplication in GF(2)
encoded_bits = reshape(encoded_blocks', 1, []);  % Convert to a serial bitstream

%% Step 3: BPSK Modulation
bpsk_signal = 2*encoded_bits - 1;  % Convert 0 → -1, 1 → 1

%% Step 4: Define Channel Parameters and Add Noise
SNR_dB = 7;  % Given Signal-to-Noise Ratio in dB
SNR_linear = 10^(SNR_dB/10);  % Convert dB to linear scale
noise_variance = 1/SNR_linear;  % Noise variance calculation
noise = sqrt(noise_variance) * randn(1, length(bpsk_signal));  % AWGN noise
received_signal = bpsk_signal + noise;  % Add noise to BPSK signal

%% Step 5: Hard Decision Demodulation
received_bits = received_signal > 0;  % Decision rule: If > 0 → 1, else → 0

%% Step 6: Hamming (15,11) Decoding
% Reshape received bits into 15-bit codewords
received_blocks = reshape(received_bits, n, [])';

% Perform Syndrome Decoding
syndrome = mod(received_blocks * H', 2);
error_positions = bi2de(syndrome, 'left-msb') + 1;  % Convert syndrome to decimal

% Correct Errors
for i = 1:size(received_blocks, 1)
    if error_positions(i) > 1 && error_positions(i) <= n
        received_blocks(i, error_positions(i)) = ~received_blocks(i, error_positions(i)); % Flip bit
    end
end

% Extract information bits from corrected codewords
decoded_bits = received_blocks(:, 1:k);
decoded_bits = reshape(decoded_bits', 1, []);

%% Step 7: Error Analysis
bit_errors = sum(transmitted_bits ~= decoded_bits);  % Count errors
bit_error_rate = bit_errors / data_length;  % Compute BER

%% Step 8: Display Results
fprintf('Total transmitted bits: %d\n', data_length);
fprintf('Total bit errors after Hamming decoding: %d\n', bit_errors);
fprintf('Bit Error Rate (BER) after Hamming correction: %.6f\n', bit_error_rate);
