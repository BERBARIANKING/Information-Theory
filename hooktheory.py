import requests

# Your Hooktheory website credentials
USERNAME = "your_actual_username"
PASSWORD = "your_actual_password"

# Step 1: Get Bearer Token (activkey)
auth_url = "https://api.hooktheory.com/v1/users/auth"
headers = {
    "Accept": "application/json",
    "Content-Type": "application/json"
}

response = requests.post(
    auth_url,
    headers=headers,
    json={
        "username": USERNAME,
        "password": PASSWORD
    }
)

if response.status_code != 200:
    print(f"Authentication failed: {response.text}")
    exit()

auth_data = response.json()
activkey = auth_data["activkey"]
print(f"Obtained activkey: {activkey}")

# Step 2: Make authenticated request
chords_url = "https://api.hooktheory.com/v1/chords"  # Example endpoint
headers = {
    "Accept": "application/json",
    "Authorization": f"Bearer {activkey}"
}

try:
    response = requests.get(chords_url, headers=headers)
    response.raise_for_status()
    
    # Process the chord data
    chord_data = response.json()
    print("Chord progressions:", chord_data)

except requests.exceptions.RequestException as e:
    print(f"API request failed: {e}")
