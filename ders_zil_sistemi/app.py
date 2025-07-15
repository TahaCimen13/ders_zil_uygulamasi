from flask import Flask, request, jsonify
import os
import json
from werkzeug.utils import secure_filename
import threading
import time
from datetime import datetime
import platform
import subprocess

CURRENT_PROCESS = None

def play_sound(path):
    global CURRENT_PROCESS
    try:
        if platform.system() == "Darwin":
            # macOS için 30 saniye oynat
            CURRENT_PROCESS = subprocess.Popen(["afplay", path])
        else:
            # Linux için
            CURRENT_PROCESS = subprocess.Popen(["aplay", path])
        
        CURRENT_PROCESS.wait(timeout=30)
    except subprocess.TimeoutExpired:
        if CURRENT_PROCESS:
            CURRENT_PROCESS.terminate()
    finally:
        CURRENT_PROCESS = None


app = Flask(__name__)

SCHEDULE_FILE = "time.json"
SOUND_FOLDER = "assets/sounds"
DEFAULT_SOUND = "bell.mp3"

ACTIVE_ALARM = None  # Şu anda çalan alarm bilgisi

@app.route("/")
def home():
    return "✅ Flask API çalışıyor!"

@app.route("/api/times", methods=["GET"])
def get_times():
    try:
        if not os.path.exists(SCHEDULE_FILE):
            return jsonify({})
        with open(SCHEDULE_FILE, "r") as f:
            return f.read(), 200, {"Content-Type": "application/json"}
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/times", methods=["POST"])
def add_time():
    try:
        data = request.get_json()
        day = data.get("day")
        time_val = data.get("time")
        sound = data.get("sound", DEFAULT_SOUND)
        name = data.get("name", "Zil")

        if not day or not time_val:
            return jsonify({"error": "Eksik veri"}), 400

        schedule = {}
        if os.path.exists(SCHEDULE_FILE):
            with open(SCHEDULE_FILE, "r") as f:
                schedule = json.load(f)

        if day not in schedule:
            schedule[day] = []

        if any(entry["time"] == time_val for entry in schedule[day]):
            return jsonify({"message": "Zaten var"}), 200

        schedule[day].append({"time": time_val, "sound": sound, "name": name})

        with open(SCHEDULE_FILE, "w") as f:
            json.dump(schedule, f, indent=2)

        return jsonify({"message": "Saat eklendi"}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/times", methods=["DELETE"])
def delete_time():
    try:
        data = request.get_json()
        day = data.get("day")
        time_val = data.get("time")

        if not os.path.exists(SCHEDULE_FILE):
            return jsonify({"error": "Zaman dosyası bulunamadı"}), 404

        with open(SCHEDULE_FILE, "r") as f:
            schedule = json.load(f)

        if day not in schedule:
            return jsonify({"error": "Gün bulunamadı"}), 404

        schedule[day] = [entry for entry in schedule.get(day, []) if entry["time"] != time_val]

        with open(SCHEDULE_FILE, "w") as f:
            json.dump(schedule, f, indent=2)

        return jsonify({"message": "Silindi"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/update-time", methods=["POST"])
def edit_time():
    try:
        data = request.get_json()
        old_day = data["old_day"]
        old_time = data["old_time"]
        new_day = data["new_day"]
        new_time = data["new_time"]
        new_sound = data["new_sound"]
        new_name = data.get("new_name", "Zil")

        if not os.path.exists(SCHEDULE_FILE):
            return jsonify({"error": "Zaman dosyası bulunamadı"}), 404

        with open(SCHEDULE_FILE, "r") as f:
            schedule = json.load(f)

        if old_day not in schedule:
            return jsonify({"error": "Gün bulunamadı"}), 404

        schedule[old_day] = [e for e in schedule[old_day] if e["time"] != old_time]

        if new_day not in schedule:
            schedule[new_day] = []

        schedule[new_day].append({"time": new_time, "sound": new_sound, "name": new_name})

        with open(SCHEDULE_FILE, "w") as f:
            json.dump(schedule, f, indent=2)

        return jsonify({"message": "Zaman güncellendi"}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/upload", methods=["POST"])
def upload():
    try:
        if "file" not in request.files:
            return jsonify({"error": "Dosya bulunamadı"}), 400

        file = request.files["file"]
        if file.filename == "":
            return jsonify({"error": "Geçersiz dosya adı"}), 400

        filename = secure_filename(file.filename)
        os.makedirs(SOUND_FOLDER, exist_ok=True)
        save_path = os.path.join(SOUND_FOLDER, filename)
        file.save(save_path)

        return jsonify({"message": "Ses dosyası yüklendi", "filename": filename}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/sounds", methods=["GET"])
def get_sounds():
    try:
        if not os.path.exists(SOUND_FOLDER):
            return jsonify([])
        files = [f for f in os.listdir(SOUND_FOLDER) if f.endswith((".mp3", ".wav"))]

        return jsonify(files), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/test-bell", methods=["GET"])
def test_bell():
    try:
        bell_path = os.path.join(SOUND_FOLDER, DEFAULT_SOUND)
        if not os.path.exists(bell_path):
            return jsonify({"error": "Ses dosyası bulunamadı"}), 404

        threading.Thread(target=play_sound, args=(bell_path,), daemon=True).start()
        return jsonify({"message": "Zil çalınıyor"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@app.route("/api/bluetooth-connect", methods=["POST"])
def bluetooth_connect():
    try:
        data = request.get_json()
        mac = data.get("mac")
        if not mac:
            return jsonify({"error": "MAC adresi gerekli"}), 400

        cmd = f"echo -e 'power on\nagent on\ndefault-agent\npair {mac}\ntrust {mac}\nconnect {mac}\n' | bluetoothctl"
        os.system(cmd)

        return jsonify({"message": f"{mac} bağlanıldı"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    
@app.route("/api/active-alarm", methods=["GET"])
def active_alarm():
    global ACTIVE_ALARM
    if ACTIVE_ALARM:
        return jsonify({"active": True, "alarm": ACTIVE_ALARM}), 200
    else:
        return jsonify({"active": False}), 200

@app.route("/api/dismiss-alarm", methods=["POST"])
def dismiss_alarm():
    global ACTIVE_ALARM, CURRENT_PROCESS
    try:
        if CURRENT_PROCESS:
            CURRENT_PROCESS.terminate()
            CURRENT_PROCESS = None
        ACTIVE_ALARM = None
        return jsonify({"message": "Alarm durduruldu"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

def check_and_ring():
    global ACTIVE_ALARM
    while True:
        now = datetime.now()
        current_day = now.strftime("%A").lower()
        current_time = now.strftime("%H:%M")

        try:
            if not os.path.exists(SCHEDULE_FILE):
                time.sleep(5)
                continue

            with open(SCHEDULE_FILE, "r") as f:
                schedule = json.load(f)

            alarm_triggered = False

            for entry in schedule.get(current_day, []):
                scheduled_time = entry.get("time")
                sound_file = entry.get("sound", DEFAULT_SOUND)
                name = entry.get("name", "Zil")

                now_time = datetime.strptime(now.strftime("%H:%M"), "%H:%M")
                scheduled_dt = datetime.strptime(scheduled_time, "%H:%M")
                diff = abs((now_time - scheduled_dt).total_seconds())

                if diff < 60:
                    sound_path = os.path.join(SOUND_FOLDER, sound_file)
                    if os.path.exists(sound_path):
                        # Alarmı önceden işaretle
                        ACTIVE_ALARM = {
                            "name": name,
                            "time": scheduled_time,
                            "sound": sound_file
                        }

                        # Sesi çalmayı başlat
                        threading.Thread(target=play_sound, args=(sound_path,), daemon=True).start()
                        print(f"🔔 Çalındı: {scheduled_time} - {name} - {sound_file}")
                        alarm_triggered = True
                        time.sleep(60)
                        break

            if not alarm_triggered:
                ACTIVE_ALARM = None

        except Exception as e:
            print(f"❌ Zil kontrol hatası: {e}")

        time.sleep(5)

if __name__ == "__main__":
    threading.Thread(target=check_and_ring, daemon=True).start()
    app.run(host="0.0.0.0", port=5001)
