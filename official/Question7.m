%% PairwiseChordAnalysis.m
% This script performs a pairwise analysis of chord progressions.
% It reads a CSV file containing chord progressions, extracts adjacent chord pairs,
% computes the frequency and probability of each pair (i.e. the alphabet of chord pairs),
% and calculates the entropy of the source (in bits per chord pair).
%
% This analysis assumes that the underlying chord source is memoryless in the sense that
% we treat each chord pair as an independent symbol. When interpreted in a Markovian
% (first-order memory) framework, the entropy calculated on chord pairs approximates the
% conditional entropy H(X_n|X_{n-1}).

clear; clc;

%% STEP 1: Read the CSV File and Extract Chord Progressions
csvFilename = 'all_four_chord_songs.csv';  % Change this if necessary
% Read the CSV file without variable names.
T = readtable(csvFilename, 'ReadVariableNames', false);

% Display the first few rows to inspect the data.
disp('First few rows of the table:');
disp(T(1:5,:));

% According to the previous output, there are 7 columns.
% Manually assign variable names. We assume the 7th column contains the chord progression.
T.Properties.VariableNames = {'ArtistSong', 'Var2', 'URL', 'Theorytab', 'View', 'Folder', 'ChordProgression'};

% Extract the chord progression column.
progressionsRaw = T.ChordProgression;
fprintf('Read %d rows from the CSV file.\n', height(T));

% In our CSV file, each progression in Var7 looks like:
% 'thatll-be-the-day#verse,"1,4,1,4"'
% We extract the part between the double quotes.
extractedProgressions = cell(height(T), 1);
for i = 1:height(T)
    cpRaw = progressionsRaw{i};
    if isempty(strtrim(cpRaw))
        continue;
    end
    tokens = regexp(cpRaw, '"(.*?)"', 'tokens');
    if ~isempty(tokens)
        cp = tokens{1}{1};  % e.g., '1,4,1,4'
    else
        cp = cpRaw;
    end
    extractedProgressions{i} = cp;
end

% Remove empty entries
extractedProgressions = extractedProgressions(~cellfun('isempty', extractedProgressions));
fprintf('Extracted %d chord progressions.\n', length(extractedProgressions));

%% STEP 2: Extract Adjacent Chord Pairs
% For each chord progression, split it into individual chords and then extract each adjacent pair.
pairCounts = containers.Map('KeyType','char','ValueType','double');
totalPairs = 0;

for i = 1:length(extractedProgressions)
    cp = extractedProgressions{i};
    chords = strtrim(split(cp, ','));
    n = length(chords);
    if n < 2
        continue;
    end
    for j = 1:(n-1)
        % Create a string representation for the pair (e.g., '1-4')
        pairStr = [chords{j} '-' chords{j+1}];
        if pairCounts.isKey(pairStr)
            pairCounts(pairStr) = pairCounts(pairStr) + 1;
        else
            pairCounts(pairStr) = 1;
        end
        totalPairs = totalPairs + 1;
    end
end

uniquePairs = keys(pairCounts);
nPairSymbols = length(uniquePairs);
fprintf('Number of symbols in the "alphabet" of chord pairs: %d\n', nPairSymbols);

%% STEP 3: Compute the Entropy of the Chord Pair Source
% For each chord pair, calculate its probability and then compute the entropy:
%   H = -sum_{pair} p(pair) * log2(p(pair))
entropyPairs = 0;
for i = 1:nPairSymbols
    pairStr = uniquePairs{i};
    count = pairCounts(pairStr);
    p = count / totalPairs;
    entropyPairs = entropyPairs - p * log2(p);
end

fprintf('Entropy of the chord pair source: %.4f bits per chord pair\n', entropyPairs);

%% STEP 4: (Optional) Interpretation in Terms of 1st-Order Memory
% In a first-order Markov model, the conditional entropy H(X_n|X_{n-1}) can be estimated by:
%   H_cond = sum_{i} p(i) * [ - sum_{j} P(j|i) log2 P(j|i) ]
% Here, if you consider each chord pair (X_{n-1}, X_n) as a symbol, the entropy computed above
% represents the uncertainty in the chord transitions.
%
% The above entropy (entropyPairs) is our measure of the average number of bits needed
% to encode each chord pair, taking into account the probabilities of transitions.
%
% If you were to encode each chord pair using a fixed-length code, you would need:
%   fixed_bits = ceil(log2(nPairSymbols)) bits per chord pair.
% For example, if nPairSymbols = 60, fixed_bits = ceil(log2(60)) = 6 bits.
%
% The compression achieved by a variable-length (optimal) code like Huffman or Shannon coding
% over a fixed-length code would then be (entropyPairs / fixed_bits).

fixedBitsPerPair = ceil(log2(nPairSymbols));
fprintf('Fixed-length code would require %d bits per chord pair.\n', fixedBitsPerPair);
fprintf('Compression ratio (entropy / fixed-length bits): %.4f\n', entropyPairs / fixedBitsPerPair);
