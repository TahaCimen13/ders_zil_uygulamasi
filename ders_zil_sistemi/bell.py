import schedule
import os
import time
import json
from datetime import datetime

def ring_bell():
    print(f"🔔 {datetime.now().strftime('%A %H:%M:%S')} - Bell ringing!")
    os.system("afplay assets/sounds/bell.mp3") 

# Load schedule from JSON file
with open("time.json", "r") as file:
    schedule_data = json.load(file)

# Map JSON to schedule functions
for day, times in schedule_data.items():
    for t in times:
        if day == "monday":
            schedule.every().monday.at(t).do(ring_bell)
        elif day == "tuesday":
            schedule.every().tuesday.at(t).do(ring_bell)
        elif day == "wednesday":
            schedule.every().wednesday.at(t).do(ring_bell)
        elif day == "thursday":
            schedule.every().thursday.at(t).do(ring_bell)
        elif day == "friday":
            schedule.every().friday.at(t).do(ring_bell)
        elif day == "saturday":
            schedule.every().saturday.at(t).do(ring_bell)
        elif day == "sunday":
            schedule.every().sunday.at(t).do(ring_bell)

print("📅 Scheduler started...\n")

# Keep running and checking
while True:
    schedule.run_pending()
    time.sleep(1)
