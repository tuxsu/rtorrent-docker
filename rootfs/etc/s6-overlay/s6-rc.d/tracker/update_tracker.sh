#!/command/with-contenv sh
set -e

TRACKER_DIR=/data/trackers
TRACKER_FILE=$TRACKER_DIR/trackers.txt
TRACKER_URL=${TRACKER_LIST_URL}
RC_FILE=$TRACKER_DIR/trackers-auto.rc
GROUP=0

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

echo "# Auto-generated tracker rc for new torrents - $(date)" > "$RC_FILE"
i=0
while IFS= read -r url; do
    [ -z "$url" ] && continue
    case "$url" in \#*) continue ;; esac
    printf 'method.set_key = event.download.inserted_new,add_all_trackers_%03d,"d.tracker.insert=\\"%s\\",\\"%s\\""\n' "$i" "$GROUP" "$url" >> "$RC_FILE"
    i=$((i+1))
done < "$TRACKER_FILE"

if [ "$TRACKER_AUTO_UPDATE" ]; then
	echo "enable auto update tracker, restart rtorrent"
	exec s6-svc -r /run/service/rtorrent
fi
