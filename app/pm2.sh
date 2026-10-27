#!/usr/bin/env bash
set -euo pipefail

APP_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$APP_DIR/.." && pwd)"
NVM_DIR="${NVM_DIR:-$HOME/.nvm}"

source "$NVM_DIR/nvm.sh"
NODE_VERSION="$(< "$PROJECT_DIR/.nvmrc")"
nvm use --silent "$NODE_VERSION" >/dev/null 2>&1
NODE_BIN="$(nvm which "$NODE_VERSION")"
PM2_BIN="${NODE_BIN%/node}/pm2"

if [[ ! -x "$PM2_BIN" ]]; then
  echo "PM2 is not installed for Node $NODE_VERSION: $PM2_BIN" >&2
  exit 1
fi

echo "#---------------------Copkey Start at $(date '+%Y%m%d %H:%M:%S') with Node $("$NODE_BIN" --version)"
export NODE_ENV="production"
export PORT=3000

cd "$APP_DIR"
exec "$PM2_BIN" start ./src/index.js --name copkey -i 2 --interpreter "$NODE_BIN"

