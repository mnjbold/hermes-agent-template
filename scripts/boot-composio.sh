#!/usr/bin/env bash
# =============================================================================
# Boot hook for Hermes Agent — mirror the composio-cli skill bundle into
# the persistent /data volume, then non-interactively log Composio in if a
# COMPOSIO_USER_API_KEY is present in env.
#
# Call this from your container ENTRYPOINT or start.sh BEFORE Hermes spawns
# the gateway, so Hermes' LLM can read the skill from a stable path.
#
# Safe to run on every boot — it's idempotent.
# =============================================================================
set -euo pipefail

SKILL_SRC="/opt/hermes-skills/composio-cli"
SKILL_DST="/data/.hermes/skills/composio-cli"

# 1. Mirror the bundled skill into /data on every boot.
#
# `cp -an` (archive + no-clobber) means: preserve a user's manual edits to
# the skill on disk; only fill in files that don't exist yet. If the user
# wants to pick up a newer version from the image, they can rm the dir.
if [ -d "$SKILL_SRC" ]; then
  mkdir -p "$(dirname "$SKILL_DST")"
  cp -an "$SKILL_SRC" "$(dirname "$SKILL_DST")/" || true
  echo "[boot-composio] Skill bundle staged at $SKILL_DST"
else
  echo "[boot-composio] WARN: $SKILL_SRC missing — was the image built with the addon Dockerfile snippet?" >&2
fi

# 2. Non-interactive login if a user API key was provided via env.
#    Skip if already logged in to avoid bumping a still-valid session.
if [ -n "${COMPOSIO_USER_API_KEY:-}" ]; then
  if ! composio whoami >/dev/null 2>&1; then
    composio login \
      --user-api-key "$COMPOSIO_USER_API_KEY" \
      ${COMPOSIO_ORG:+--org "$COMPOSIO_ORG"} \
      --no-skill-install \
      --no-browser \
      -y >/dev/null 2>&1 \
      && echo "[boot-composio] Logged in as Composio user (org=${COMPOSIO_ORG:-default})" \
      || echo "[boot-composio] WARN: composio login failed — check COMPOSIO_USER_API_KEY" >&2
  else
    echo "[boot-composio] Already logged in: $(composio whoami 2>/dev/null | head -1)"
  fi
else
  echo "[boot-composio] COMPOSIO_USER_API_KEY not set — skill is loadable but tools won't execute"
fi

exit 0
