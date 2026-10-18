#!/bin/sh
set -e

export HOST="${HOST:-0.0.0.0}"
export PORT="${PORT:-8191}"
export LOG_LEVEL="${LOG_LEVEL:-info}"
export DISABLE_MEDIA="${DISABLE_MEDIA:-true}"
export MAX_TIMEOUT_MS="${MAX_TIMEOUT_MS:-25000}"
export TZ="${TZ:-UTC}"

exec /usr/bin/dumb-init -- /usr/local/bin/python -u /app/flaresolverr.py "$@"
