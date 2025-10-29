#!/bin/sh
set -e

CACHE="${CACHE_NAME}"
ATTIC_SERVER="http://granary:8080"

# First, create an admin token so we can create the cache.
echo "[bootstrap] Creating admin token for $CACHE ..."
ADMIN_TOKEN="$(atticadm make-token \
  --sub 'bootstrap' \
  --validity '180d' \
  --pull "$CACHE" --push "$CACHE" \
  --create-cache "$CACHE" --configure-cache "$CACHE" \
  --configure-cache-retention "$CACHE" \
  --delete "$CACHE" --destroy-cache "$CACHE" \
  -f /granary/server.toml)"

# The admin token is suitable for privileged operations such as preparing
# initial builds to seed the attic cache. Care must be taken to avoid leaking
# this token.
mkdir -p ~/secrets
printf '%s' "$ADMIN_TOKEN" > ~/secrets/admin_token
echo "[bootstrap] Admin token saved to ~/secrets/admin_token ..."

# Wait for the server to be ready.
echo "[bootstrap] Waiting for attic server to be ready ..."
for i in $(seq 1 30); do
  if curl -f -s "$ATTIC_SERVER/" > /dev/null 2>&1; then
    echo "[bootstrap] Server is ready!"
    break
  fi
  echo "[bootstrap] Waiting for server... (attempt $i/30)."
  sleep 2
done

# Now log in to the server
echo "[bootstrap] Logging in to attic server ..."
attic login local "$ATTIC_SERVER" "$ADMIN_TOKEN"

# Create the cache if it doesn't exist.
echo "[bootstrap] Checking if cache $CACHE exists ..."
if attic cache info "$CACHE"; then
  echo "[bootstrap] Cache $CACHE already exists."
else
  echo "[bootstrap] Creating cache $CACHE ..."
  attic cache create --priority 0 --upstream-cache-key-name "" "$CACHE"
  attic cache configure "$CACHE" --private
  echo "[bootstrap] Cache $CACHE created successfully!"
fi

# The read-only token is suitable for distributing to others who might want to
# pull Nix binaries from the cache.
echo "[bootstrap] Creating read-only token for $CACHE ..."
READ_TOKEN="$(atticadm make-token \
  --sub 'bootstrap' \
  --validity '180d' \
  --pull "$CACHE" \
  -f /granary/server.toml)"

# Ensure correct permissions on the token directory.
printf '%s' "$READ_TOKEN" > ~/secrets/read_token
echo "[bootstrap] Read token saved to ~/secrets/read_token ..."
echo "[bootstrap] Bootstrap complete."
