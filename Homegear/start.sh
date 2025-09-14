#!/usr/bin/env bash
esac
else
# Fallback: if default /etc/homegear exists in the image, copy from there
if [ -d /etc/homegear ]; then
log "No /etc/homegear.config found — copying /etc/homegear to $HOST_CONFIG_DIR"
cp -a /etc/homegear/. "$HOST_CONFIG_DIR/"
else
log "No initial config found in container; $HOST_CONFIG_DIR will remain empty"
fi
fi
else
log "$HOST_CONFIG_DIR is not empty — skipping initial config population"
fi


# Populate host lib from container if empty
if [ -z "$(ls -A "$HOST_LIB_DIR")" ]; then
if [ -d "$CONTAINER_LIB_SOURCE" ]; then
log "Copying initial lib directory from $CONTAINER_LIB_SOURCE to $HOST_LIB_DIR"
cp -a "$CONTAINER_LIB_SOURCE"/. "$HOST_LIB_DIR/"
elif [ -f "$CONTAINER_LIB_SOURCE" ]; then
case "$CONTAINER_LIB_SOURCE" in
*.tar|*.tar.gz|*.tgz)
log "Extracting tarball $CONTAINER_LIB_SOURCE to $HOST_LIB_DIR"
mkdir -p "$HOST_LIB_DIR"
tar -xzf "$CONTAINER_LIB_SOURCE" -C "$HOST_LIB_DIR"
;;
*)
log "Copying file $CONTAINER_LIB_SOURCE to $HOST_LIB_DIR"
cp -a "$CONTAINER_LIB_SOURCE" "$HOST_LIB_DIR/"
;;
esac
else
# Fallback: if default /var/lib/homegear exists in image, copy from there
if [ -d /var/lib/homegear ]; then
log "No /var/lib/homegear.data found — copying /var/lib/homegear to $HOST_LIB_DIR"
cp -a /var/lib/homegear/. "$HOST_LIB_DIR/"
else
log "No initial lib data found in container; $HOST_LIB_DIR will remain empty"
fi
fi
else
log "$HOST_LIB_DIR is not empty — skipping initial lib population"
fi


# Ensure proper ownership and permissions so non-root user can access
log "Setting ownership on host-mounted folders to homegear:homegear"
chown -R 1000:1000 "$HOST_CONFIG_DIR" "$HOST_LIB_DIR" "$HOST_LOG_DIR" || true


# Replace original container directories with symlinks to host-mounted paths
# (remove only if they are not already symlinks)
if [ ! -L /etc/homegear ]; then
rm -rf /etc/homegear || true
ln -s "$HOST_CONFIG_DIR" /etc/homegear
fi


if [ ! -L /var/lib/homegear ]; then
rm -rf /var/lib/homegear || true
ln -s "$HOST_LIB_DIR" /var/lib/homegear
fi


if [ ! -L /var/log/homegear ]; then
rm -rf /var/log/homegear || true
ln -s "$HOST_LOG_DIR" /var/log/homegear
fi


# Ensure the homegear user exists (should already be created in Dockerfile)
if id -u homegear >/dev/null 2>&1; then
log "homegear user exists"
else
log "homegear user missing — creating"
groupadd -g 1000 homegear || true
useradd -u 1000 -g 1000 -m -s /bin/bash homegear || true
fi


# Make sure log directory is writable
mkdir -p /var/log/homegear
chown -R homegear:homegear /var/log/homegear || true


# Switch to the homegear user and exec Homegear as PID 1
log "Starting Homegear as user 'homegear'"
exec su -s /bin/bash homegear -c "homegear -f"
