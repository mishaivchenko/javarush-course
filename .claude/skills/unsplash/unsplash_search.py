#!/usr/bin/env python3
"""Search Unsplash and return raw JSON."""
import urllib.request
import urllib.parse
import json
import sys

query = " ".join(sys.argv[1:]) if len(sys.argv) > 1 else "split road fork two paths diverging dark"
params = urllib.parse.urlencode({
    "query": query,
    "orientation": "landscape",
    "per_page": 1,
    "order_by": "latest",
})
url = f"https://api.unsplash.com/search/photos?{params}"
req = urllib.request.Request(url, headers={
    "Authorization": "Client-ID VM2uG3NK2BFMNqR8TP6g9KN29SuQpQxpEwQsbxLK17I",
    "Accept-Version": "v1",
})
with urllib.request.urlopen(req) as resp:
    data = json.loads(resp.read().decode())
print(json.dumps(data, indent=2))
