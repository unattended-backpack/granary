#!/bin/sh
set -e

echo "[entrypoint] Starting bootstrap as petros user ..."
su petros -c '/bootstrap.sh'
echo "[entrypoint] Bootstrap complete, copying tokens as root ..."

# Now we're back to running as root, copy tokens with correct ownership
if [ -d /home/petros/secrets ]; then
  mkdir -p /out
  cp /home/petros/secrets/* /out/
  chown -R ${HOST_UID:-1000}:${HOST_GID:-1000} /out
  chmod 600 /out/*
else
  echo "[entrypoint] ERROR: No tokens found in /home/petros/secrets!"
  exit 1
fi

echo "[entrypoint] All done!"
