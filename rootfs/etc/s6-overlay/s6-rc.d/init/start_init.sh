#!/command/with-contenv sh

PUID=${PUID:-1000}
PGID=${PGID:-1000}

echo "Checking permissions (Target UID: $PUID, GID: $PGID)..."

if [ "$PUID" -eq 0 ] || [ "$PGID" -eq 0 ]; then
    echo "PUID/PGID set to 0. Running as root."
    mkdir -p "$CONFIG_DIR" "$DOWNLOAD_DIR" "${CONFIG_DIR}/.rotrrent/session" "$WATCH_DIR"
	if [ ! -f "$CONFIG_DIR/rtorrent.rc" ]; then
		echo "Config file not found, copying default rtorrent.rc to $CONFIG_DIR"
		cp -a /rtorrent.rc "$CONFIG_DIR/rtorrent.rc"
	fi
    exit 0
fi

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

echo "Applying file permissions..."
mkdir -p "$CONFIG_DIR" "$DOWNLOAD_DIR" "$CONFIG_DIR/.rotrrent/session" "$WATCH_DIR"

if [ ! -f "$CONFIG_DIR/rtorrent.rc" ]; then
    echo "Config file not found, copying default rtorrent.rc to $CONFIG_DIR"
    cp -a /rtorrent.rc "$CONFIG_DIR/rtorrent.rc"
fi

chown -R rtorrent:rtorrent "$CONFIG_DIR" "$DOWNLOAD_DIR"

echo "Permission configuration complete."
