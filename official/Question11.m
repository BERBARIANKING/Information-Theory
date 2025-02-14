% Define the tempo and duration
tempo = 120; % beats per minute
beatsPerChord = 4; % each chord lasts for 4 beats
fs = 44100; % sampling frequency

% Define the chord progression in terms of MIDI note numbers
C_major = [60, 64, 67]; % C, E, G
G_major = [67, 71, 74]; % G, B, D
A_minor = [69, 72, 76]; % A, C, E
F_major = [65, 69, 72]; % F, A, C

% Combine the chords into a progression
chordProgression = {C_major, G_major, A_minor, F_major};

% Function to generate a chord sound
generateChord = @(chord, duration) sum(sin(2 * pi * (440 * 2.^((chord - 69)/12))' * (0:1/fs:duration-1/fs)), 1);

% Generate the audio signal for the progression
audio = [];
for i = 1:length(chordProgression)
    chord = chordProgression{i};
    duration = beatsPerChord * (60 / tempo);
    audio = [audio, generateChord(chord, duration)];
end

% Normalize the audio signal
audio = audio / max(abs(audio));

% Play the audio
sound(audio, fs);
