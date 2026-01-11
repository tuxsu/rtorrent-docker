#!/command/with-contenv sh

PUID=${PUID:-1000}
PGID=${PGID:-1000}

echo "Checking permissions (Target UID: $PUID, GID: $PGID)..."

if [ "$PUID" -ne 0 ] && [ "$PGID" -ne 0 ]; then
	if ! getent group rtorrent > /dev/null; then
		EXISTING_GROUP=$(getent group "$PGID" | cut -d: -f1)
		if [ -n "$EXISTING_GROUP" ]; then
			echo "Warning: GID $PGID is used by '$EXISTING_GROUP'. Renaming..."
			groupmod -n rtorrent "$EXISTING_GROUP"
		else
			echo "Creating group 'rtorrent' with GID $PGID..."
			addgroup -g "$PGID" -S rtorrent
		fi
	else
		groupmod -g "$PGID" rtorrent
	fi

	if ! getent passwd rtorrent > /dev/null; then
		EXISTING_USER=$(getent passwd "$PUID" | cut -d: -f1)
		if [ -n "$EXISTING_USER" ]; then
			echo "Warning: UID $PUID is used by '$EXISTING_USER'. Renaming..."
			usermod -l rtorrent -g "$PGID" "$EXISTING_USER"
		else
			echo "Creating user 'rtorrent' with UID $PUID..."
			adduser -u "$PUID" -G rtorrent -S -D -H rtorrent
		fi
	else
		usermod -u "$PUID" -g "$PGID" rtorrent
	fi
else
	echo "PUID/PGID set to 0. Running as root. Skipping user/group creation."
fi

echo "Applying file permissions..."
mkdir -p "$CONFIG_DIR" "$DOWNLOAD_DIR" "$CONFIG_DIR/.rtorrent/session" "$WATCH_DIR"

if [ ! -f "$CONFIG_DIR/.rtorrent.rc" ]; then
    echo "Config file not found, copying default rtorrent.rc to $CONFIG_DIR"
    cp -a /rtorrent.rc "$CONFIG_DIR/.rtorrent.rc"
fi

chown -R "$PUID":"$PGID" "$CONFIG_DIR" "$DOWNLOAD_DIR"

echo "Permission configuration complete."

CRON_SCHEDULE=${TRACKER_CRON:-}
TRACKER_URL=${TRACKER_LIST_URL:-}

if [ -n "$CRON_SCHEDULE" ] && [ -n "$TRACKER_URL" ] && [ "$TRACKER_AUTO_UPDATE" ]; then
	echo "${CRON_SCHEDULE} /etc/s6-overlay/s6-rc.d/tracker/update_tracker.sh > /dev/stdout 2>&1" > /var/spool/cron/crontabs/root
	echo "Tracker Update Cron configured with schedule $CRON_SCHEDULE"
	exec /etc/s6-overlay/s6-rc.d/tracker/update_tracker.sh
else
	echo "Tracker URL/Tracker Cron is empty or not enable cron.Skipping set cron update tracker. tracker_url: $TRACKER_URL, cron: $CRON_SCHEDULE, tracker_auto_update: $TRACKER_AUTO_UPDATE"
fi
