#!/usr/bin/env bash
set -euo pipefail

# ===== Настройки (можно подправить) =====
MIN_MINUTES=18          # минимум интервала
MAX_MINUTES=19          # максимум интервала
TONE_HZ=45              # низкий тон, едва заметный
TONE_DURATION=0.12      # длительность сигнала в секундах
TONE_VOLUME=0.015       # амплитуда WAV (очень тихо)
AFPLAY_VOLUME=0.03      # дополнительное снижение громкости afplay (0.0..1.0)

# ===== Временный WAV =====
WAV_FILE="$(mktemp /tmp/speaker-keepalive.XXXXXX.wav)"

cleanup() {
  rm -f "$WAV_FILE"
}
trap cleanup EXIT INT TERM

# Генерация короткого тихого тона через Python (есть в macOS)
python3 - "$WAV_FILE" "$TONE_HZ" "$TONE_DURATION" "$TONE_VOLUME" <<'PY'
import math, struct, wave, sys
path, hz, dur, vol = sys.argv[1], float(sys.argv[2]), float(sys.argv[3]), float(sys.argv[4])

sr = 44100
n = int(sr * dur)

with wave.open(path, "wb") as w:
    w.setnchannels(1)
    w.setsampwidth(2)   # 16-bit
    w.setframerate(sr)
    for i in range(n):
        # плавный fade-in/out чтобы не было щелчка
        t = i / sr
        env = min(1.0, i / (0.01 * sr), (n - i) / (0.01 * sr))
        sample = int(32767 * vol * env * math.sin(2 * math.pi * hz * t))
        w.writeframesraw(struct.pack("<h", sample))
PY

echo "Keep-alive запущен. Тихий сигнал каждые ${MIN_MINUTES}-${MAX_MINUTES} минут."
echo "Остановить: Ctrl+C"

while true; do
  afplay -v "$AFPLAY_VOLUME" "$WAV_FILE" >/dev/null 2>&1 || true
  sleep_seconds=$(( MIN_MINUTES*60 + RANDOM % ((MAX_MINUTES - MIN_MINUTES)*60 + 1) ))
  sleep "$sleep_seconds"
done
