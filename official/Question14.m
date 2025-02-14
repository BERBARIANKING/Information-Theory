clc; clear; close all;

%% Step 1: System Parameters
data_length = 11000;  % Number of information bits (multiples of 11)
transmitted_bits = randi([0 1], 1, data_length);  % Random binary data
n = 15; % Hamming codeword length
k = 11; % Information bit length
SNR_dB = 7; % Signal-to-noise ratio
SNR_linear = 10^(SNR_dB/10); % Convert dB to linear scale
noise_variance = 1/SNR_linear; % Noise variance
symbol_rate = 1e6; % 1 Msymbol/sec for BPSK

%% Step 2: Hamming (15,11) Encoding
[H, G] = hammgen(n-k); % Generate Hamming parity-check and generator matrices
data_blocks = reshape(transmitted_bits, k, [])';
encoded_blocks = mod(data_blocks * G, 2);  % Encode each 11-bit block
encoded_bits = reshape(encoded_blocks', 1, []); % Serialize data

%% Step 3: Transmission with AWGN Channel
bpsk_signal = 2*encoded_bits - 1; % BPSK mapping (0 → -1, 1 → 1)
noise = sqrt(noise_variance) * randn(1, length(bpsk_signal)); % Generate noise
received_signal = bpsk_signal + noise; % Add noise to the signal

%% Step 4: Hard Decision Demodulation
received_bits = received_signal > 0; % Decision: > 0 → 1, <= 0 → 0

%% Step 5: Reshape Received Data & Perform Hamming Decoding
received_blocks = reshape(received_bits, n, [])';
syndrome = mod(received_blocks * H', 2);
error_positions = bi2de(syndrome, 'left-msb') + 1;

% Retransmission simulation: Count the number of retransmitted blocks
retransmissions = 0;
for i = 1:size(received_blocks, 1)
    if error_positions(i) > 1 && error_positions(i) <= n
        retransmissions = retransmissions + 1; % Count retransmissions
        received_blocks(i, error_positions(i)) = ~received_blocks(i, error_positions(i)); % Correct error
    end
end

decoded_bits = received_blocks(:, 1:k);
decoded_bits = reshape(decoded_bits', 1, []);

%% Step 6: Error and Transmission Rate Analysis
bit_errors = sum(transmitted_bits ~= decoded_bits); % Count errors
bit_error_rate = bit_errors / data_length; % Compute BER

% Compute transmission rate considering retransmissions
retransmission_factor = (size(received_blocks, 1) + retransmissions) / size(received_blocks, 1);
achievable_rate = (k/n) * symbol_rate / retransmission_factor; % Adjusted for retransmissions

%% Step 7: Compute Theoretical Channel Capacity
bandwidth = 1e6; % 1 MHz
channel_capacity = bandwidth * log2(1 + SNR_linear); % Shannon-Hartley Capacity

%% Step 8: Display Results
fprintf('Total transmitted bits: %d\n', data_length);
fprintf('Total bit errors after Hamming correction: %d\n', bit_errors);
fprintf('Bit Error Rate (BER) after correction: %.6f\n', bit_error_rate);
fprintf('Retransmitted blocks: %d\n', retransmissions);
fprintf('Achievable Information Rate: %.2f Mbps\n', achievable_rate / 1e6);
fprintf('Theoretical Channel Capacity: %.2f Mbps\n', channel_capacity / 1e6);
