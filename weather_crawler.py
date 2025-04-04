# weather_crawler.py

import requests
import datetime
import pymongo
import os
from datetime import datetime, timezone


# MongoDB connection
mongo_url = os.environ.get("MONGO_URL", "mongodb://localhost:27017/")
client = pymongo.MongoClient(mongo_url)
print("Connected!")
db = client["weather"]
collection = db["data"]

def get_wttr():
    try:
        res = requests.get("https://wttr.in/London?format=3")
        return {"wttr_in": res.text}
    except Exception as e:
        return {"wttr_in": f"Error: {e}"}

def get_open_meteo():
    try:
        url = "https://api.open-meteo.com/v1/forecast?latitude=52.52&longitude=13.41&current_weather=true"
        res = requests.get(url).json()
        return {"open_meteo": res.get("current_weather", {})}
    except Exception as e:
        return {"open_meteo": f"Error: {e}"}

def get_weatherapi():
    try:
        api_key = os.environ["WEATHERAPI_KEY"]
        url = f"http://api.weatherapi.com/v1/current.json?key={api_key}&q=London"
        res = requests.get(url).json()
        return {"weatherapi": res.get("current", {})}
    except Exception as e:
        return {"weatherapi": f"Error: {e}"}

def main():
    timestamp = datetime.now(timezone.utc).isoformat()
    data = {
        "timestamp": timestamp,
        **get_wttr(),
        **get_open_meteo(),
        **get_weatherapi()
    }
    collection.insert_one(data)
    print("Weather data inserted at", timestamp)


if __name__ == "__main__":
    main()
