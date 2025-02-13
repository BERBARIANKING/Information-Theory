%% PairwiseChordCoding.m
% This script reads a CSV file with song chord progressions, extracts adjacent
% chord pairs, builds both Shannon and Huffman codes for the chord-pair alphabet,
% encodes the progressions using these codes, and measures the overall size in bytes.
% It then compares the sizes (and thus the compression) with a fixed-length code.
%
% Assumptions:
% - The CSV file does not have a header row.
% - The chord progression is stored in column 7 in a string of the form:
%     something#section,"1,4,1,4"
%   and the code extracts the part inside the quotes.

clear; clc;

%% STEP 1: Read the CSV File and Assign Column Names
csvFilename = 'all_four_chord_songs.csv';  % Adjust if necessary
% Read CSV without headers
T = readtable(csvFilename, 'ReadVariableNames', false);
disp('First few rows of the table:');
disp(T(1:5,:));

% Based on your file structure, there are 7 columns.
% Manually assign variable names.
T.Properties.VariableNames = {'ArtistSong','Var2','URL','Theorytab','View','Folder','ChordProgression'};

%% STEP 2: Extract Chord Progressions
% Each row in the 7th column looks like:
% 'thatll-be-the-day#verse,"1,4,1,4"'
progressionsRaw = T.ChordProgression;
fprintf('Read %d rows from the CSV file.\n', height(T));

extractedProgressions = cell(height(T),1);
for i = 1:height(T)
    cpRaw = progressionsRaw{i};
    if isempty(strtrim(cpRaw))
        continue;
    end
    % Extract text between double quotes using regexp.
    tokens = regexp(cpRaw, '"(.*?)"', 'tokens');
    if ~isempty(tokens)
        cp = tokens{1}{1};  % e.g., '1,4,1,4'
    else
        cp = cpRaw;
    end
    extractedProgressions{i} = cp;
end
% Remove empty entries.
extractedProgressions = extractedProgressions(~cellfun('isempty', extractedProgressions));
fprintf('Extracted %d chord progressions.\n', length(extractedProgressions));

%% STEP 3: Extract Adjacent Chord Pairs & Count Frequencies
% For each progression, form adjacent chord pairs.
pairCounts = containers.Map('KeyType','char','ValueType','double');
totalPairs = 0;
% Also store the chord pairs for each progression (for later encoding)
progressionPairs = cell(length(extractedProgressions),1);

for i = 1:length(extractedProgressions)
    cp = extractedProgressions{i};
    chords = strtrim(split(cp, ','));
    n = length(chords);
    if n < 2
        progressionPairs{i} = {};
        continue;
    end
    pairs = cell(n-1,1);
    for j = 1:(n-1)
        pairStr = [chords{j} '-' chords{j+1}];
        pairs{j} = pairStr;
        if pairCounts.isKey(pairStr)
            pairCounts(pairStr) = pairCounts(pairStr) + 1;
        else
            pairCounts(pairStr) = 1;
        end
        totalPairs = totalPairs + 1;
    end
    progressionPairs{i} = pairs;
end

uniquePairs = keys(pairCounts);
nPairSymbols = length(uniquePairs);
fprintf('Number of symbols in the "alphabet" of chord pairs: %d\n', nPairSymbols);

%% STEP 4: Compute Probability Distribution for Chord Pairs
freq = zeros(nPairSymbols,1);
for i = 1:nPairSymbols
    freq(i) = pairCounts(uniquePairs{i});
end
probPairs = freq / totalPairs;

%% STEP 5: Build Shannon Code for Chord Pairs
% Shannon coding: sort symbols by descending probability, then
% for each symbol i, let L = ceil(-log2(p_i)) and assign code = first L bits
% of binary expansion of cumulative probability F(i) = sum_{j=1}^{i-1} p(j).
[probSorted, idx] = sort(probPairs, 'descend');
alphabetShannon = uniquePairs(idx);
cumProb = cumsum(probSorted) - probSorted;
shannonCodes = cell(nPairSymbols,1);
shannonLengths = zeros(nPairSymbols,1);
for i = 1:nPairSymbols
    p_i = probSorted(i);
    L = ceil(-log2(p_i));
    shannonLengths(i) = L;
    % Codeword is the binary representation of floor(F(i)*2^L) padded to L bits.
    value = floor(cumProb(i) * 2^L);
    codeStr = dec2bin(value, L);
    shannonCodes{i} = codeStr;
