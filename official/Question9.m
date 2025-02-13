%% ChordQuadAnalysis.m
% This script reads a CSV file with song chord progressions, extracts chord
% quads (four consecutive chords) from progressions with at least 4 chords,
% builds an exhaustive alphabet of these quads, and computes the joint entropy
% (in bits per chord quad) for the source.

clear; clc;

%% STEP 1: Read the CSV File and Assign Variable Names
csvFilename = 'all_four_chord_songs.csv';  % Update the filename/path if needed
% Read the CSV file without variable names.
T = readtable(csvFilename, 'ReadVariableNames', false);

% Display first few rows to inspect the data:
disp('First few rows of the table:');
disp(T(1:5,:));

% Based on the file, there are 7 columns. We assign names manually.
% Here we assume the 7th column contains the chord progression.
T.Properties.VariableNames = {'ArtistSong','Var2','URL','Theorytab','View','Folder','ChordProgression'};

fprintf('Read %d rows from the CSV file.\n', height(T));

%% STEP 2: Extract Chord Progressions
% In the CSV, the ChordProgression column may contain strings like:
% 'thatll-be-the-day#verse,"1,4,1,4"'
% We extract the text within the double quotes (i.e. the chord progression).
progressionsRaw = T.ChordProgression;
extractedProgressions = cell(height(T),1);
for i = 1:height(T)
    cpRaw = progressionsRaw{i};
    if isempty(strtrim(cpRaw))
        continue;
    end
    % Use regexp to extract the part within double quotes.
    tokens = regexp(cpRaw, '"(.*?)"', 'tokens');
    if ~isempty(tokens)
        cp = tokens{1}{1};  % For example, '1,4,1,4'
    else
        cp = cpRaw;
    end
    extractedProgressions{i} = cp;
end
% Remove empty entries:
extractedProgressions = extractedProgressions(~cellfun('isempty', extractedProgressions));
fprintf('Extracted %d chord progressions.\n', length(extractedProgressions));

%% STEP 3: Extract Chord Quads from Each Progression
% We are interested only in progressions that have at least 4 chords.
quadCounts = containers.Map('KeyType','char','ValueType','double');
totalQuads = 0;
for i = 1:length(extractedProgressions)
    cp = extractedProgressions{i};
    % Split the progression string into individual chords using comma as delimiter.
    chords = strtrim(split(cp, ','));
    n = length(chords);
    % Only process progressions with at least 4 chords.
    if n < 4
        continue;
    end
    % For a progression with n chords, there are (n - 3) quads.
    for j = 1:(n-3)
        % Form a quad by concatenating four consecutive chords with a dash.
        quadStr = sprintf('%s-%s-%s-%s', chords{j}, chords{j+1}, chords{j+2}, chords{j+3});
        % Count its occurrence.
        if quadCounts.isKey(quadStr)
            quadCounts(quadStr) = quadCounts(quadStr) + 1;
        else
            quadCounts(quadStr) = 1;
        end
        totalQuads = totalQuads + 1;
    end
end

uniqueQuads = keys(quadCounts);
nQuadSymbols = length(uniqueQuads);
fprintf('Number of symbols in the "alphabet" of chord quads: %d\n', nQuadSymbols);

%% STEP 4: Compute the Probability Distribution and Joint Entropy
% For each unique chord quad, compute its probability.
freq = zeros(nQuadSymbols,1);
for i = 1:nQuadSymbols
    freq(i) = quadCounts(uniqueQuads{i});
end
probQuads = freq / totalQuads;

% Compute the joint entropy of the chord quad source.
jointEntropy = 0;
for i = 1:nQuadSymbols
    p = probQuads(i);
    if p > 0
        jointEntropy = jointEntropy - p * log2(p);
    end
end

fprintf('Joint entropy for chord quads: %.4f bits per chord quad\n', jointEntropy);
