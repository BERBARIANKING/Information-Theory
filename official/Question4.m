%% FixedLengthChordEncoding.m
% This script reads a CSV file (without header), assigns variable names manually,
% extracts the chord progression from the appropriate column, encodes the chord
% progressions using a fixed-length binary code, and computes the total size of
% the encoded data in bytes.

clear; clc;

%% STEP 1: Read the CSV File (Without Header) and Assign Variable Names
csvFilename = 'all_four_chord_songs.csv';  % Update if necessary
% Read the CSV file without treating the first row as headers:
T = readtable(csvFilename, 'ReadVariableNames', false);

% Inspect the first few rows:
disp('First few rows of the table:');
disp(T(1:5,:));

% Based on your file output, there are 7 columns.
% Manually assign names to each column. (Update these names if you know which column is which.)
% Here, we assume that the 7th column contains the chord progression.
T.Properties.VariableNames = {'ArtistSong', 'Var2', 'URL', 'Theorytab', 'View', 'Folder', 'ChordProgression'};

%% STEP 2: Verify and Extract the Chord Progression Column
if ~ismember('ChordProgression', T.Properties.VariableNames)
    error('The CSV file does not have a column named "ChordProgression". Please check your file.');
end

% Extract the chord progressions.
progressionsRaw = T.ChordProgression;
fprintf('Read %d rows from the CSV file.\n', height(T));

%% STEP 3: Build the Chord Alphabet from the Progressions
% In our CSV file, the ChordProgression field appears to have content like:
% 'thatll-be-the-day#verse,"1,4,1,4"'
% We'll extract the portion inside the quotes.
alphabetList = {};  % initialize empty cell array
for i = 1:length(progressionsRaw)
    cpRaw = progressionsRaw{i};
    % Check if cpRaw is empty (after trimming whitespace)
    if isempty(strtrim(cpRaw))
        continue;
    end
    % Use regular expression to extract the text between double quotes.
    tokens = regexp(cpRaw, '"(.*?)"', 'tokens');
    if ~isempty(tokens)
        cp = tokens{1}{1};  % This should be the chord progression, e.g., '1,4,1,4'
    else
        % If no quotes are found, assume the entire field is the progression.
        cp = cpRaw;
    end
    
    % Split the progression string by commas and trim any whitespace.
    chords = strtrim(split(cp, ','));
    % Append these chords to our list.
    alphabetList = [alphabetList; chords];
end

% Remove duplicates and sort alphabetically.
alphabet = unique(alphabetList);
nSymbols = numel(alphabet);
fprintf('Unique chords in alphabet: %d\n', nSymbols);
disp('Alphabet:');
disp(alphabet);

%% STEP 4: Create a Fixed-Length Code Mapping
% Determine how many bits are needed for each chord:
bitsPerSymbol = ceil(log2(nSymbols));
fprintf('Each chord will be represented using %d bits.\n', bitsPerSymbol);

% Create a mapping from each chord to its fixed-length binary code.
chordCode = containers.Map;
for i = 1:nSymbols
    code = dec2bin(i-1, bitsPerSymbol);
    chordCode(alphabet{i}) = code;
end

fprintf('Fixed-length code mapping:\n');
for i = 1:nSymbols
    fprintf('  %s : %s\n', alphabet{i}, chordCode(alphabet{i}));
end

%% STEP 5: Encode Each Chord Progression and Compute Total Size
totalBits = 0;
encodedProgressions = cell(length(progressionsRaw), 1);
for i = 1:length(progressionsRaw)
    cpRaw = progressionsRaw{i};
    if isempty(strtrim(cpRaw))
        continue;
    end
    % Extract the chord progression from within quotes if available.
    tokens = regexp(cpRaw, '"(.*?)"', 'tokens');
    if ~isempty(tokens)
        cp = tokens{1}{1};
    else
        cp = cpRaw;
    end
    % Split the progression into individual chords.
    chords = strtrim(split(cp, ','));
    encodedStr = '';
    for j = 1:length(chords)
        chord = chords{j};
        if chordCode.isKey(chord)
            encodedStr = [encodedStr, chordCode(chord)]; %#ok<AGROW>
        else
            warning('Chord "%s" not found in the alphabet!', chord);
        end
    end
    encodedProgressions{i} = encodedStr;
    totalBits = totalBits + length(encodedStr);
end

fprintf('\nTotal encoded length: %d bits\n', totalBits);

% Calculate the total size in bytes (rounding up)
totalBytes = ceil(totalBits / 8);
fprintf('Total size in bytes (uncompressed): %d bytes\n', totalBytes);