end

% Create mapping: chord pair -> Shannon code
shannonMap = containers.Map;
fprintf('\nShannon Code Mapping for chord pairs:\n');
for i = 1:nPairSymbols
    shannonMap(alphabetShannon{i}) = shannonCodes{i};
    fprintf('  %s : %s (p=%.4f, L=%d)\n', alphabetShannon{i}, shannonCodes{i}, probSorted(i), shannonLengths(i));
end

%% STEP 6: Build Huffman Dictionary for Chord Pairs
% Use MATLAB's huffmandict function (requires Communications Toolbox)
[dict, avglen] = huffmandict(uniquePairs, probPairs);
% Create mapping: chord pair -> Huffman code (as a string)
huffMap = containers.Map;
fprintf('\nHuffman Code Mapping for chord pairs:\n');
for i = 1:size(dict,1)
    symbol = dict{i,1};
    codeVec = dict{i,2};  % numeric vector (e.g., [0 1 1])
    codeStr = num2str(codeVec);
    codeStr = regexprep(codeStr, '\s+', '');
    huffMap(symbol) = codeStr;
    % Find probability and length
    idxSym = find(strcmp(uniquePairs, symbol));
    fprintf('  %s : %s (p=%.4f, L=%d)\n', symbol, codeStr, probPairs(idxSym), length(codeStr));
end

%% STEP 7: Encode All Progressions Using Shannon and Huffman Codes
totalBitsShannon = 0;
totalBitsHuff = 0;
for i = 1:length(progressionPairs)
    pairs = progressionPairs{i};
    if isempty(pairs)
        continue;
    end
    encShannon = '';
    encHuff = '';
    for j = 1:length(pairs)
        pairStr = pairs{j};
        if shannonMap.isKey(pairStr)
            encShannon = [encShannon, shannonMap(pairStr)]; %#ok<AGROW>
        else
            warning('Pair "%s" not found in Shannon map!', pairStr);
        end
        if huffMap.isKey(pairStr)
            encHuff = [encHuff, huffMap(pairStr)]; %#ok<AGROW>
        else
            warning('Pair "%s" not found in Huffman map!', pairStr);
        end
    end
    totalBitsShannon = totalBitsShannon + length(encShannon);
    totalBitsHuff = totalBitsHuff + length(encHuff);
end

totalBytesShannon = ceil(totalBitsShannon / 8);
totalBytesHuff = ceil(totalBitsHuff / 8);

fprintf('\nTotal encoded length with Shannon coding: %d bits\n', totalBitsShannon);
fprintf('Total size in bytes with Shannon coding: %d bytes\n', totalBytesShannon);

fprintf('\nTotal encoded length with Huffman coding: %d bits\n', totalBitsHuff);
fprintf('Total size in bytes with Huffman coding: %d bytes\n', totalBytesHuff);

%% STEP 8: Compare with Fixed-Length Coding
% For fixed-length coding, each chord pair would use:
fixedBitsPerPair = ceil(log2(nPairSymbols));
fixedTotalBits = totalPairs * fixedBitsPerPair;
fixedTotalBytes = ceil(fixedTotalBits / 8);

fprintf('\nFixed-length coding size: %d bytes (each chord pair uses %d bits)\n', fixedTotalBytes, fixedBitsPerPair);

% Compute compression ratios:
compressionRatioShannon = totalBytesShannon / fixedTotalBytes;
compressionRatioHuff = totalBytesHuff / fixedTotalBytes;
fprintf('Compression ratio (Shannon vs. fixed-length): %.4f\n', compressionRatioShannon);
fprintf('Compression ratio (Huffman vs. fixed-length): %.4f\n', compressionRatioHuff);

%% STEP 9: Comments on the Results
% The output shows the total size (in bytes) for encoding chord pairs using:
%  - Shannon coding (variable-length based on cumulative probabilities)
%  - Huffman coding (optimal prefix code)
% It then compares these sizes with the fixed-length code size.
% A compression ratio less than 1 indicates compression relative to fixed-length encoding.
% The "situation" (i.e., average bits per chord pair) may change compared to single chord analysis.
