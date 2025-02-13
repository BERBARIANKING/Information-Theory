%% ShannonChordEncoding.m
% This script reads a CSV file with song chord progressions, computes the
% Shannon code for the chord alphabet (assuming a memoryless source), encodes
% each progression using this variable-length code, and measures the total
% size of the encoded data in bytes. It also compares the result with a
% fixed-length coding scheme.

clear; clc;

%% STEP 1: Read the CSV File (Without Header) and Assign Column Names
csvFilename = 'all_four_chord_songs.csv';  % Update as needed
% Read the CSV file without variable names.
T = readtable(csvFilename, 'ReadVariableNames', false);

% Display the first few rows to verify data:
disp('First few rows of the table:');
disp(T(1:5,:));

% Based on your file output, there are 7 columns.
% Manually assign names to columns. Here we assume column 7 contains the chord progression.
T.Properties.VariableNames = {'ArtistSong', 'Var2', 'URL', 'Theorytab', 'View', 'Folder', 'ChordProgression'};

%% STEP 2: Extract the Chord Progressions
% The ChordProgression column appears to have data like:
% 'thatll-be-the-day#verse,"1,4,1,4"'
% We extract the part inside the double quotes.
progressionsRaw = T.ChordProgression;
fprintf('Read %d rows from the CSV file.\n', height(T));

% We'll store the extracted progression strings here.
extractedProgressions = cell(height(T), 1);
for i = 1:height(T)
    cpRaw = progressionsRaw{i};
    if isempty(strtrim(cpRaw))
        continue;
    end
    % Use regexp to extract the part between double quotes.
    tokens = regexp(cpRaw, '"(.*?)"', 'tokens');
    if ~isempty(tokens)
        cp = tokens{1}{1};  % e.g., '1,4,1,4'
    else
        cp = cpRaw;
    end
    extractedProgressions{i} = cp;
end

%% STEP 3: Build the Chord Alphabet & Count Frequencies
% We process each extracted progression to count the occurrences of each chord.
symbolCounts = containers.Map;
totalSymbols = 0;

for i = 1:height(T)
    cp = extractedProgressions{i};
    if isempty(cp)
        continue;
    end
    % Split by commas:
    chords = strtrim(split(cp, ','));
    for j = 1:length(chords)
        chord = chords{j};
        if symbolCounts.isKey(chord)
            symbolCounts(chord) = symbolCounts(chord) + 1;
        else
            symbolCounts(chord) = 1;
        end
        totalSymbols = totalSymbols + 1;
    end
end

alphabet = keys(symbolCounts);
nSymbols = numel(alphabet);
fprintf('Unique chords in alphabet: %d\n', nSymbols);
disp('Alphabet:');
disp(alphabet);

% Compute relative frequencies (probabilities)
freq = zeros(nSymbols,1);
for i = 1:nSymbols
    freq(i) = symbolCounts(alphabet{i});
end
prob = freq / totalSymbols;

%% STEP 4: Construct Shannon Codes for Each Chord
% Sort the alphabet in descending order of probability.
[probSorted, idx] = sort(prob, 'descend');
alphabetSorted = alphabet(idx);

% Compute cumulative probabilities: for each symbol i, F(i) = sum_{j=1}^{i-1} p(j)
cumProb = cumsum(probSorted) - probSorted;

shannonCodes = cell(nSymbols, 1);
codeLengths = zeros(nSymbols, 1);
for i = 1:nSymbols
    p_i = probSorted(i);
    L = ceil(-log2(p_i));  % Code length for this symbol
    codeLengths(i) = L;
    % The code is given by the first L bits of the binary expansion of F(i).
    % That is, we compute floor(F(i) * 2^L) and convert to a binary string.
    value = floor(cumProb(i) * 2^L);
    codeStr = dec2bin(value, L);
    shannonCodes{i} = codeStr;
end

% Create a mapping from chord symbol to Shannon code.
shannonMap = containers.Map;
fprintf('Shannon Code mapping:\n');
for i = 1:nSymbols
    shannonMap(alphabetSorted{i}) = shannonCodes{i};
    fprintf('  %s : %s (p=%.4f, L=%d)\n', alphabetSorted{i}, shannonCodes{i}, probSorted(i), codeLengths(i));
end

%% STEP 5: Encode Each Chord Progression with Shannon Codes
totalBitsShannon = 0;
encodedProgressionsShannon = cell(height(T), 1);
for i = 1:height(T)
    cp = extractedProgressions{i};
    if isempty(cp)
        continue;
    end
    chords = strtrim(split(cp, ','));
    encodedStr = '';
    for j = 1:length(chords)
        chord = chords{j};
        if shannonMap.isKey(chord)
            encodedStr = [encodedStr, shannonMap(chord)]; %#ok<AGROW>
        else
            warning('Chord "%s" not found in Shannon map!', chord);
        end
    end
    encodedProgressionsShannon{i} = encodedStr;
    totalBitsShannon = totalBitsShannon + length(encodedStr);
end

fprintf('\nTotal encoded length with Shannon coding: %d bits\n', totalBitsShannon);
totalBytesShannon = ceil(totalBitsShannon / 8);
fprintf('Total size in bytes with Shannon coding: %d bytes\n', totalBytesShannon);

%% STEP 6: Compare with Fixed-Length Coding
% In our previous fixed-length code, each chord was represented with 4 bits (since we had 10 chords).
% For the entire dataset, the fixed-length total bits would be:
fixedTotalBits = totalSymbols * 4;
fixedTotalBytes = ceil(fixedTotalBits / 8);
fprintf('\nFixed-length coding size: %d bytes\n', fixedTotalBytes);

% Compute the compression ratio:
compressionRatio = totalBytesShannon / fixedTotalBytes;
fprintf('Compression ratio (Shannon vs. fixed-length): %.4f\n', compressionRatio);
