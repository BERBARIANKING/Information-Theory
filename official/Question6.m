%% HuffmanChordEncoding.m
% This script reads a CSV file (without header) that contains chord progressions,
% extracts the chord progression from the 7th column, builds a Huffman dictionary
% for the chord alphabet (assuming a memoryless source), encodes each progression,
% and then computes the total encoded size in bytes.
% It finally compares the Huffman-coded size with a fixed-length coding (4 bits per chord).

clear; clc;

%% STEP 1: Read the CSV File and Assign Variable Names
csvFilename = 'all_four_chord_songs.csv';  % Update if necessary
% Read the CSV file without variable names:
T = readtable(csvFilename, 'ReadVariableNames', false);

% Display the first few rows to check the data:
disp('First few rows of the table:');
disp(T(1:5,:));

% According to your file, there are 7 columns.
% Manually assign names. We assume the 7th column contains the chord progression.
T.Properties.VariableNames = {'ArtistSong', 'Var2', 'URL', 'Theorytab', 'View', 'Folder', 'ChordProgression'};

%% STEP 2: Extract the Chord Progressions
% In our file, the ChordProgression field has data like:
% 'thatll-be-the-day#verse,"1,4,1,4"'
% We extract the text inside the quotes.
progressionsRaw = T.ChordProgression;
fprintf('Read %d rows from the CSV file.\n', height(T));

extractedProgressions = cell(height(T), 1);
for i = 1:height(T)
    cpRaw = progressionsRaw{i};
    if isempty(strtrim(cpRaw))
        continue;
    end
    % Extract text within double quotes using regexp.
    tokens = regexp(cpRaw, '"(.*?)"', 'tokens');
    if ~isempty(tokens)
        cp = tokens{1}{1};  % e.g., '1,4,1,4'
    else
        cp = cpRaw;
    end
    extractedProgressions{i} = cp;
end

%% STEP 3: Build the Chord Alphabet & Count Frequencies
% Process each progression to collect all chords and count frequency.
symbolCounts = containers.Map;
totalSymbols = 0;
for i = 1:length(extractedProgressions)
    cp = extractedProgressions{i};
    if isempty(cp)
        continue;
    end
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

% Compute relative frequencies (probabilities) for each symbol.
freq = zeros(nSymbols,1);
for i = 1:nSymbols
    freq(i) = symbolCounts(alphabet{i});
end
prob = freq / totalSymbols;

%% STEP 4: Build Huffman Dictionary
% Use MATLAB's built-in huffmandict function.
% huffmandict expects symbols as a cell array and probabilities as a vector.
[dict, avglen] = huffmandict(alphabet, prob);

% Create a mapping from chord symbol to a binary string.
huffMap = containers.Map;
fprintf('\nHuffman Code Mapping:\n');
for i = 1:size(dict,1)
    symbol = dict{i,1};
    codeVec = dict{i,2};  % This is a numeric vector (e.g., [0 1 1])
    % Convert numeric vector to string (remove spaces).
    codeStr = num2str(codeVec);
    codeStr = regexprep(codeStr, '\s+', '');
    huffMap(symbol) = codeStr;
    % Find corresponding probability and length:
    idx = find(strcmp(alphabet, symbol));
    fprintf('  %s : %s (p=%.4f, L=%d)\n', symbol, codeStr, prob(idx), length(codeStr));
end

%% STEP 5: Encode Each Chord Progression Using Huffman Codes
totalBitsHuff = 0;
encodedProgressionsHuff = cell(length(extractedProgressions), 1);
for i = 1:length(extractedProgressions)
    cp = extractedProgressions{i};
    if isempty(cp)
        continue;
    end
    chords = strtrim(split(cp, ','));
    encodedStr = '';
    for j = 1:length(chords)
        chord = chords{j};
        if huffMap.isKey(chord)
            encodedStr = [encodedStr, huffMap(chord)]; %#ok<AGROW>
        else
            warning('Chord "%s" not found in Huffman map!', chord);
        end
    end
    encodedProgressionsHuff{i} = encodedStr;
    totalBitsHuff = totalBitsHuff + length(encodedStr);
end

fprintf('\nTotal encoded length with Huffman coding: %d bits\n', totalBitsHuff);
totalBytesHuff = ceil(totalBitsHuff / 8);
fprintf('Total size in bytes with Huffman coding: %d bytes\n', totalBytesHuff);

%% STEP 6: Compare with Fixed-Length Coding
% For fixed-length coding: with 10 symbols, each chord uses 4 bits.
fixedTotalBits = totalSymbols * 4;
fixedTotalBytes = ceil(fixedTotalBits / 8);
fprintf('\nFixed-length coding size: %d bytes\n', fixedTotalBytes);

compressionRatio = totalBytesHuff / fixedTotalBytes;
fprintf('Compression ratio (Huffman vs. fixed-length): %.4f\n', compressionRatio);
