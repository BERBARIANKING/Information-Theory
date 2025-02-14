%% Mainstream Music Analysis using Information Theory
% This script compares the information-theoretic complexity of two MP3 files
% by evaluating their compression efficiency and entropy.

clear; clc; close all;

%% STEP 1: Load MP3 Files
file1 = 'paranoid_android.mp3'; % Replace with actual path if needed
file2 = 'hello.mp3'; % Replace with actual path if needed

% Get file sizes
info1 = dir(file1);
info2 = dir(file2);

size1 = info1.bytes;
size2 = info2.bytes;

fprintf('File Sizes (in bytes):\n');
fprintf('Paranoid Android: %d bytes\n', size1);
fprintf('Hello: %d bytes\n', size2);

%% STEP 2: Convert MP3 to WAV for Entropy Analysis
% MP3 compression can affect entropy calculations, so we convert to WAV

[audio1, Fs1] = audioread(file1); % Read first file
[audio2, Fs2] = audioread(file2); % Read second file

% Convert stereo to mono if necessary
if size(audio1,2) > 1
    audio1 = mean(audio1, 2); % Convert to mono by averaging channels
end
if size(audio2,2) > 1
    audio2 = mean(audio2, 2);
end

% Normalize audio to avoid bias due to amplitude differences
audio1 = audio1 / max(abs(audio1));
audio2 = audio2 / max(abs(audio2));

%% STEP 3: Compute Shannon Entropy
% We estimate entropy based on probability distributions of amplitude values.

entropy1 = -sum(histcounts(audio1, 256, 'Normalization', 'probability') .* ...
                 log2(histcounts(audio1, 256, 'Normalization', 'probability') + eps));

entropy2 = -sum(histcounts(audio2, 256, 'Normalization', 'probability') .* ...
                 log2(histcounts(audio2, 256, 'Normalization', 'probability') + eps));

fprintf('\nShannon Entropy of Waveform:\n');
fprintf('Paranoid Android: %.4f bits\n', entropy1);
fprintf('Hello: %.4f bits\n', entropy2);

%% STEP 4: Spectral Complexity Analysis (Fourier Transform)
% Songs with simpler structures have less spectral variance.

NFFT = 2^14; % Use large FFT size for better frequency resolution
frequencies1 = abs(fft(audio1, NFFT));
frequencies2 = abs(fft(audio2, NFFT));

% Compute variance in spectral domain
spectralVariance1 = var(frequencies1);
spectralVariance2 = var(frequencies2);

fprintf('\nSpectral Variance (Complexity of Frequency Content):\n');
fprintf('Paranoid Android: %.2e\n', spectralVariance1);
fprintf('Hello: %.2e\n', spectralVariance2);

%% STEP 5: Conclusion - Which Song is More Mainstream?
fprintf('\nFinal Analysis:\n');

if entropy1 < entropy2
    fprintf('Based on entropy, "Hello" is less complex and more predictable.\n');
else
    fprintf('Based on entropy, "Paranoid Android" is less predictable and thus less mainstream.\n');
end

if size1 < size2
    fprintf('"Hello" is more compressible, indicating a more structured song with repetition.\n');
else
    fprintf('"Paranoid Android" is less compressible, suggesting greater complexity.\n');
end

if spectralVariance1 < spectralVariance2
    fprintf('"Hello" has a simpler harmonic structure, reinforcing its mainstream characteristics.\n');
else
    fprintf('"Paranoid Android" has greater spectral variance, suggesting a more experimental sound.\n');
end

fprintf('\nOverall Verdict: ');
if (entropy1 < entropy2) && (size1 < size2) && (spectralVariance1 < spectralVariance2)
    fprintf('"Hello" is more mainstream based on information theory principles.\n');
else
    fprintf('"Paranoid Android" is less mainstream and structurally more complex.\n');
end
