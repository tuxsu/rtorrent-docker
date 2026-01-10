#!/command/with-contenv sh
set -e

TRACKER_FILE=/data/trackers/trackers.txt
TRACKER_URL=${TRACKER_LIST_URL}

if [ ! -d "/data/trackers" ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Directory /data/trackers does not exist. Creating..."
    mkdir -p /data/trackers
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Directory /data/trackers already exists."
fi

echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Starting download of tracker list: $TRACKER_URL"

if curl -fsSL "$TRACKER_URL" -o "$TRACKER_FILE"; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] Tracker list downloaded successfully and saved to $TRACKER_FILE"
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN] Failed to download tracker list, keeping existing file"
fi
