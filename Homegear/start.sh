#!/usr/bin/env bash
set -euo pipefail

# Helper for logging
log() { echo "[start.sh] $*"; }

# Directories on the host (mounted via add-on 'map')
HOST_CONFIG_DIR=/config/homegear
HOST_LIB_DIR=/share/homegear/lib
HOST_LOG_DIR=/share/homegear/log

# Default container-source locations (per your request)
CONTAINER_CONFIG_SOURCE=/etc/homegear.config
CONTAINER_LIB_SOURCE=/var/lib/homegear.data

# Ensure host mount directories exist
mkdir -p "$HOST_CONFIG_DIR"
mkdir -p "$HOST_LIB_DIR"
mkdir -p "$HOST_LOG_DIR"

# Populate host config from container if empty
if [ -z "$(ls -A "$HOST_CONFIG_DIR")" ]; then
    if [ -d "$CONTAINER_CONFIG_SOURCE" ]; then
        log "Copying initial config directory from $CONTAINER_CONFIG_SOURCE to $HOST_CONFIG_DIR"
        cp -a "$CONTAINER_CONFIG_SOURCE"/. "$HOST_CONFIG_DIR/"
    elif [ -f "$CONTAINER_CONFIG_SOURCE" ]; then
        # If the source is a tarball, attempt to extract; otherwise copy file
        case "$CONTAINER_CONFIG_SOURCE" in
        *.tar | *.tar.gz | *.tgz)
            log "Extracting tarball $CONTAINER_CONFIG_SOURCE to $HOST_CONFIG_DIR"
            mkdir -p "$HOST_CONFIG_DIR"
            tar -xzf "$CONTAINER_CONFIG_SOURCE" -C "$HOST_CONFIG_DIR"
            ;;
        *)
            log "Copying file $CONTAINER_CONFIG_SOURCE to $HOST_CONFIG_DIR"
            cp -a "$CONTAINER_CONFIG_SOURCE" "$HOST_CONFIG_DIR/"
            ;;
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
        *.tar | *.tar.gz | *.tgz)
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


# Switch to the homegear user and exec Homegear as PID 1
log "Starting Homegear as user 'homegear'"
exec su -s /bin/bash homegear -c "homegear -c $HOST_CONFIG_DIR"
