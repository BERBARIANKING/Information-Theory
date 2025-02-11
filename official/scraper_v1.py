import requests
import csv
import sys
import time
import itertools

# ---------------------------
# CONFIGURATION
# ---------------------------
USERNAME = "inserthere"
PASSWORD = "inserthere"

TARGET_SONG_COUNT = 5000      # We want at least 5000 unique songs
RATE_LIMIT_DELAY = 1          # Base seconds between API requests
TOP_N = 10                    # Use top N chords (by probability) to generate progressions
MAX_RETRIES = 5               # Maximum number of retries on a 429 error

BASE_URL = "https://api.hooktheory.com/v1/"

# ---------------------------
# STEP 1: Authenticate to retrieve the Bearer token (activkey)
# ---------------------------
auth_url = BASE_URL + "users/auth"
auth_data = {"username": USERNAME, "password": PASSWORD}

try:
    auth_response = requests.post(auth_url, json=auth_data)
    auth_response.raise_for_status()
except requests.RequestException as e:
    sys.exit(f"Error during authentication: {e}")

auth_result = auth_response.json()
activkey = auth_result.get("activkey")
if not activkey:
    sys.exit("Failed to retrieve activkey. Check your credentials.")

print("Authentication successful. Retrieved Bearer token.\n")

# ---------------------------
# STEP 2: Retrieve the base chords (nodes)
# ---------------------------
nodes_url = BASE_URL + "trends/nodes"
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

nodes = nodes_response.json()
print(f"Total base chords retrieved: {len(nodes)}")

# Sort chords by probability (descending) and take the top TOP_N.
chords_sorted = sorted(nodes, key=lambda c: c.get("probability", 0), reverse=True)
top_chords = chords_sorted[:TOP_N]
top_chord_ids = [chord.get("chord_ID") for chord in top_chords]

print(f"Using top {TOP_N} chords for progression generation:")
for chord in top_chords:
    print(f"  {chord.get('chord_HTML')} (ID: {chord.get('chord_ID')}, p: {chord.get('probability')})")
print()

# ---------------------------
# STEP 3: Function to fetch songs for a given chord progression with backoff and type checks
# ---------------------------
def fetch_songs_by_progression(cp, delay=RATE_LIMIT_DELAY, max_retries=MAX_RETRIES):
    """
    Fetch songs for a given chord progression (cp) using the trends/songs endpoint.
    Implements exponential backoff on 429 errors and checks that the JSON response is a list.
    
    Returns:
        List of song dictionaries.
    """
    songs_url = BASE_URL + "trends/songs"
    headers_local = {
        "Authorization": f"Bearer {activkey}",
        "Accept": "application/json",
        "Content-Type": "application/json"
    }
    
    results = []
    page = 1
    while True:
        params = {"cp": cp, "page": page}
        retries = 0
        while retries < max_retries:
            try:
                response = requests.get(songs_url, headers=headers_local, params=params)
                if response.status_code == 429:
                    # Check for Retry-After header; if not, use exponential backoff.
                    retry_after = response.headers.get("Retry-After")
                    if retry_after:
                        wait_time = int(retry_after)
                    else:
                        wait_time = 2 ** (retries + 1)
                    print(f"429 Too Many Requests for progression {cp} on page {page}. Waiting {wait_time} seconds...")
                    time.sleep(wait_time)
                    retries += 1
                    continue
                response.raise_for_status()
                break  # Successful response.
            except requests.RequestException as e:
                print(f"Error retrieving songs on page {page} for progression {cp}: {e}")
                break  # Exit retry loop on other errors.
        if retries == max_retries:
            print(f"Max retries reached for progression {cp} page {page}. Moving to next progression.")
            break
        
        # Attempt to parse the JSON.
        try:
            songs = response.json()
        except ValueError:
            print(f"Warning: Received invalid JSON for progression {cp} on page {page}.")
            break

        # Ensure the JSON is a list.
        if not isinstance(songs, list):
            print(f"Warning: Received non-list JSON for progression {cp} on page {page}.")
            break

        if not songs:
            break  # No more songs for this progression.
        
        print(f"  Progression {cp} - page {page}, {len(songs)} songs found...")
        for song in songs:
            if not isinstance(song, dict):
                print("    Unexpected song format, skipping:", song)
                continue
            print("    Title:", song.get("song", "Unknown Title"))
            # Tag the song with the progression.
            song["chord_progression"] = cp
            results.append(song)
        
        page += 1
        time.sleep(delay)
    
    return results

# ---------------------------
# STEP 4: Crawl through generated progressions to gather songs
# ---------------------------
all_songs = {}

def song_key(song):
    """Create a unique key for each song using artist, title, and section."""
    return (song.get("artist", "").strip().lower(),
            song.get("song", "").strip().lower(),
            song.get("section", "").strip().lower())

print("Starting song retrieval from generated progressions...\n")

progressions_tried = 0
# Generate all 4-length progressions from top_chord_ids using itertools.product.
for progression_tuple in itertools.product(top_chord_ids, repeat=4):
    cp = ",".join(progression_tuple)
    progressions_tried += 1
    print(f"Searching for songs with chord progression: {cp}")
    songs = fetch_songs_by_progression(cp)
    for s in songs:
        key = song_key(s)
        if key not in all_songs:
            all_songs[key] = s
    print(f"Unique songs so far: {len(all_songs)}\n")
    
    if len(all_songs) >= TARGET_SONG_COUNT:
        print("Target reached!")
        break
else:
    print("Finished trying all candidate progressions.")

print(f"\nTotal progressions tried: {progressions_tried}")
print(f"Final total unique songs retrieved: {len(all_songs)}")

# ---------------------------
# STEP 5: Save the song data to a CSV file
# ---------------------------
csv_filename = "all_four_chord_songs.csv"
fieldnames = ["artist", "song", "section", "url", "chord_progression"]

try:
    with open(csv_filename, "w", newline="", encoding="utf-8") as csvfile:
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        for song in all_songs.values():
            writer.writerow({
                "artist": song.get("artist", ""),
                "song": song.get("song", ""),
                "section": song.get("section", ""),
                "url": song.get("url", ""),
                "chord_progression": song.get("chord_progression", "")
            })
    print(f"\nSong data saved to {csv_filename}")
except IOError as e:
    sys.exit(f"Error writing to CSV file: {e}")
