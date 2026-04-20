# keep_speakers_awake.sh
This macOS Bash script prevents your speakers from entering standby mode by playing a very short, barely audible low-volume tone at random intervals between 18 and 19 minutes. It generates a temporary WAV tone file once, reuses it in a loop via afplay, and cleans up the file automatically when the script stops.
