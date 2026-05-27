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

echo "# Auto-generated tracker rc - $(date)" > "$RC_FILE"
# 先清除旧的 tracker 方法，再重建，避免重复累积
echo "method.erase = tracker_insert" >> "$RC_FILE"
echo "method.insert = tracker_insert, multi|private" >> "$RC_FILE"
i=0
while IFS= read -r url; do
    [ -z "$url" ] && continue
    case "$url" in \#*) continue ;; esac
    printf 'method.set_key = tracker_insert, t%03d, "d.tracker.insert=\\"%s\\",\\"%s\\""\n' "$i" "$GROUP" "$url" >> "$RC_FILE"
    i=$((i+1))
done < "$TRACKER_FILE"

if [ "$TRACKER_AUTO_UPDATE" ]; then
	echo "enable auto update tracker, tracker file updated (rtorrent will reload via schedule2)"
fi
