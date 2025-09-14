# Use the official Homegear image as base
FROM homegear/homegear:stable


# Create a non-root user 'homegear' with UID/GID 1000 (common Home Assistant UID)
# This user will run the Homegear process; startup script will perform setup
RUN set -eux \
&& groupadd -g 1000 homegear || true \
&& useradd -u 1000 -g 1000 -m -s /bin/bash homegear || true


# Copy start script
COPY start.sh /start.sh
RUN chmod +x /start.sh


# The container will use the start script as entrypoint
ENTRYPOINT ["/start.sh"]
CMD ["/sbin/tini", "--"]
