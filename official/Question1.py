import requests
import math
import sys

# --- CONFIGURATION ---
# Replace these with your actual Hooktheory username and password
USERNAME = "inserthere"
PASSWORD = "inserthere"

# --- STEP 1: Authenticate to retrieve the Bearer token (activkey) ---
auth_url = "https://api.hooktheory.com/v1/users/auth"
auth_data = {
    "username": USERNAME,
    "password": PASSWORD
}

try:
    auth_response = requests.post(auth_url, json=auth_data)
    auth_response.raise_for_status()  # Raises an HTTPError if the status is 4xx, 5xx
except requests.RequestException as e:
    sys.exit(f"Error during authentication: {e}")

auth_result = auth_response.json()
activkey = auth_result.get("activkey")
if not activkey:
    sys.exit("Failed to retrieve activkey. Check your credentials.")

print("Authentication successful. Retrieved Bearer token.")

# --- STEP 2: Retrieve the base chords using the trends/nodes endpoint ---
nodes_url = "https://api.hooktheory.com/v1/trends/nodes"
headers = {
    "Authorization": f"Bearer {activkey}",
    "Accept": "application/json",
    "Content-Type": "application/json"
}

try:
    nodes_response = requests.get(nodes_url, headers=headers)
    nodes_response.raise_for_status()
except requests.RequestException as e:
    sys.exit(f"Error retrieving base chords: {e}")

chords = nodes_response.json()

# --- STEP 3: Count the base chords and isolate their probabilities ---
total_chords = len(chords)
print(f"\nTotal number of base chords: {total_chords}")

# We'll use 'chord_HTML' as our chord name.
# Create a dictionary mapping chord names to their probabilities.
chord_probabilities = {}
for chord in chords:
    # Use chord_HTML if available; otherwise, fall back to chord_ID
    chord_name = chord.get("chord_HTML") or f"Chord {chord.get('chord_ID')}"
    probability = chord.get("probability", 0)
    chord_probabilities[chord_name] = probability

print("\nChord Probabilities:")
for chord_name, probability in chord_probabilities.items():
    print(f"  {chord_name}: {probability}")

# --- STEP 4: Calculate the entropy of the chord source ---
# Entropy H = -Σ p(x) * log2(p(x))
entropy = 0
for p in chord_probabilities.values():
    if p > 0:
        entropy += p * math.log2(p)
entropy = -entropy

print(f"\nEntropy of the chord source: {entropy:.4f} bits")
