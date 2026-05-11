#!/bin/bash
set -e

# ── Infisical vault secret pull (runs before anything else) ──
if [ -n "$INFISICAL_BOOT_B64" ]; then
    echo "[start.sh] Decoding Infisical boot script..."
    printf "%s" "$INFISICAL_BOOT_B64" | base64 -d > /tmp/infisical-boot.sh || true
    chmod +x /tmp/infisical-boot.sh || true
    echo "[start.sh] Running Infisical boot..."
    bash /tmp/infisical-boot.sh || echo "[start.sh] Infisical boot failed (non-fatal)"
    # Source the env file so secrets are available to the server
    _inf_env="${INFISICAL_ENV_FILE:-/data/.infisical.env}"
    if [ -f "$_inf_env" ]; then
        set -a
        . "$_inf_env"
        set +a
        echo "[start.sh] Infisical secrets loaded from $_inf_env"
    fi
    echo "[start.sh] Infisical boot complete"
fi

# Mirror dashboard-ref-only's startup: create every directory hermes expects
# and seed a default config.yaml if the volume is empty. Without these,
# `hermes dashboard` endpoints that hit logs/, sessions/, cron/, etc. can fail
# with opaque errors even though no auth is actually involved.
mkdir -p /data/.hermes/cron /data/.hermes/sessions /data/.hermes/logs \
         /data/.hermes/memories /data/.hermes/skills /data/.hermes/pairing \
         /data/.hermes/hooks /data/.hermes/image_cache /data/.hermes/audio_cache \
         /data/.hermes/workspace

if [ ! -f /data/.hermes/config.yaml ] && [ -f /opt/hermes-agent/cli-config.yaml.example ]; then
  cp /opt/hermes-agent/cli-config.yaml.example /data/.hermes/config.yaml
fi

[ ! -f /data/.hermes/.env ] && touch /data/.hermes/.env

# Clear any stale gateway PID file left over from the previous container.
# `hermes gateway` writes /data/.hermes/gateway.pid on start but does not
# remove it on SIGTERM. Since /data is a persistent volume, the file
# survives container restarts and causes every subsequent boot to exit with
# "ERROR gateway.run: PID file race lost to another gateway instance".
# No hermes process can be running at this point (we're pre-exec in a fresh
# container), so removing the file unconditionally is safe.
rm -f /data/.hermes/gateway.pid

# === Composio integration (from hermes-composio addon) ================
# Mirrors the composio-cli skill bundle into /data/.hermes/skills and
# logs Composio in non-interactively if COMPOSIO_USER_API_KEY is set.
# Safe to run on every boot - idempotent.
# ====================================================================
if [ -x /usr/local/bin/boot-composio.sh ]; then
  /usr/local/bin/boot-composio.sh || echo "[start.sh] boot-composio failed (non-fatal)"
fi

exec python /app/server.py
