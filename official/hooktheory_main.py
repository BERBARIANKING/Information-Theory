import requests
import time

class HooktheoryAPI:
    def __init__(self, username, password):
        self.base_url = "https://api.hooktheory.com/v1/"
        self.headers = {
            "Accept": "application/json",
            "Content-Type": "application/json"
        }
        self.activkey = self._authenticate(username, password)
        self.headers["Authorization"] = f"Bearer {self.activkey}"
        
    def _authenticate(self, username, password):
        """Get activkey using username/password"""
        auth_url = f"{self.base_url}users/auth"
        response = requests.post(
            auth_url,
            headers=self.headers,
            json={"username": username, "password": password}
        )
        response.raise_for_status()
        return response.json()["activkey"]

    def get_next_chords(self, progression=None):
        """Get chord probabilities for a progression (child path)"""
        url = f"{self.base_url}trends/nodes"
        params = {"cp": progression} if progression else None
        
        response = requests.get(url, headers=self.headers, params=params)
        self._handle_rate_limits(response)
        response.raise_for_status()
        return response.json()

    def get_songs_with_progression(self, progression, page=1):
        """Get songs containing a specific chord progression"""
        url = f"{self.base_url}trends/songs"
        params = {"cp": progression, "page": page}
        
        response = requests.get(url, headers=self.headers, params=params)
        self._handle_rate_limits(response)
        response.raise_for_status()
        return response.json()

    def _handle_rate_limits(self, response):
        """Handle API rate limiting"""
        remaining = int(response.headers.get("X-Rate-Limit-Remaining", 10))
        reset = int(response.headers.get("X-Rate-Limit-Reset", 10))
        
        if remaining <= 2:
            print(f"⚠️ Approaching rate limit - waiting {reset} seconds")
            time.sleep(reset + 1)

# Usage Example
if __name__ == "__main__":
    # Initialize with your credentials
    api = HooktheoryAPI(username="yourapihere", password="yourapihere")
    
    # Example 1: Get next chord probabilities for IV → I progression
    progression = "4,1"
    chords = api.get_next_chords(progression)
    print(f"\nNext chords after {progression}:")
    for chord in chords[:3]:  # Show top 3 probabilities
        print(f"{chord['chord_HTML']}: {chord['probability']*100:.1f}%")
    
    # Example 2: Get songs containing IV → I progression
    songs = api.get_songs_with_progression(progression)
    print("\nSongs with this progression:")
    for song in songs[:3]:  # Show first 3 results
        print(f"{song['artist']} - {song['song']} ({song['section']})")
