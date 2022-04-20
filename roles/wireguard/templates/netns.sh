#!/usr/bin/env sh
set -e

NETNS='{{ netns_name }}'

cat <<EOF | xargs -0 sudo -E nsenter "--net=/var/run/netns/$NETNS" unshare --mount sh -c
mount --bind /etc/netns/${NETNS}/resolv.conf /etc/resolv.conf &&
sudo -E -u \#${SUDO_UID:-$(id -u)} -g \#${SUDO_GID:-$(id -g)} -- $@
EOF
